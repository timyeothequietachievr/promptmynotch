import Foundation

enum PPTXImporterError: LocalizedError {
    case unreadableArchive
    case noSlides
    case parseFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreadableArchive:
            return "Could not read this PowerPoint file. Export from Google Slides as .pptx and try again."
        case .noSlides:
            return "No speaker notes found in this presentation."
        case .parseFailed(let detail):
            return "Failed to parse PowerPoint file: \(detail)"
        }
    }
}

/// Imports speaker notes from .pptx files (including Google Slides → Download → .pptx exports).
struct PPTXImporter {
    func importNotes(from fileURL: URL, source: ImportSource = .powerPoint) throws -> ImportedPresentation {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("notchprompter-pptx-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        try unzip(fileURL, to: tempDir)

        let slideNotes = try extractNotes(from: tempDir)
        guard !slideNotes.isEmpty else { throw PPTXImporterError.noSlides }

        let title = fileURL.deletingPathExtension().lastPathComponent
        return ImportedPresentation(title: title, source: source, googlePresentationID: nil, slides: slideNotes)
    }

    private func unzip(_ fileURL: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-qq", "-o", fileURL.path, "-d", destination.path]
        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let err = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw PPTXImporterError.parseFailed(err.isEmpty ? "unzip failed" : err)
        }
    }

    private func extractNotes(from root: URL) throws -> [SlideNote] {
        let slidesDir = root.appendingPathComponent("ppt/slides")
        let slidesRelsDir = root.appendingPathComponent("ppt/slides/_rels")
        let notesDir = root.appendingPathComponent("ppt/notesSlides")
        let notesRelsDir = root.appendingPathComponent("ppt/notesSlides/_rels")

        guard FileManager.default.fileExists(atPath: slidesDir.path) else {
            throw PPTXImporterError.unreadableArchive
        }

        let slideFiles = try FileManager.default.contentsOfDirectory(at: slidesDir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "xml" && $0.lastPathComponent.hasPrefix("slide") }
            .sorted { slideNumber(from: $0.lastPathComponent) < slideNumber(from: $1.lastPathComponent) }

        var results: [SlideNote] = []

        for (index, slideFile) in slideFiles.enumerated() {
            let slideNumber = index + 1
            let relFile = slidesRelsDir.appendingPathComponent("\(slideFile.deletingPathExtension().lastPathComponent).xml.rels")
            let notesFile = try notesFileForSlide(relFile: relFile, notesDir: notesDir, notesRelsDir: notesRelsDir, fallbackIndex: slideNumber)
            let text = notesFile.map { extractTextFromOOXML(at: $0) } ?? ""
            results.append(SlideNote(slideNumber: slideNumber, text: text))
        }

        return results
    }

    private func notesFileForSlide(
        relFile: URL,
        notesDir: URL,
        notesRelsDir: URL,
        fallbackIndex: Int
    ) throws -> URL? {
        if FileManager.default.fileExists(atPath: relFile.path),
           let rels = try? String(contentsOf: relFile, encoding: .utf8),
           let target = rels.range(of: #"Target="../notesSlides/([^"]+\.xml)""#, options: .regularExpression) {
            let match = String(rels[target])
            if let fileName = match.components(separatedBy: "/").last?.replacingOccurrences(of: "\"", with: "") {
                let candidate = notesDir.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: candidate.path) {
                    return candidate
                }
            }
        }

        let fallback = notesDir.appendingPathComponent("notesSlide\(fallbackIndex).xml")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }

    private func extractTextFromOOXML(at url: URL) -> String {
        guard let xml = try? String(contentsOf: url, encoding: .utf8) else { return "" }

        // Collect text from <a:t> nodes, skipping slide number placeholder fields.
        var parts: [String] = []
        let pattern = #"<a:t[^>]*>([^<]*)</a:t>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return "" }
        let range = NSRange(xml.startIndex..., in: xml)
        regex.enumerateMatches(in: xml, range: range) { match, _, _ in
            guard let match, match.numberOfRanges > 1,
                  let textRange = Range(match.range(at: 1), in: xml) else { return }
            let text = String(xml[textRange])
            if text != "\u{200B}" && !text.isEmpty {
                parts.append(text)
            }
        }

        return parts.joined()
            .replacingOccurrences(of: "\u{000B}", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func slideNumber(from fileName: String) -> Int {
        let digits = fileName.filter(\.isNumber)
        return Int(digits) ?? 0
    }
}
