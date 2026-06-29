import AppKit
import Foundation

@MainActor
final class GoogleSlidesPresenterMonitor {
    static let shared = GoogleSlidesPresenterMonitor()

    private var timer: Timer?
    private weak var appState: AppState?
    private var lastSlideKey: String?
    private var resolveTask: Task<Void, Never>?

    func bind(appState: AppState) {
        self.appState = appState
        startPolling()
    }

    func notifyManualStop() {}

    func startPolling() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.poll()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func poll() {
        guard let appState, appState.googleSlidesSyncEnabled else { return }

        guard let session = BrowserURLReader.currentBrowserSlideSession() else {
            if BrowserURLReader.lastProbeError != nil {
                appState.slidesSyncStatus = "Allow Automation for NotchPrompter → your browser in System Settings."
            } else {
                appState.slidesSyncStatus = nil
            }
            return
        }

        guard let script = appState.scripts.first(where: { $0.googlePresentationID == session.presentationID }) else {
            appState.slidesSyncStatus = nil
            return
        }

        appState.slidesSyncStatus = nil
        appState.selectScript(forGooglePresentationID: session.presentationID)

        let slideKey = "\(session.presentationID)-\(session.slideObjectId ?? "idx:\(session.slideIndex)")"
        guard slideKey != lastSlideKey else { return }

        if let slideIndex = resolveSlideIndexLocally(for: session, script: script) {
            applySlide(slideIndex: slideIndex, slideKey: slideKey, appState: appState)
            return
        }

        guard let objectId = session.slideObjectId else { return }

        resolveTask?.cancel()
        resolveTask = Task { @MainActor in
            let token = GoogleOAuthService.shared.accessToken
            if let index = await GoogleSlidesSlideIndexCache.slideIndex(
                presentationID: session.presentationID,
                objectId: objectId,
                accessToken: token
            ) {
                applySlide(slideIndex: index, slideKey: slideKey, appState: appState)
            } else {
                appState.slidesSyncStatus = "Re-import this deck from Google Slides to refresh slide IDs."
            }
        }
    }

    private func applySlide(slideIndex: Int, slideKey: String, appState: AppState) {
        lastSlideKey = slideKey
        appState.slidesSyncStatus = nil

        if !appState.isPresenting {
            appState.goToSlide(slideIndex, force: true)
            appState.startPresentation(googleSlidesTriggered: true)
        } else {
            appState.goToSlide(slideIndex, force: true)
        }
    }

    private func resolveSlideIndexLocally(for session: GoogleSlidesPresenterSession, script: Script) -> Int? {
        if let objectId = session.slideObjectId,
           let index = script.slideIndex(forObjectId: objectId) {
            return index
        }
        if session.slideObjectId == nil,
           let slides = script.slides, !slides.isEmpty,
           session.slideIndex >= 0 {
            return min(max(0, session.slideIndex), slides.count - 1)
        }
        return nil
    }
}
