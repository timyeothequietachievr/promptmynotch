import Foundation

enum GoogleSlidesNotesUpdaterError: LocalizedError {
    case missingPresentationID
    case missingSlideObjectId
    case missingSpeakerNotesObjectId
    case invalidWordRange
    case apiError(Int, String)

    var errorDescription: String? {
        switch self {
        case .missingPresentationID:
            return "This script is not linked to a Google Slides presentation."
        case .missingSlideObjectId:
            return "This slide has no Google Slides object ID."
        case .missingSpeakerNotesObjectId:
            return "Could not find speaker notes for this slide."
        case .invalidWordRange:
            return "Could not locate that word in the speaker notes."
        case .apiError(let code, let detail):
            return "Google Slides API error (\(code)): \(detail)"
        }
    }
}

struct GoogleSlidesNotesUpdater {
    func setSmallCaps(
        presentationID: String,
        slide: SlideNote,
        wordIndex: Int,
        slideText: String,
        enabled: Bool,
        accessToken: String
    ) async throws {
        guard let slideObjectId = slide.objectId else {
            throw GoogleSlidesNotesUpdaterError.missingSlideObjectId
        }

        let speakerNotesObjectId: String
        if let stored = slide.speakerNotesObjectId {
            speakerNotesObjectId = stored
        } else {
            speakerNotesObjectId = try await fetchSpeakerNotesObjectId(
                presentationID: presentationID,
                slideObjectId: slideObjectId,
                accessToken: accessToken
            )
        }

        guard let range = PrompterTextTokenizer.utf16CodeUnitRange(at: wordIndex, in: slideText) else {
            throw GoogleSlidesNotesUpdaterError.invalidWordRange
        }

        let body: [String: Any] = [
            "requests": [
                [
                    "updateTextStyle": [
                        "objectId": speakerNotesObjectId,
                        "textRange": [
                            "type": "FIXED_RANGE",
                            "startIndex": range.start,
                            "endIndex": range.end,
                        ],
                        "style": [
                            "smallCaps": enabled,
                        ],
                        "fields": "smallCaps",
                    ],
                ],
            ],
        ]

        try await postBatchUpdate(presentationID: presentationID, body: body, accessToken: accessToken)
    }

    func replaceSpeakerNotesText(
        presentationID: String,
        slide: SlideNote,
        newText: String,
        accessToken: String
    ) async throws {
        guard let slideObjectId = slide.objectId else {
            throw GoogleSlidesNotesUpdaterError.missingSlideObjectId
        }

        let speakerNotesObjectId: String
        if let stored = slide.speakerNotesObjectId {
            speakerNotesObjectId = stored
        } else {
            speakerNotesObjectId = try await fetchSpeakerNotesObjectId(
                presentationID: presentationID,
                slideObjectId: slideObjectId,
                accessToken: accessToken
            )
        }

        let body: [String: Any] = [
            "requests": [
                [
                    "deleteText": [
                        "objectId": speakerNotesObjectId,
                        "textRange": ["type": "ALL"],
                    ],
                ],
                [
                    "insertText": [
                        "objectId": speakerNotesObjectId,
                        "text": newText,
                        "insertionIndex": 0,
                    ],
                ],
            ],
        ]

        try await postBatchUpdate(presentationID: presentationID, body: body, accessToken: accessToken)
    }

    private func fetchSpeakerNotesObjectId(
        presentationID: String,
        slideObjectId: String,
        accessToken: String
    ) async throws -> String {
        let url = URL(string: "https://slides.googleapis.com/v1/presentations/\(presentationID)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleSlidesNotesUpdaterError.apiError(-1, "No response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleSlidesNotesUpdaterError.apiError(http.statusCode, detail)
        }

        let presentation = try JSONDecoder().decode(GooglePresentationLookup.self, from: data)
        guard let slides = presentation.slides else {
            throw GoogleSlidesNotesUpdaterError.missingSpeakerNotesObjectId
        }

        guard let slide = slides.first(where: { $0.objectId == slideObjectId }),
              let objectId = slide.slideProperties?.notesPage?.notesProperties?.speakerNotesObjectId else {
            throw GoogleSlidesNotesUpdaterError.missingSpeakerNotesObjectId
        }

        return objectId
    }

    private func postBatchUpdate(
        presentationID: String,
        body: [String: Any],
        accessToken: String
    ) async throws {
        let url = URL(string: "https://slides.googleapis.com/v1/presentations/\(presentationID):batchUpdate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleSlidesNotesUpdaterError.apiError(-1, "No response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleSlidesNotesUpdaterError.apiError(http.statusCode, detail)
        }
    }
}

private struct GooglePresentationLookup: Decodable {
    let slides: [GoogleSlideLookup]?
}

private struct GoogleSlideLookup: Decodable {
    let objectId: String?
    let slideProperties: GoogleSlidePropertiesLookup?
}

private struct GoogleSlidePropertiesLookup: Decodable {
    let notesPage: GoogleNotesPageLookup?
}

private struct GoogleNotesPageLookup: Decodable {
    let notesProperties: GoogleNotesPropertiesLookup?
}

private struct GoogleNotesPropertiesLookup: Decodable {
    let speakerNotesObjectId: String?
}
