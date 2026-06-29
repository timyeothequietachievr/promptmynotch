import AppKit
import SwiftUI

/// Reports the text-area frame and captures scroll / clicks in the AppKit layer.
struct PrompterTextAreaCaptureView: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void
    let onClick: (CGPoint) -> Void

    func makeNSView(context: Context) -> PrompterTextAreaCaptureNSView {
        let view = PrompterTextAreaCaptureNSView()
        view.onScroll = onScroll
        view.onClick = onClick
        PrompterClickRouter.shared.textAreaView = view
        return view
    }

    func updateNSView(_ nsView: PrompterTextAreaCaptureNSView, context: Context) {
        nsView.onScroll = onScroll
        nsView.onClick = onClick
        PrompterClickRouter.shared.textAreaView = nsView
    }

    static func dismantleNSView(_ nsView: PrompterTextAreaCaptureNSView, coordinator: ()) {
        if PrompterClickRouter.shared.textAreaView === nsView {
            PrompterClickRouter.shared.textAreaView = nil
        }
    }
}

final class PrompterTextAreaCaptureNSView: NSView {
    var onScroll: ((CGFloat) -> Void)?
    var onClick: ((CGPoint) -> Void)?
    private var lastClickTime: TimeInterval = 0

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }
        return self
    }

    override func scrollWheel(with event: NSEvent) {
        let deltaY: CGFloat
        if event.hasPreciseScrollingDeltas {
            deltaY = -event.scrollingDeltaY
        } else {
            deltaY = -event.deltaY * 4
        }
        let scaled = deltaY * (event.momentumPhase == .changed ? 0.85 : 1.0)
        onScroll?(scaled)
    }

    func deliverClickFromMonitor(_ event: NSEvent) {
        let local = convert(event.locationInWindow, from: nil)
        deliverClick(at: local)
    }

    private func deliverClick(at location: CGPoint) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastClickTime > 0.2 else { return }
        lastClickTime = now
        onClick?(location)
    }
}
