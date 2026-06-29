import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class AppState {
    var scripts: [Script] = []
    var selectedScriptID: UUID?
    var isPresenting = false
    var isPaused = false
    var scrollSpeed: Double = 60
    var fontSize: Double = 18
    var textColorHex: String = "#FFFFFF"
    var voiceActivationEnabled = true
    var micSensitivity: Double = 0.5
    var countdownSeconds = 3
    var isImporting = false
    var importError: String?
    var lastImportSource: ImportSource?
    var googleSlidesSyncEnabled = true
    var slidesSyncStatus: String?
    var currentSlideIndex = 0
    var presentationSlideRevision = 0
    /// Bumped when prompter word caps styling changes (separate from slide revision to avoid scroll reset).
    var wordCapsDisplayRevision = 0
    var showNewScriptPicker = false
    var showImportPanel = false
    var importPanelTab: ImportPanelView.ImportTab = .googleSlides
    var cameraMirrorVisible = false
    var cameraMirrorShape: CameraMirrorShape = .rectangle
    var cameraMirrorWindowType: CameraMirrorWindowType = .popover
    var cameraMirrorSnapPosition: CameraMirrorSnapPosition = .topRight
    var cameraMirrorDisplayID: String?
    var cameraMirrorLockAspectRatio = false
    var cameraMirrorManualPosition = true
    var cameraMirrorKeepInFront = true
    var cameraMirrorCloseWhenUnfocused = false
    var cameraMirrorFlippedHorizontally = true

    private let store = ScriptStore()
    private var wordSmallCapsKeys: Set<String> = []

    var selectedScript: Script? {
        get {
            guard let id = selectedScriptID else { return scripts.first }
            return scripts.first { $0.id == id }
        }
        set {
            guard let newValue else { return }
            if let index = scripts.firstIndex(where: { $0.id == newValue.id }) {
                scripts[index] = newValue
            }
        }
    }

    var presentationText: String {
        guard let script = selectedScript else { return "" }
        return script.presentationText(at: currentSlideIndex)
    }

    var slideCount: Int {
        selectedScript?.slides?.count ?? 0
    }

    var isGoogleSlidesScript: Bool {
        selectedScript?.source == .googleSlides && selectedScript?.googlePresentationID != nil
    }

    init() {
        scripts = store.load()
        selectedScriptID = scripts.first?.id
        googleSlidesSyncEnabled = UserDefaults.standard.object(forKey: Self.googleSlidesSyncKey) as? Bool ?? true
        if let savedFontSize = UserDefaults.standard.object(forKey: Self.fontSizeKey) as? Double {
            fontSize = savedFontSize
        }
        if let savedColor = UserDefaults.standard.string(forKey: Self.textColorKey) {
            textColorHex = savedColor
        }
        // Always start camera mirror in rectangle mode on app launch.
        cameraMirrorShape = .rectangle
        if let savedShapeRaw = UserDefaults.standard.string(forKey: Self.cameraMirrorShapeKey) {
            if savedShapeRaw == "circle" || savedShapeRaw == CameraMirrorShape.smallCircle.rawValue {
                // Legacy / placeholder: map to big circle.
                UserDefaults.standard.set(CameraMirrorShape.bigCircle.rawValue, forKey: Self.cameraMirrorShapeKey)
            }
        }
        if let savedWindowType = UserDefaults.standard.string(forKey: Self.cameraMirrorWindowTypeKey),
           let windowType = CameraMirrorWindowType(rawValue: savedWindowType) {
            cameraMirrorWindowType = windowType
        }
        if let savedPosition = UserDefaults.standard.string(forKey: Self.cameraMirrorSnapPositionKey),
           let position = CameraMirrorSnapPosition(rawValue: savedPosition) {
            cameraMirrorSnapPosition = position
        }
        cameraMirrorDisplayID = UserDefaults.standard.string(forKey: Self.cameraMirrorDisplayIDKey)
        cameraMirrorLockAspectRatio = UserDefaults.standard.object(forKey: Self.cameraMirrorLockAspectRatioKey) as? Bool ?? false
        cameraMirrorManualPosition = UserDefaults.standard.object(forKey: Self.cameraMirrorManualPositionKey) as? Bool ?? true
        cameraMirrorKeepInFront = UserDefaults.standard.object(forKey: Self.cameraMirrorKeepInFrontKey) as? Bool ?? true
        cameraMirrorCloseWhenUnfocused = UserDefaults.standard.object(forKey: Self.cameraMirrorCloseWhenUnfocusedKey) as? Bool ?? false
        cameraMirrorFlippedHorizontally = UserDefaults.standard.object(forKey: Self.cameraMirrorFlipKey) as? Bool ?? true
        if let savedSmallCaps = UserDefaults.standard.array(forKey: Self.wordSmallCapsKeysKey) as? [String] {
            wordSmallCapsKeys = Set(savedSmallCaps)
        }
    }

    func openNewScriptPicker() {
        showNewScriptPicker = true
    }

    func handleNewScriptChoice(_ choice: NewScriptSheet.Choice) {
        showNewScriptPicker = false
        switch choice {
        case .googleSlides:
            importPanelTab = .googleSlides
            showImportPanel = true
        case .keynote:
            importPanelTab = .keynote
            showImportPanel = true
        case .powerPoint:
            importPanelTab = .powerPoint
            showImportPanel = true
        case .richText:
            createRichTextScript()
            showImportPanel = false
        }
    }

    func createNewScript(source: ImportSource = .richText) {
        let script = Script(title: "Untitled Script", content: "", source: source)
        scripts.insert(script, at: 0)
        selectedScriptID = script.id
        persist()
    }

    func createRichTextScript() {
        createNewScript(source: .richText)
    }

    func deleteScript(_ script: Script) {
        scripts.removeAll { $0.id == script.id }
        if selectedScriptID == script.id {
            selectedScriptID = scripts.first?.id
        }
        persist()
    }

    func updateSelectedScript(title: String, content: String, richContentRTF: Data) {
        guard var script = selectedScript else { return }
        script.title = title
        script.content = content
        script.richContentRTF = richContentRTF.isEmpty ? nil : richContentRTF
        script.updatedAt = .now
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
        }
        persist()
    }

    /// Commits script editor changes locally and syncs speaker notes to Google Slides when linked.
    func saveSelectedScriptEditorChanges(title: String, content: String, richContentRTF: Data) {
        guard let script = selectedScript,
              let index = scripts.firstIndex(where: { $0.id == script.id }) else { return }

        let updated = script.withEditorContent(
            title: title,
            content: content,
            richContentRTF: richContentRTF
        )
        scripts[index] = updated
        persist()
        presentationSlideRevision += 1

        if isGoogleSlidesScript, googleSlidesSyncEnabled, let slides = updated.slides, !slides.isEmpty {
            syncAllSpeakerNotesToGoogle(slides: slides)
        }
    }

    /// Saves edited speaker notes for the current slide from prompter edit mode.
    func savePresentationSlideText(at slideIndex: Int, text: String) {
        guard let script = selectedScript,
              let index = scripts.firstIndex(where: { $0.id == script.id }) else { return }

        let updated = script.withUpdatedSlideText(at: slideIndex, text: text)
        scripts[index] = updated
        persist()
        presentationSlideRevision += 1
        wordCapsDisplayRevision += 1
        clearWordCapsForSlide(scriptID: updated.id, slideIndex: slideIndex)

        if isGoogleSlidesScript, googleSlidesSyncEnabled, let slides = updated.slides, slideIndex < slides.count {
            syncSpeakerNotesTextToGoogle(slideIndex: slideIndex, slide: slides[slideIndex], text: text)
        }
    }

    private func clearWordCapsForSlide(scriptID: UUID, slideIndex: Int) {
        let prefix = "\(scriptID.uuidString)|\(slideIndex)|"
        let before = wordSmallCapsKeys.count
        wordSmallCapsKeys = Set(wordSmallCapsKeys.filter { !$0.hasPrefix(prefix) })
        if wordSmallCapsKeys.count != before {
            persistWordSmallCapsKeys()
            wordCapsDisplayRevision += 1
        }
    }

    private func syncSpeakerNotesTextToGoogle(slideIndex: Int, slide: SlideNote, text: String) {
        guard let script = selectedScript,
              let presentationID = script.googlePresentationID else { return }

        guard let token = GoogleOAuthService.shared.accessToken else {
            slidesSyncStatus = "Sign in with Google to update speaker notes."
            return
        }

        slidesSyncStatus = "Saving speaker notes…"
        Task {
            do {
                try await GoogleSlidesNotesUpdater().replaceSpeakerNotesText(
                    presentationID: presentationID,
                    slide: slide,
                    newText: text,
                    accessToken: token
                )
                slidesSyncStatus = nil
            } catch {
                slidesSyncStatus = error.localizedDescription
            }
        }
    }

    private func syncAllSpeakerNotesToGoogle(slides: [SlideNote]) {
        guard let script = selectedScript,
              let presentationID = script.googlePresentationID else { return }

        guard let token = GoogleOAuthService.shared.accessToken else {
            slidesSyncStatus = "Sign in with Google to update speaker notes."
            return
        }

        slidesSyncStatus = "Saving speaker notes…"
        Task {
            do {
                let updater = GoogleSlidesNotesUpdater()
                for slide in slides {
                    try await updater.replaceSpeakerNotesText(
                        presentationID: presentationID,
                        slide: slide,
                        newText: slide.text,
                        accessToken: token
                    )
                }
                slidesSyncStatus = nil
            } catch {
                slidesSyncStatus = error.localizedDescription
            }
        }
    }

    func applyImport(_ presentation: ImportedPresentation) {
        let script = Script(
            title: presentation.title,
            content: presentation.combinedScript,
            source: presentation.source,
            sourceReference: presentation.googlePresentationID,
            slides: presentation.slides
        )
        scripts.insert(script, at: 0)
        selectedScriptID = script.id
        lastImportSource = presentation.source
        persist()
    }

    func startPresentation(googleSlidesTriggered: Bool = false) {
        isPaused = false
        let wasPresenting = isPresenting
        isPresenting = true
        if !wasPresenting {
            presentationSlideRevision += 1
        }
        if googleSlidesTriggered || isGoogleSlidesScript {
            SlideSyncPermissions.ensureGranted(promptIfMissing: true)
        }
        if googleSlidesTriggered {
            UserDefaults.standard.set(true, forKey: Self.googleSlidesSessionKey)
        }
    }

    func stopPresentation(manual: Bool = true) {
        isPresenting = false
        isPaused = false
        UserDefaults.standard.set(false, forKey: Self.googleSlidesSessionKey)
        CameraMirrorWindowController.shared.hide()
        PrompterTextColorPanel.shared.hide()
        if manual {
            GoogleSlidesPresenterMonitor.shared.notifyManualStop()
        }
    }

    func togglePresentation() {
        if isPresenting {
            stopPresentation()
        } else {
            currentSlideIndex = 0
            presentationSlideRevision += 1
            startPresentation()
        }
    }

    func goToSlide(_ index: Int, force: Bool = false) {
        guard slideCount > 0 else { return }
        let clamped = min(max(0, index), slideCount - 1)
        if clamped != currentSlideIndex {
            currentSlideIndex = clamped
            presentationSlideRevision += 1
        } else if force {
            presentationSlideRevision += 1
        }
    }

    func selectScript(forGooglePresentationID presentationID: String) {
        guard let script = scripts.first(where: { $0.googlePresentationID == presentationID }) else { return }
        selectedScriptID = script.id
    }

    func setGoogleSlidesSyncEnabled(_ enabled: Bool) {
        googleSlidesSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.googleSlidesSyncKey)
        if enabled {
            SlideSyncPermissions.ensureGranted(promptIfMissing: true)
        }
    }

    func adjustSpeed(by delta: Double) {
        scrollSpeed = min(200, max(10, scrollSpeed + delta))
    }

    func adjustFontSize(by delta: Double) {
        setFontSize(fontSize + delta)
    }

    func setFontSize(_ size: Double) {
        fontSize = min(48, max(12, size))
        UserDefaults.standard.set(fontSize, forKey: Self.fontSizeKey)
    }

    func setTextColor(_ color: Color) {
        if let hex = color.hexString {
            textColorHex = hex
            UserDefaults.standard.set(hex, forKey: Self.textColorKey)
        }
    }

    func setTextColorHex(_ hex: String) {
        textColorHex = hex
        UserDefaults.standard.set(hex, forKey: Self.textColorKey)
    }

    func resetCameraMirrorToDefaults() {
        cameraMirrorShape = .rectangle
        UserDefaults.standard.set(CameraMirrorShape.rectangle.rawValue, forKey: Self.cameraMirrorShapeKey)
    }

    func toggleCameraMirror(anchorToPrompter: Bool = false) {
        CameraMirrorWindowController.shared.toggle(appState: self, anchorToPrompter: anchorToPrompter)
    }

    func showTextColorPanel() {
        PrompterTextColorPanel.shared.show(currentHex: textColorHex) { [weak self] nsColor in
            guard let self else { return }
            let rgb = nsColor.usingColorSpace(.sRGB) ?? nsColor
            let red = max(0, min(1, rgb.redComponent))
            let green = max(0, min(1, rgb.greenComponent))
            let blue = max(0, min(1, rgb.blueComponent))
            let hex = String(
                format: "#%02X%02X%02X",
                Int(round(red * 255)),
                Int(round(green * 255)),
                Int(round(blue * 255))
            )
            setTextColorHex(hex)
        }
    }

    func openCameraMirror() {
        CameraMirrorWindowController.shared.show(appState: self)
    }

    func setCameraMirrorShape(_ shape: CameraMirrorShape) {
        guard shape.isSelectable else { return }
        let shapeChanged = cameraMirrorShape != shape
        cameraMirrorShape = shape
        UserDefaults.standard.set(shape.rawValue, forKey: Self.cameraMirrorShapeKey)
        if cameraMirrorVisible {
            CameraMirrorWindowController.shared.applySettings(appState: self)
            if shapeChanged {
                CameraMirrorWindowController.shared.alignTopToPrompter()
            }
        }
    }

    func toggleCameraMirrorShape() {
        setCameraMirrorShape(cameraMirrorShape.toggled)
    }

    func toggleCameraMirrorFlip() {
        cameraMirrorFlippedHorizontally.toggle()
        UserDefaults.standard.set(cameraMirrorFlippedHorizontally, forKey: Self.cameraMirrorFlipKey)
    }

    func setCameraMirrorWindowType(_ type: CameraMirrorWindowType) {
        cameraMirrorWindowType = type
        UserDefaults.standard.set(type.rawValue, forKey: Self.cameraMirrorWindowTypeKey)
        if cameraMirrorVisible {
            CameraMirrorWindowController.shared.applySettings(appState: self)
        }
    }

    func setCameraMirrorSnapPosition(_ position: CameraMirrorSnapPosition) {
        cameraMirrorSnapPosition = position
        UserDefaults.standard.set(position.rawValue, forKey: Self.cameraMirrorSnapPositionKey)
        if cameraMirrorVisible, !cameraMirrorManualPosition {
            CameraMirrorWindowController.shared.applySettings(appState: self)
        }
    }

    func setCameraMirrorDisplayID(_ displayID: String?) {
        cameraMirrorDisplayID = displayID
        UserDefaults.standard.set(displayID, forKey: Self.cameraMirrorDisplayIDKey)
        if cameraMirrorVisible, !cameraMirrorManualPosition {
            CameraMirrorWindowController.shared.applySettings(appState: self)
        }
    }

    func setCameraMirrorLockAspectRatio(_ enabled: Bool) {
        cameraMirrorLockAspectRatio = enabled
        UserDefaults.standard.set(enabled, forKey: Self.cameraMirrorLockAspectRatioKey)
        if cameraMirrorVisible {
            CameraMirrorWindowController.shared.applySettings(appState: self)
        }
    }

    func setCameraMirrorManualPosition(_ enabled: Bool) {
        cameraMirrorManualPosition = enabled
        UserDefaults.standard.set(enabled, forKey: Self.cameraMirrorManualPositionKey)
        if cameraMirrorVisible, !enabled {
            CameraMirrorWindowController.shared.applySettings(appState: self)
        }
    }

    func setCameraMirrorKeepInFront(_ enabled: Bool) {
        cameraMirrorKeepInFront = enabled
        UserDefaults.standard.set(enabled, forKey: Self.cameraMirrorKeepInFrontKey)
        if cameraMirrorVisible {
            CameraMirrorWindowController.shared.applySettings(appState: self)
        }
    }

    func setCameraMirrorCloseWhenUnfocused(_ enabled: Bool) {
        cameraMirrorCloseWhenUnfocused = enabled
        UserDefaults.standard.set(enabled, forKey: Self.cameraMirrorCloseWhenUnfocusedKey)
    }

    func toggleWordCaps(at wordIndex: Int) {
        guard let script = selectedScript else { return }

        let slideIndex = currentSlideIndex
        let sourceText = script.presentationText(at: slideIndex)
        guard PrompterTextTokenizer.wordRange(at: wordIndex, in: sourceText) != nil else { return }

        let storageKey = wordSmallCapsStorageKey(scriptID: script.id, slideIndex: slideIndex, wordIndex: wordIndex)
        let enabling: Bool
        if wordSmallCapsKeys.contains(storageKey) {
            wordSmallCapsKeys.remove(storageKey)
            enabling = false
        } else {
            wordSmallCapsKeys.insert(storageKey)
            enabling = true
        }
        persistWordSmallCapsKeys()
        wordCapsDisplayRevision += 1

        Task {
            await Task.yield()
            syncSmallCapsToGoogleSlides(
                slideIndex: slideIndex,
                wordIndex: wordIndex,
                slideText: sourceText,
                enabled: enabling
            )
        }
    }

    func smallCapsWordIndices(for slideIndex: Int) -> Set<Int> {
        guard let script = selectedScript else { return [] }
        let prefix = "\(script.id.uuidString)|\(slideIndex)|"
        return Set(wordSmallCapsKeys.compactMap { key in
            guard key.hasPrefix(prefix) else { return nil }
            return Int(key.dropFirst(prefix.count))
        })
    }

    private func wordSmallCapsStorageKey(scriptID: UUID, slideIndex: Int, wordIndex: Int) -> String {
        "\(scriptID.uuidString)|\(slideIndex)|\(wordIndex)"
    }

    private func persistWordSmallCapsKeys() {
        UserDefaults.standard.set(Array(wordSmallCapsKeys), forKey: Self.wordSmallCapsKeysKey)
    }

    private func syncSmallCapsToGoogleSlides(
        slideIndex: Int,
        wordIndex: Int,
        slideText: String,
        enabled: Bool
    ) {
        guard isGoogleSlidesScript, googleSlidesSyncEnabled,
              let script = selectedScript,
              let presentationID = script.googlePresentationID,
              let slides = script.slides,
              slideIndex < slides.count else { return }

        guard let token = GoogleOAuthService.shared.accessToken else {
            slidesSyncStatus = "Sign in with Google to update speaker notes."
            return
        }

        let slide = slides[slideIndex]
        Task {
            do {
                try await GoogleSlidesNotesUpdater().setSmallCaps(
                    presentationID: presentationID,
                    slide: slide,
                    wordIndex: wordIndex,
                    slideText: slideText,
                    enabled: enabled,
                    accessToken: token
                )
                slidesSyncStatus = nil
            } catch {
                slidesSyncStatus = error.localizedDescription
            }
        }
    }

    private func combinedContent(from slides: [SlideNote]) -> String {
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

    private func persist() {
        store.save(scripts)
    }

    private static let googleSlidesSyncKey = "google_slides_sync_enabled"
    private static let googleSlidesSessionKey = "google_slides_auto_session"
    private static let fontSizeKey = "prompter_font_size"
    private static let textColorKey = "prompter_text_color"
    private static let cameraMirrorShapeKey = "camera_mirror_shape"
    private static let cameraMirrorWindowTypeKey = "camera_mirror_window_type"
    private static let cameraMirrorSnapPositionKey = "camera_mirror_snap_position"
    private static let cameraMirrorDisplayIDKey = "camera_mirror_display_id"
    private static let cameraMirrorLockAspectRatioKey = "camera_mirror_lock_aspect_ratio"
    private static let cameraMirrorManualPositionKey = "camera_mirror_manual_position"
    private static let cameraMirrorKeepInFrontKey = "camera_mirror_keep_in_front"
    private static let cameraMirrorCloseWhenUnfocusedKey = "camera_mirror_close_when_unfocused"
    private static let cameraMirrorFlipKey = "camera_mirror_flip_horizontal"
    private static let wordSmallCapsKeysKey = "prompter_word_small_caps_keys"
}
