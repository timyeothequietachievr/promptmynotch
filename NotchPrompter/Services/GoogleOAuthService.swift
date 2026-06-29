import AppKit
import Foundation

enum GoogleAuthError: LocalizedError {
    case missingClientID
    case cancelled
    case noAccessToken
    case tokenExchangeFailed(String)
    case browserOpenFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Google Client ID is not configured. Add it in Settings."
        case .cancelled:
            return "Google sign-in was cancelled."
        case .noAccessToken:
            return "Google did not return an access token."
        case .tokenExchangeFailed(let detail):
            return "Google sign-in failed: \(detail)"
        case .browserOpenFailed(let detail):
            return "Could not open browser: \(detail)"
        }
    }
}

@MainActor
final class GoogleOAuthService {
    static let shared = GoogleOAuthService()

    private let tokenKey = "google_access_token"
    private let expiryKey = "google_token_expiry"

    static var redirectURI: String { OAuthLoopbackServer.redirectURI }

    var clientID: String {
        UserDefaults.standard.string(forKey: "google_client_id")
            ?? Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String
            ?? ""
    }

    var clientSecret: String {
        UserDefaults.standard.string(forKey: "google_client_secret") ?? ""
    }

    var isConfigured: Bool { !clientID.isEmpty }

    var accessToken: String? {
        guard let token = UserDefaults.standard.string(forKey: tokenKey) else { return nil }
        let expiry = UserDefaults.standard.double(forKey: expiryKey)
        if expiry > 0, Date().timeIntervalSince1970 >= expiry - 60 {
            return nil
        }
        return token
    }

    func setCredentials(clientID: String, clientSecret: String) {
        UserDefaults.standard.set(clientID.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "google_client_id")
        UserDefaults.standard.set(clientSecret.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "google_client_secret")
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: expiryKey)
    }

    func authenticate(in browser: InstalledBrowser) async throws -> String {
        if let token = accessToken { return token }

        guard !clientID.isEmpty else { throw GoogleAuthError.missingClientID }

        let redirectURI = Self.redirectURI
        let scope = "https://www.googleapis.com/auth/presentations"
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent"),
        ]

        guard let authURL = components.url else {
            throw GoogleAuthError.tokenExchangeFailed("Invalid auth URL")
        }

        let loopback = OAuthLoopbackServer()
        async let codeTask = loopback.waitForAuthorizationCode()

        do {
            try await BrowserDiscovery.open(authURL, in: browser)
        } catch {
            loopback.cancel()
            throw GoogleAuthError.browserOpenFailed(error.localizedDescription)
        }

        let code: String
        do {
            code = try await codeTask
        } catch {
            if error is OAuthLoopbackError {
                throw GoogleAuthError.cancelled
            }
            throw error
        }

        return try await exchangeCode(code, redirectURI: redirectURI)
    }

    private func exchangeCode(_ code: String, redirectURI: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var params = [
            "code": code,
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code",
        ]
        if !clientSecret.isEmpty {
            params["client_secret"] = clientSecret
        }
        let body = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleAuthError.tokenExchangeFailed(detail)
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let expires_in: Int?
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        UserDefaults.standard.set(decoded.access_token, forKey: tokenKey)
        if let expires = decoded.expires_in {
            UserDefaults.standard.set(Date().timeIntervalSince1970 + Double(expires), forKey: expiryKey)
        }
        return decoded.access_token
    }
}
