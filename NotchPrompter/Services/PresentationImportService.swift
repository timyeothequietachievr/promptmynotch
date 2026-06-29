import Foundation

@MainActor
enum PresentationImportService {
    static func importGoogleSlides(urlOrID: String, browser: InstalledBrowser) async throws -> ImportedPresentation {
        let token: String
        if let existing = GoogleOAuthService.shared.accessToken {
            token = existing
        } else {
            token = try await GoogleOAuthService.shared.authenticate(in: browser)
        }
        return try await GoogleSlidesImporter().importNotes(from: urlOrID, accessToken: token)
    }

    static func importPowerPoint(from fileURL: URL) throws -> ImportedPresentation {
        try PPTXImporter().importNotes(from: fileURL, source: .powerPoint)
    }

    static func importGoogleSlidesPPTX(from fileURL: URL) throws -> ImportedPresentation {
        try importPowerPoint(from: fileURL)
    }

    static func importKeynote(from fileURL: URL) async throws -> ImportedPresentation {
        try await KeynoteImporter().importNotes(from: fileURL)
    }
}
