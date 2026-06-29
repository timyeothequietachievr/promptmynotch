import AppKit

final class CameraMirrorPanel: NSPanel {
    /// Above the teleprompter (statusBar) and normal floating windows.
    private static let alwaysOnTopLevel = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)

    var allowsTextEditing = false

    override var canBecomeKey: Bool { allowsTextEditing }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = Self.alwaysOnTopLevel
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenPrimary]
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        isMovable = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hideStandardWindowButtons()
    }

    func configure(shape: CameraMirrorShape) {
        styleMask = shape == .rectangle
            ? [.borderless, .fullSizeContentView, .resizable]
            : [.borderless, .fullSizeContentView]
        level = Self.alwaysOnTopLevel
        hidesOnDeactivate = false
        isMovable = true
        isMovableByWindowBackground = true
        hideStandardWindowButtons()
    }

    override func orderFrontRegardless() {
        level = Self.alwaysOnTopLevel
        super.orderFrontRegardless()
    }

    private func hideStandardWindowButtons() {
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }

}
