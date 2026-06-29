import Foundation

enum GoogleSlidesURLParser {
    static func presentationID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return presentationID(from: url)
        }

        // Bare ID pasted directly.
        if trimmed.range(of: #"^[a-zA-Z0-9_-]{20,}$"#, options: .regularExpression) != nil {
            return trimmed
        }

        return nil
    }

    static func presentationID(from url: URL) -> String? {
        let path = url.path

        // Standard: /presentation/d/{id}/edit
        if let regex = try? NSRegularExpression(pattern: #"/presentation/d/([a-zA-Z0-9_-]+)"#),
           let match = regex.firstMatch(in: path, range: NSRange(path.startIndex..., in: path)),
           let idRange = Range(match.range(at: 1), in: path) {
            return String(path[idRange])
        }

        // Published embed: /presentation/d/e/{token}/pub
        if path.contains("/presentation/d/e/") {
            let parts = path.split(separator: "/")
            if let index = parts.firstIndex(of: "e"), index + 1 < parts.count {
                return String(parts[index + 1])
            }
        }

        return nil
    }
}
