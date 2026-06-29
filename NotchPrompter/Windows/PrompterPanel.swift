import AppKit

final class PrompterPanel: NSPanel {
    var allowsTextEditing = false

    override var canBecomeKey: Bool { allowsTextEditing }
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        minSize = NSSize(width: 320, height: 120)
        maxSize = NSSize(width: 1200, height: 500)
        hideStandardWindowButtons()

        applyCaptureExclusion()
    }

    func applyCaptureExclusion() {
        sharingType = .none
    }

    override func orderFrontRegardless() {
        applyCaptureExclusion()
        hideStandardWindowButtons()
        super.orderFrontRegardless()
    }

    private func hideStandardWindowButtons() {
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }
}
