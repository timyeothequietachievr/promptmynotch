import AppKit
import SwiftUI

@MainActor
final class PrompterTextColorPanel: NSObject {
    static let shared = PrompterTextColorPanel()

    private var onColorChange: ((NSColor) -> Void)?

    func show(currentHex: String, onChange: @escaping (NSColor) -> Void) {
        onColorChange = onChange

        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.isContinuous = true
        panel.showsAlpha = false

        if let color = Color(hex: currentHex) {
            panel.color = NSColor(color)
        }

        positionNearPrompter(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        NSColorPanel.shared.orderOut(nil)
        onColorChange = nil
    }

    private func positionNearPrompter(_ panel: NSColorPanel) {
        guard let prompterFrame = PrompterWindowController.shared.prompterFrame else { return }
        let screenFrame = NSScreen.screens.first(where: { $0.frame.intersects(prompterFrame) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
        guard let screen = screenFrame else { return }

        let size = panel.frame.size
        var origin = NSPoint(
            x: prompterFrame.midX - size.width / 2,
            y: prompterFrame.minY - size.height - 10
        )

        if origin.y < screen.minY + 12 {
            origin.y = prompterFrame.maxY + 10
        }

        origin.x = min(max(origin.x, screen.minX + 8), screen.maxX - size.width - 8)
        origin.y = min(max(origin.y, screen.minY + 8), screen.maxY - size.height - 8)
        panel.setFrameOrigin(origin)
    }

    @objc private func colorChanged(_ sender: NSColorPanel) {
        // Ignore late close/reset events that can fire while the panel is dismissing.
        guard sender.isVisible else { return }
        onColorChange?(sender.color)
    }
}
