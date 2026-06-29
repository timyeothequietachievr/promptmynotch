import AppKit
import SwiftUI

@MainActor
final class PrompterWindowController: NSObject, NSWindowDelegate {
    static let shared = PrompterWindowController()

    private var panel: PrompterPanel?
    private var hostingView: NSHostingView<PrompterContainerView>?
    private var clickMonitor: Any?
    weak var appState: AppState?

    private static let windowWidthKey = "prompter_window_width"
    private static let windowHeightKey = "prompter_window_height"
    private static let minWidth: CGFloat = 320
    private static let minHeight: CGFloat = 120
    private static let maxWidth: CGFloat = 1200
    private static let maxHeight: CGFloat = 500

    func setup() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func bind(appState: AppState) {
        self.appState = appState
    }

    func show(appState: AppState) {
        self.appState = appState
        if panel == nil {
            createPanel(appState: appState)
        } else if let hostingView {
            hostingView.rootView = PrompterContainerView(appState: appState)
        }
        positionAtNotch()
        panel?.orderFrontRegardless()
        installClickMonitor()
        CameraMirrorWindowController.shared.syncSizeToPrompterIfNeeded()
    }

    func hide() {
        removeClickMonitor()
        PrompterClickRouter.shared.clear()
        panel?.orderOut(nil)
        PrompterTextColorPanel.shared.hide()
    }

    func makeKey() {
        panel?.makeKeyAndOrderFront(nil)
    }

    func setEditModeActive(_ active: Bool) {
        panel?.allowsTextEditing = active
        if active {
            removeClickMonitor()
            makeKey()
        } else if panel?.isVisible == true {
            installClickMonitor()
        }
    }

    var prompterFrame: NSRect? {
        panel?.frame
    }

    var isPrompterVisible: Bool {
        panel?.isVisible == true
    }

    func referencePrompterHeight(for screen: NSScreen? = nil) -> CGFloat {
        if let panel, panel.isVisible {
            return panel.frame.height
        }

        let defaults = UserDefaults.standard
        if let saved = defaults.object(forKey: Self.windowHeightKey) as? Double {
            return CGFloat(saved)
        }

        let resolvedScreen = screen ?? NSScreen.main ?? NSScreen.screens[0]
        let notchHeight = max(resolvedScreen.safeAreaInsets.top, 32)
        return 200 + notchHeight
    }

    private func createPanel(appState: AppState) {
        let frame = notchFrame(for: NSScreen.main)
        let panel = PrompterPanel(contentRect: frame)
        panel.delegate = self
        let rootView = PrompterContainerView(appState: appState)
        let hosting = PrompterHostingView(rootView: rootView)
        hosting.frame = panel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        panel.contentView = hosting
        self.panel = panel
        self.hostingView = hosting
    }

    private func positionAtNotch() {
        guard let panel else { return }
        let screen = panel.screen ?? NSScreen.main
        let frame = notchFrame(for: screen, size: panel.frame.size)
        panel.setFrame(frame, display: true)
        panel.applyCaptureExclusion()
    }

    private func notchFrame(for screen: NSScreen?, size: NSSize? = nil) -> NSRect {
        guard let screen else {
            let width = size?.width ?? 560
            let height = size?.height ?? 232
            return NSRect(x: 200, y: 400, width: width, height: height)
        }

        let full = screen.frame
        let resolvedSize = size ?? savedWindowSize(for: screen)
        let width = clamp(resolvedSize.width, min: Self.minWidth, max: Self.maxWidth)
        let height = clamp(resolvedSize.height, min: Self.minHeight, max: Self.maxHeight)
        let x = full.midX - width / 2
        let y = full.maxY - height
        return NSRect(x: x, y: y, width: width, height: height)
    }

    private func savedWindowSize(for screen: NSScreen) -> NSSize {
        let defaults = UserDefaults.standard
        let savedWidth = defaults.object(forKey: Self.windowWidthKey) as? Double
        let savedHeight = defaults.object(forKey: Self.windowHeightKey) as? Double
        let defaultWidth = min(560, screen.frame.width * 0.55)
        let notchHeight = max(screen.safeAreaInsets.top, 32)
        let defaultHeight = 200 + notchHeight
        return NSSize(
            width: clamp(CGFloat(savedWidth ?? Double(defaultWidth)), min: Self.minWidth, max: Self.maxWidth),
            height: clamp(CGFloat(savedHeight ?? Double(defaultHeight)), min: Self.minHeight, max: Self.maxHeight)
        )
    }

    private func saveWindowSize(_ size: NSSize) {
        UserDefaults.standard.set(Double(size.width), forKey: Self.windowWidthKey)
        UserDefaults.standard.set(Double(size.height), forKey: Self.windowHeightKey)
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(maxValue, Swift.max(minValue, value))
    }

    @objc private func screenParametersChanged() {
        positionAtNotch()
        CameraMirrorWindowController.shared.prompterDidMove()
    }

    func windowDidResize(_ notification: Notification) {
        guard let panel = notification.object as? PrompterPanel else { return }
        saveWindowSize(panel.frame.size)
        CameraMirrorWindowController.shared.prompterDidMove()
    }

    func windowDidMove(_ notification: Notification) {
        guard notification.object is PrompterPanel else { return }
        CameraMirrorWindowController.shared.prompterDidMove()
    }

    private func installClickMonitor() {
        removeClickMonitor()
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp, .leftMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel, panel.isVisible, event.window === panel else {
                return event
            }

            guard event.type == .leftMouseUp else { return event }

            let isDoubleClick = event.clickCount == 2
            let isOptionClick = event.modifierFlags.contains(.option) && event.clickCount == 1
            guard isDoubleClick || isOptionClick else { return event }

            guard let textView = PrompterClickRouter.shared.textAreaView else { return event }

            let local = textView.convert(event.locationInWindow, from: nil)
            guard textView.bounds.contains(local) else { return event }

            if let capture = textView as? PrompterTextAreaCaptureNSView {
                capture.deliverClickFromMonitor(event)
            } else {
                PrompterClickRouter.shared.handleClick(at: local)
            }

            return event
        }
    }

    private func removeClickMonitor() {
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
    }
}
