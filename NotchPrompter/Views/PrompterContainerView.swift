import AppKit
import SwiftUI

struct PrompterContainerView: View {
    @Bindable var appState: AppState
    @StateObject private var scrollEngine = ScrollEngine()
    @StateObject private var speechScroller = SpeechLineScroller()
    @StateObject private var elapsedTimer = PrompterElapsedTimer()
    @State private var voiceError: String?
    @State private var prompterLines: [PrompterLine] = []
    @State private var viewportHeight: CGFloat = 0
    @State private var interactionState = PrompterInteractionState()
    @State private var isEditMode = false
    @State private var editDraftText = ""
    @State private var editOriginalText = ""
    @State private var editInsertion = PrompterEditInsertion()

    var body: some View {
        VStack(spacing: 0) {
            PrompterWindowDragHandle()
                .frame(maxWidth: .infinity)
                .frame(height: 16)

            prompterToolbarChrome

            if isEditMode {
                VStack(spacing: 6) {
                    Text("Double-click a word to toggle ALL CAPS emphasis")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .allowsHitTesting(false)

                    PrompterEditSnippetBar(insertion: $editInsertion)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }

            ZStack {
                if let countdown = scrollEngine.countdown {
                    ZStack {
                        Text("\(countdown)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.black.opacity(0.65))

                        PrompterWindowDragHandle()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if isEditMode {
                    PrompterSlideEditor(
                        text: $editDraftText,
                        insertion: $editInsertion,
                        fontSize: appState.fontSize,
                        textColor: Color(hex: appState.textColorHex) ?? .white
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if appState.presentationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    emptySpeakerNotesPrompt
                } else {
                    PrompterView(
                        interaction: interactionState,
                        text: appState.presentationText,
                        fontSize: appState.fontSize,
                        textColor: Color(hex: appState.textColorHex) ?? .white,
                        offset: scrollEngine.offset,
                        highlightedWordIndices: speechScroller.highlightedWordIndices,
                        smallCapsWordIndices: appState.smallCapsWordIndices(for: appState.currentSlideIndex),
                        wordCapsDisplayRevision: appState.wordCapsDisplayRevision,
                        onContentHeightChange: { contentHeight, viewportHeight in
                            scrollEngine.setContentHeight(contentHeight, viewport: viewportHeight)
                            self.viewportHeight = viewportHeight
                        },
                        onLineLayoutChange: { lines, _, viewport in
                            prompterLines = lines
                            viewportHeight = viewport
                            speechScroller.updateLayout(
                                text: appState.presentationText,
                                lines: lines,
                                scrollOffset: scrollEngine.offset,
                                viewportHeight: viewport
                            )
                        },
                        onManualScroll: { delta in
                            scrollEngine.adjustOffset(by: delta)
                            speechScroller.updateLayout(
                                text: appState.presentationText,
                                lines: prompterLines,
                                scrollOffset: scrollEngine.offset,
                                viewportHeight: viewportHeight
                            )
                        }
                    )
                    .onAppear {
                        interactionState.onToggleWord = { wordIndex in
                            appState.toggleWordCaps(at: wordIndex)
                        }
                    }
                    .id("prompter-\(appState.presentationSlideRevision)-\(appState.currentSlideIndex)-\(appState.wordCapsDisplayRevision)")
                    .onHover { _ in
                        scrollEngine.setPaused(appState.isPaused)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            NotchPrompterBackground()
        )
        .clipShape(NotchShape())
        .onAppear {
            wireSpeechScroller()
            VoiceInputDeviceService.shared.refreshDevices()
            beginPresentation()
        }
        .onDisappear { endPresentation() }
        .onChange(of: appState.isPresenting) { _, presenting in
            if presenting {
                beginPresentation()
            } else {
                endPresentation()
            }
        }
        .onChange(of: appState.presentationSlideRevision) { _, _ in
            if isEditMode {
                syncEditDraftFromPresentation()
            } else {
                scrollEngine.reset()
                speechScroller.resetProgress()
                if scrollEngine.isScrolling == false, scrollEngine.countdown == nil, appState.isPresenting {
                    scrollEngine.start()
                }
            }
        }
        .onChange(of: scrollEngine.offset) { _, offset in
            speechScroller.updateLayout(
                text: appState.presentationText,
                lines: prompterLines,
                scrollOffset: offset,
                viewportHeight: viewportHeight
            )
        }
        .onChange(of: appState.scrollSpeed) { _, speed in
            scrollEngine.configure(speed: speed, voiceEnabled: appState.voiceActivationEnabled)
        }
        .onChange(of: appState.voiceActivationEnabled) { _, enabled in
            scrollEngine.configure(speed: appState.scrollSpeed, voiceEnabled: enabled)
        }
        .onChange(of: appState.currentSlideIndex) { _, _ in
            if isEditMode {
                cancelEditMode()
            }
        }
    }

    private var prompterToolbarChrome: some View {
        VStack(spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                HStack(spacing: 8) {
                    if appState.slideCount > 1 {
                        Text("Slide \(appState.currentSlideIndex + 1)/\(appState.slideCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .prompterToolbarCapsule()
                    }

                    PrompterTimerBar(timer: elapsedTimer)

                    if !isEditMode {
                        Button {
                            enterEditMode()
                        } label: {
                            PrompterToolbarStyle.filledCircleIcon(
                                systemName: "pencil.circle.fill",
                                primary: .white,
                                secondary: Color.white.opacity(0.28)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Edit speaker notes")
                    }
                }

                Spacer(minLength: 0)
                    .overlay {
                        PrompterWindowDragHandle()
                    }

                HStack(spacing: 8) {
                    if isEditMode {
                        editModeToolbar
                    } else {
                        presentModeToolbar
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .background {
                PrompterWindowDragHandle()
            }
            .contentShape(Rectangle())

            VoiceInputMeterBar(
                level: speechScroller.level,
                isActive: speechScroller.isSpeaking,
                micSensitivity: appState.micSensitivity,
                onDeviceChange: {
                    Task {
                        do {
                            try await speechScroller.restart(sensitivity: appState.micSensitivity)
                        } catch {
                            voiceError = error.localizedDescription
                        }
                    }
                }
            )
                .opacity(isEditMode ? 0.35 : 1)

            if let voiceError {
                Text(voiceError)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .allowsHitTesting(false)
            }
            if let syncStatus = appState.slidesSyncStatus {
                Text(syncStatus)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var presentModeToolbar: some View {
        Button {
            appState.toggleCameraMirror(anchorToPrompter: true)
        } label: {
            PrompterToolbarStyle.filledCircleIcon(
                systemName: "video.circle.fill",
                primary: appState.cameraMirrorVisible ? .green : .white,
                secondary: Color.white.opacity(0.28)
            )
        }
        .buttonStyle(.plain)
        .help("Camera mirror")

        Button {
            appState.showTextColorPanel()
        } label: {
            PrompterToolbarStyle.textColorCircleIcon(
                color: Color(hex: appState.textColorHex) ?? .white
            )
        }
        .buttonStyle(.plain)
        .help("Text color")

        Button {
            appState.adjustFontSize(by: -1)
        } label: {
            PrompterToolbarStyle.filledCircleIcon(
                systemName: "minus.circle.fill",
                primary: .white,
                secondary: Color.white.opacity(0.28)
            )
        }
        .buttonStyle(.plain)
        .disabled(appState.fontSize <= 12)
        .help("Decrease text size")

        Button {
            appState.adjustFontSize(by: 1)
        } label: {
            PrompterToolbarStyle.filledCircleIcon(
                systemName: "plus.circle.fill",
                primary: .white,
                secondary: Color.white.opacity(0.28)
            )
        }
        .buttonStyle(.plain)
        .disabled(appState.fontSize >= 48)
        .help("Increase text size")

        Button {
            appState.stopPresentation()
        } label: {
            PrompterToolbarStyle.filledCircleIcon(
                systemName: "xmark.circle.fill",
                primary: .white,
                secondary: Color.white.opacity(0.28)
            )
        }
        .buttonStyle(.plain)
        .help("Stop presentation")
    }

    private var emptySpeakerNotesPrompt: some View {
        VStack {
            Spacer()
            Button {
                enterEditMode()
            } label: {
                Text("Click to add speaker notes")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var editModeToolbar: some View {
        Button {
            appState.showTextColorPanel()
        } label: {
            PrompterToolbarStyle.textColorCircleIcon(
                color: Color(hex: appState.textColorHex) ?? .white
            )
        }
        .buttonStyle(.plain)
        .help("Text color")

        Button {
            cancelEditMode()
        } label: {
            Text("Cancel")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Discard changes")

        Button {
            saveEditMode()
        } label: {
            Text("Save")
                .font(.caption.weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.95), in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Save speaker notes")
    }

    private func enterEditMode() {
        syncEditDraftFromPresentation()
        editOriginalText = editDraftText
        editInsertion = PrompterEditInsertion()
        scrollEngine.setPaused(true)
        isEditMode = true
        PrompterWindowController.shared.setEditModeActive(true)
    }

    private func cancelEditMode() {
        editDraftText = editOriginalText
        isEditMode = false
        scrollEngine.setPaused(appState.isPaused)
        PrompterWindowController.shared.setEditModeActive(false)
    }

    private func saveEditMode() {
        appState.savePresentationSlideText(at: appState.currentSlideIndex, text: editDraftText)
        editOriginalText = editDraftText
        isEditMode = false
        scrollEngine.setPaused(appState.isPaused)
        PrompterWindowController.shared.setEditModeActive(false)
    }

    private func syncEditDraftFromPresentation() {
        editDraftText = appState.presentationText
        editOriginalText = editDraftText
    }

    private func wireSpeechScroller() {
        speechScroller.onLineAdvance = { completedLineIndex in
            let nextIndex = completedLineIndex + 1
            guard nextIndex < prompterLines.count else { return }
            scrollEngine.scrollToLine(prompterLines[nextIndex])
            speechScroller.updateLayout(
                text: appState.presentationText,
                lines: prompterLines,
                scrollOffset: scrollEngine.offset,
                viewportHeight: viewportHeight
            )
        }
    }

    private func beginPresentation() {
        guard appState.isPresenting else { return }
        voiceError = nil
        scrollEngine.configure(speed: appState.scrollSpeed, voiceEnabled: appState.voiceActivationEnabled)
        scrollEngine.reset()
        speechScroller.resetProgress()

        if appState.voiceActivationEnabled {
            scrollEngine.setVoiceActive(false)
            Task {
                do {
                    try await speechScroller.start(sensitivity: appState.micSensitivity)
                } catch {
                    voiceError = error.localizedDescription
                }
            }
        } else {
            scrollEngine.setVoiceActive(true)
        }

        scrollEngine.startCountdown(seconds: appState.countdownSeconds) {
            elapsedTimer.start()
        }
        PrompterWindowController.shared.show(appState: appState)
    }

    private func endPresentation() {
        if isEditMode {
            cancelEditMode()
        }
        elapsedTimer.stop()
        scrollEngine.stop()
        speechScroller.stop()
        PrompterWindowController.shared.hide()
    }
}

struct VoiceInputMeterBar: View {
    @ObservedObject private var deviceService = VoiceInputDeviceService.shared
    let level: Float
    let isActive: Bool
    let micSensitivity: Double
    let onDeviceChange: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))

                Menu {
                    ForEach(deviceService.devices) { device in
                        Button(device.name) {
                            deviceService.selectDevice(uid: device.id)
                            onDeviceChange()
                        }
                    }
                    Divider()
                    Button("Refresh microphones") {
                        deviceService.refreshDevices()
                    }
                } label: {
                    Text(deviceService.selectedDeviceName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)

            VoiceLevelBar(level: level, isActive: isActive)
        }
    }
}

struct VoiceLevelBar: View {
    let level: Float
    let isActive: Bool

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(isActive ? Color.green.opacity(0.9) : Color.white.opacity(0.25))
                    .frame(width: 4, height: barHeight(for: index))
            }
        }
        .frame(height: 18)
        .animation(.easeOut(duration: 0.08), value: level)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let threshold = Float(index) / 12
        return CGFloat(6 + (level > threshold ? 12 * level : 0))
    }
}

@MainActor
final class PrompterElapsedTimer: ObservableObject {
    @Published private(set) var elapsedSeconds = 0

    private var startedAt: Date?
    private var tickTimer: Timer?

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        if minutes >= 100 {
            return String(format: "%03d:%02d", minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        stop()
        startedAt = Date()
        elapsedSeconds = 0
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
        startedAt = nil
    }

    func reset() {
        startedAt = Date()
        elapsedSeconds = 0
    }

    private func tick() {
        guard let startedAt else { return }
        elapsedSeconds = max(0, Int(Date().timeIntervalSince(startedAt)))
    }
}

struct PrompterTimerBar: View {
    @ObservedObject var timer: PrompterElapsedTimer

    var body: some View {
        HStack(spacing: 6) {
            Text(timer.formattedTime)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(.white)

            Button {
                timer.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.white.opacity(0.28))
                    .font(.system(size: 22))
            }
            .buttonStyle(.plain)
            .help("Reset timer")
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .frame(height: 28)
        .background(.white.opacity(0.12), in: Capsule())
        .fixedSize()
    }
}

struct NotchPrompterBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.88), Color.black.opacity(0.72)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    fileprivate func prompterToolbarIconButton() -> some View {
        font(.caption.weight(.semibold))
            .frame(width: 28, height: 28)
            .background(.white.opacity(0.12), in: Circle())
    }
}

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String? {
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components,
              components.count >= 3 else { return nil }
        let r = Int(round(components[0] * 255))
        let g = Int(round(components[1] * 255))
        let b = Int(round(components[2] * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
