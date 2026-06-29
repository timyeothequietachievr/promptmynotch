import Foundation
import Network

enum OAuthLoopbackError: LocalizedError {
    case cancelled
    case invalidPort
    case listenerFailed(String)
    case noCode

    var errorDescription: String? {
        switch self {
        case .cancelled: return "Google sign-in was cancelled."
        case .invalidPort: return "Invalid OAuth port configuration."
        case .listenerFailed(let detail): return detail
        case .noCode: return "Google did not return an authorization code."
        }
    }
}

final class OAuthLoopbackServer {
    static let port: UInt16 = 38475
    /// Google Desktop OAuth allows loopback URIs with no path: http://127.0.0.1:PORT
    static var redirectURI: String { "http://127.0.0.1:\(port)" }

    private var listener: NWListener?
    private var resumed = false
    private let queue = DispatchQueue(label: "com.notchprompter.oauth-loopback")

    func cancel() {
        queue.async {
            self.listener?.cancel()
            self.listener = nil
        }
    }

    func waitForAuthorizationCode() async throws -> String {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                queue.async {
                    do {
                        guard let nwPort = NWEndpoint.Port(rawValue: Self.port) else {
                            continuation.resume(throwing: OAuthLoopbackError.invalidPort)
                            return
                        }

                        let params = NWParameters.tcp
                        params.allowLocalEndpointReuse = true
                        self.listener = try NWListener(using: params, on: nwPort)
                    } catch {
                        continuation.resume(throwing: OAuthLoopbackError.listenerFailed(
                            "Could not listen on port \(Self.port). Another app may be using it."
                        ))
                        return
                    }

                    self.listener?.stateUpdateHandler = { [weak self] state in
                        if case .failed(let error) = state {
                            self?.resumeOnce(continuation, with: .failure(error))
                        }
                    }

                    self.listener?.newConnectionHandler = { [weak self] connection in
                        self?.handle(connection: connection, continuation: continuation)
                    }

                    self.listener?.start(queue: self.queue)
                }
            }
        } onCancel: {
            self.cancel()
        }
    }

    private func handle(connection: NWConnection, continuation: CheckedContinuation<String, Error>) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, _, _ in
            defer { connection.cancel() }

            guard let self else { return }

            if let data, let request = String(data: data, encoding: .utf8) {
                let responseBody = """
                <!DOCTYPE html><html><body style="font-family: -apple-system, sans-serif; text-align: center; padding: 48px;">
                <h1>Signed in</h1><p>Return to NotchPrompter.</p></body></html>
                """
                let response = """
                HTTP/1.1 200 OK\r
                Content-Type: text/html; charset=utf-8\r
                Content-Length: \(responseBody.utf8.count)\r
                Connection: close\r
                \r
                \(responseBody)
                """
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in })

                if let requestLine = request.split(separator: "\r\n").first {
                    let parts = requestLine.split(separator: " ")
                    if parts.count >= 2 {
                        let path = String(parts[1])
                        if let components = URLComponents(string: "http://127.0.0.1\(path)") {
                            if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
                                self.resumeOnce(continuation, with: .failure(GoogleAuthError.tokenExchangeFailed(error)))
                                return
                            }
                            if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                                self.resumeOnce(continuation, with: .success(code))
                                return
                            }
                        }
                    }
                }
            }

            self.resumeOnce(continuation, with: .failure(OAuthLoopbackError.noCode))
        }
    }

    private func resumeOnce(_ continuation: CheckedContinuation<String, Error>, with result: Result<String, Error>) {
        queue.async {
            guard !self.resumed else { return }
            self.resumed = true
            self.listener?.cancel()
            self.listener = nil
            continuation.resume(with: result)
        }
    }
}
