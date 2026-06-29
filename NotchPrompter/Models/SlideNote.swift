import Foundation

struct SlideNote: Identifiable, Hashable, Codable {
    let slideNumber: Int
    let objectId: String?
    let speakerNotesObjectId: String?
    let text: String

    var id: Int { slideNumber }

    init(slideNumber: Int, objectId: String? = nil, speakerNotesObjectId: String? = nil, text: String) {
        self.slideNumber = slideNumber
        self.objectId = objectId
        self.speakerNotesObjectId = speakerNotesObjectId
        self.text = text
    }

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ImportedPresentation: Identifiable {
    let id = UUID()
    let title: String
    let source: ImportSource
    let googlePresentationID: String?
    let slides: [SlideNote]

    var combinedScript: String {
        slides
            .filter { !$0.isEmpty }
            .map { slide in
                if slides.count > 1 {
                    return "--- Slide \(slide.slideNumber) ---\n\(slide.text)"
                }
                return slide.text
            }
            .joined(separator: "\n\n")
    }
}

enum ImportSource: String, Codable {
    case googleSlides = "Google Slides"
    case keynote = "Keynote"
    case powerPoint = "PowerPoint"
    case richText = "Rich Text"
    case manual = "Manual"
}
