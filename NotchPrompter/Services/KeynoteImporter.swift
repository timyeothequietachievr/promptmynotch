import AppKit
import Foundation

enum KeynoteImporterError: LocalizedError {
    case keynoteNotInstalled
    case fileNotFound
    case scriptFailed(String)
    case noSlides

    var errorDescription: String? {
        switch self {
        case .keynoteNotInstalled:
            return "Keynote is not installed. Install Keynote from the App Store to import .key files."
        case .fileNotFound:
            return "The Keynote file could not be found."
        case .scriptFailed(let detail):
            return "Keynote import failed: \(detail)"
        case .noSlides:
            return "No slides found in this Keynote presentation."
        }
    }
}

struct KeynoteImporter {
    func importNotes(from fileURL: URL) async throws -> ImportedPresentation {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw KeynoteImporterError.fileNotFound
        }

        guard isKeynoteInstalled() else {
            throw KeynoteImporterError.keynoteNotInstalled
        }

        let escapedPath = fileURL.path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        set output to ""
        set docTitle to "Keynote Presentation"
        tell application "Keynote"
            set theDoc to open POSIX file "\(escapedPath)"
            try
                set docTitle to name of theDoc
            end try
            set slideCount to count of slides of theDoc
            repeat with i from 1 to slideCount
                set theSlide to slide i of theDoc
                set theNotes to presenter notes of theSlide
                if theNotes is missing value then
                    set theNotes to ""
                end if
                set output to output & "|||SLIDE|||" & i & "|||NOTES|||" & theNotes
            end repeat
            close theDoc saving no
        end tell
        return docTitle & "|||TITLE|||" & output
        """

        let result = try await runAppleScript(script)
        return try parseResult(result, fileURL: fileURL)
    }

    private func isKeynoteInstalled() -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iWork.Keynote") != nil
    }

    private func runAppleScript(_ source: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                guard let script = NSAppleScript(source: source) else {
                    continuation.resume(throwing: KeynoteImporterError.scriptFailed("Invalid AppleScript"))
                    return
                }
                let output = script.executeAndReturnError(&error)
                if let error {
                    let message = (error[NSAppleScript.errorMessage] as? String) ?? "Unknown AppleScript error"
                    continuation.resume(throwing: KeynoteImporterError.scriptFailed(message))
                    return
                }
                continuation.resume(returning: output.stringValue ?? "")
            }
        }
    }

    private func parseResult(_ result: String, fileURL: URL) throws -> ImportedPresentation {
        let parts = result.components(separatedBy: "|||TITLE|||")
        let title = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? fileURL.deletingPathExtension().lastPathComponent
        let body = parts.count > 1 ? parts[1] : result

        let segments = body.components(separatedBy: "|||SLIDE|||").filter { !$0.isEmpty }
        var slides: [SlideNote] = []

        for segment in segments {
            let pieces = segment.components(separatedBy: "|||NOTES|||")
            guard pieces.count == 2, let number = Int(pieces[0]) else { continue }
            let text = pieces[1].trimmingCharacters(in: .whitespacesAndNewlines)
            slides.append(SlideNote(slideNumber: number, text: text))
        }

        guard !slides.isEmpty else { throw KeynoteImporterError.noSlides }

        slides.sort { $0.slideNumber < $1.slideNumber }
        return ImportedPresentation(title: title, source: .keynote, googlePresentationID: nil, slides: slides)
    }
}
