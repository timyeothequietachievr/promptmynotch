import Foundation

enum GoogleSlidesImporterError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case apiError(Int, String)
    case noSlides

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not find a Google Slides presentation ID in that URL."
        case .notAuthenticated:
            return "Sign in with Google to import speaker notes."
        case .apiError(let code, let detail):
            return "Google Slides API error (\(code)): \(detail)"
        case .noSlides:
            return "This presentation has no slides."
        }
    }
}

struct GoogleSlidesImporter {
    func importNotes(
        from urlOrID: String,
        accessToken: String
    ) async throws -> ImportedPresentation {
        guard let presentationID = GoogleSlidesURLParser.presentationID(from: urlOrID) else {
            throw GoogleSlidesImporterError.invalidURL
        }

        let url = URL(string: "https://slides.googleapis.com/v1/presentations/\(presentationID)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GoogleSlidesImporterError.apiError(-1, "No response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let detail = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GoogleSlidesImporterError.apiError(http.statusCode, detail)
        }

        let presentation = try JSONDecoder().decode(GooglePresentation.self, from: data)
        guard let slides = presentation.slides, !slides.isEmpty else {
            throw GoogleSlidesImporterError.noSlides
        }

        var notes: [SlideNote] = []
        for (index, slide) in slides.enumerated() {
            let slideNumber = index + 1
            let text = extractSpeakerNotes(from: slide)
            let speakerNotesObjectId = slide.slideProperties?.notesPage?.notesProperties?.speakerNotesObjectId
            notes.append(SlideNote(
                slideNumber: slideNumber,
                objectId: slide.objectId,
                speakerNotesObjectId: speakerNotesObjectId,
                text: text
            ))
        }

        return ImportedPresentation(
            title: presentation.title ?? "Google Slides",
            source: .googleSlides,
            googlePresentationID: presentationID,
            slides: notes
        )
    }

    private func extractSpeakerNotes(from slide: GoogleSlide) -> String {
        guard
            let notesPage = slide.slideProperties?.notesPage,
            let speakerNotesID = notesPage.notesProperties?.speakerNotesObjectId,
            let shapes = notesPage.pageElements
        else { return "" }

        guard let shape = shapes.first(where: { $0.objectId == speakerNotesID }),
              let textElements = shape.shape?.text?.textElements
        else { return "" }

        return textElements.compactMap { element -> String? in
            element.textRun?.content
        }.joined()
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Google Slides API models

private struct GooglePresentation: Decodable {
    let title: String?
    let slides: [GoogleSlide]?
}

private struct GoogleSlide: Decodable {
    let objectId: String?
    let slideProperties: GoogleSlideProperties?
}

private struct GoogleSlideProperties: Decodable {
    let notesPage: GooglePage?
}

private struct GooglePage: Decodable {
    let notesProperties: GoogleNotesProperties?
    let pageElements: [GooglePageElement]?
}

private struct GoogleNotesProperties: Decodable {
    let speakerNotesObjectId: String?
}

private struct GooglePageElement: Decodable {
    let objectId: String?
    let shape: GoogleShape?
}

private struct GoogleShape: Decodable {
    let text: GoogleText?
}

private struct GoogleText: Decodable {
    let textElements: [GoogleTextElement]?
}

private struct GoogleTextElement: Decodable {
    let textRun: GoogleTextRun?
}

private struct GoogleTextRun: Decodable {
    let content: String?
}
