import Foundation

struct Script: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var content: String
    var richContentRTF: Data?
    var source: ImportSource
    var sourceReference: String?
    var slides: [SlideNote]?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        richContentRTF: Data? = nil,
        source: ImportSource = .manual,
        sourceReference: String? = nil,
        slides: [SlideNote]? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.richContentRTF = richContentRTF
        self.source = source
        self.sourceReference = sourceReference
        self.slides = slides
        self.updatedAt = updatedAt
    }

    var googlePresentationID: String? {
        guard source == .googleSlides else { return nil }
        return sourceReference
    }

    func slideIndex(forObjectId objectId: String?) -> Int? {
        guard let objectId, let slides, !slides.isEmpty else { return nil }
        let normalized = objectId.hasPrefix("id.") ? String(objectId.dropFirst(3)) : objectId
        return slides.firstIndex { slide in
            guard let stored = slide.objectId else { return false }
            let storedNormalized = stored.hasPrefix("id.") ? String(stored.dropFirst(3)) : stored
            return storedNormalized == normalized
        }
    }

    func slideText(at index: Int) -> String {
        guard let slides, !slides.isEmpty else { return content }
        let clamped = min(max(0, index), slides.count - 1)
        return slides[clamped].text
    }

    /// Text shown in the prompter for a slide — prefers per-slide notes, then script content.
    func presentationText(at slideIndex: Int) -> String {
        guard let slides, !slides.isEmpty else { return content }

        let clamped = min(max(0, slideIndex), slides.count - 1)
        let slideText = slides[clamped].text
        if !slideText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return slideText
        }

        let slideNumber = slides[clamped].slideNumber
        if slides.count > 1,
           let parsed = Self.parseSlideSection(from: content, slideNumber: slideNumber),
           !parsed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return parsed
        }

        if slides.count == 1 {
            return content
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? slideText
            : content
    }

    static func combinedContent(from slides: [SlideNote]) -> String {
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

    static func parseSlideSection(from content: String, slideNumber: Int) -> String? {
        let marker = "--- Slide \(slideNumber) ---"
        guard let markerRange = content.range(of: marker) else { return nil }

        let afterMarker = content[markerRange.upperBound...]
        if let nextMarker = afterMarker.range(of: "\n--- Slide ") {
            return String(afterMarker[..<nextMarker.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(afterMarker).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func withUpdatedSlideText(at slideIndex: Int, text: String) -> Script {
        var updated = self
        updated.updatedAt = .now

        guard var slideList = updated.slides, !slideList.isEmpty, slideIndex < slideList.count else {
            updated.content = text
            return updated
        }

        let slideNumber = slideList[slideIndex].slideNumber
        let existing = slideList[slideIndex]
        slideList[slideIndex] = SlideNote(
            slideNumber: slideNumber,
            objectId: existing.objectId,
            speakerNotesObjectId: existing.speakerNotesObjectId,
            text: text
        )
        updated.slides = slideList
        updated.richContentRTF = nil

        if slideList.count > 1 {
            updated.content = Self.combinedContent(from: slideList)
        } else {
            updated.content = text
        }

        return updated
    }

    static func updatedContent(_ content: String, slideNumber: Int, newText: String) -> String {
        let marker = "--- Slide \(slideNumber) ---"
        guard let markerRange = content.range(of: marker) else { return content }

        let afterMarker = content[markerRange.upperBound...]
        let prefix = String(content[..<markerRange.upperBound])

        if let nextMarker = afterMarker.range(of: "\n--- Slide ") {
            let suffix = String(afterMarker[nextMarker.lowerBound...])
            return prefix + "\n" + newText + "\n" + suffix
        }

        return prefix + "\n" + newText
    }
}
