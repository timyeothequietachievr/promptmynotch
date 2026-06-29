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

        panel.orderFront(nil)
        positionBelowPrompter(panel)
    }

    func hide() {
        NSColorPanel.shared.orderOut(nil)
        onColorChange = nil
    }

    private func positionBelowPrompter(_ panel: NSColorPanel) {
        guard let prompterFrame = PrompterWindowController.shared.prompterFrame else { return }

        DispatchQueue.main.async {
            let size = panel.frame.size
            let origin = NSPoint(
                x: prompterFrame.midX - size.width / 2,
                y: prompterFrame.minY - size.height
            )
            panel.setFrameOrigin(origin)
        }
    }

    @objc private func colorChanged(_ sender: NSColorPanel) {
        onColorChange?(sender.color)
    }
}
