import Foundation

/// Resolves Google Slides page object IDs to zero-based slide indices using the live API.
@MainActor
enum GoogleSlidesSlideIndexCache {
    private struct Entry {
        let fetchedAt: Date
        let indexByObjectId: [String: Int]
    }

    private static var entries: [String: Entry] = [:]
    private static let ttl: TimeInterval = 120

    static func slideIndex(
        presentationID: String,
        objectId: String,
        accessToken: String?
    ) async -> Int? {
        let normalized = normalize(objectId)
        if let cached = cachedIndex(presentationID: presentationID, objectId: normalized) {
            return cached
        }
        guard let accessToken else { return nil }
        await refresh(presentationID: presentationID, accessToken: accessToken)
        if let index = cachedIndex(presentationID: presentationID, objectId: normalized) {
            return index
        }
        return await fetchPageIndex(presentationID: presentationID, pageObjectId: normalized, accessToken: accessToken)
    }

    static func invalidate(presentationID: String) {
        entries.removeValue(forKey: presentationID)
    }

    private static func cachedIndex(presentationID: String, objectId: String) -> Int? {
        guard let entry = entries[presentationID],
              Date().timeIntervalSince(entry.fetchedAt) < ttl else { return nil }
        return entry.indexByObjectId[objectId]
    }

    private static func refresh(presentationID: String, accessToken: String) async {
        let url = URL(string: "https://slides.googleapis.com/v1/presentations/\(presentationID)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let slides = json["slides"] as? [[String: Any]] else {
            return
        }

        var map: [String: Int] = [:]
        for (index, slide) in slides.enumerated() {
            guard let objectId = slide["objectId"] as? String else { continue }
            map[normalize(objectId)] = index
        }
        entries[presentationID] = Entry(fetchedAt: .now, indexByObjectId: map)
    }

    private static func fetchPageIndex(
        presentationID: String,
        pageObjectId: String,
        accessToken: String
    ) async -> Int? {
        let url = URL(string: "https://slides.googleapis.com/v1/presentations/\(presentationID)/pages/\(pageObjectId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resolvedId = json["objectId"] as? String else {
            return nil
        }

        let normalized = normalize(resolvedId)
        if let index = cachedIndex(presentationID: presentationID, objectId: normalized) {
            return index
        }
        await refresh(presentationID: presentationID, accessToken: accessToken)
        return cachedIndex(presentationID: presentationID, objectId: normalized)
    }

    private static func normalize(_ raw: String) -> String {
        raw.hasPrefix("id.") ? String(raw.dropFirst(3)) : raw
    }
}
