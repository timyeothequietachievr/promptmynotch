import AppKit
import SwiftUI

private enum PrompterAttachment: Equatable {
    case none
    case left
    case right
    case bottom
}

@MainActor
final class CameraMirrorWindowController: NSObject, NSWindowDelegate {
    static let shared = CameraMirrorWindowController()

    private var panel: CameraMirrorPanel?
    private var hostingView: NSHostingView<CameraMirrorView>?
    weak var appState: AppState?
    private var lockedAspectRatio: CGFloat?
    private var isApplyingAspectLock = false
    private var isApplyingSnap = false
    private var prompterAttachment: PrompterAttachment = .none
    private var frameBeforePolaroidEject: NSRect?

    private static let originXKey = "camera_mirror_origin_x"
    private static let originYKey = "camera_mirror_origin_y"
    private static let widthKey = "camera_mirror_width"
    private static let heightKey = "camera_mirror_height"
    private static let circleSizeKey = "camera_mirror_circle_size"
    private static let snapThreshold: CGFloat = 28
    private static let polaroidEjectExtraHeight: CGFloat = 230
    /// Extra width so the top control bar fits comfortably (height still matches prompter).
    private static let prompterWidthMultiplier: CGFloat = 1.55

    func beginPolaroidEject(extraHeight: CGFloat) {
        guard let panel, frameBeforePolaroidEject == nil else { return }
        frameBeforePolaroidEject = panel.frame
        var frame = panel.frame
        frame.size.height += extraHeight
        frame.origin.y -= extraHeight
        panel.setFrame(frame, display: true)
    }

    func endPolaroidEject() {
        guard let panel, let saved = frameBeforePolaroidEject else { return }
        panel.setFrame(saved, display: true)
        frameBeforePolaroidEject = nil
    }

    func setPolaroidEditingActive(_ active: Bool) {
        panel?.isMovableByWindowBackground = !active
    }

    func bind(appState: AppState) {
        self.appState = appState
    }

    var panelWidth: CGFloat? {
        panel?.frame.width
    }

    func show(appState: AppState, anchorToPrompter: Bool = false) {
        self.appState = appState
        if panel == nil {
            createPanel(appState: appState)
        } else if let hostingView {
            hostingView.rootView = CameraMirrorView(appState: appState)
        }
        applySettings(appState: appState)
        if anchorToPrompter {
            if appState.cameraMirrorShape != .rectangle {
                appState.setCameraMirrorShape(.rectangle)
            }
            applyPrompterMatchedSize(appState: appState)
            positionAdjacentToPrompter(appState: appState)
            prompterAttachment = .right
        }
        panel?.orderFrontRegardless()
        appState.cameraMirrorVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        appState?.cameraMirrorVisible = false
        prompterAttachment = .none
    }

    func toggle(appState: AppState, anchorToPrompter: Bool = false) {
        if appState.cameraMirrorVisible {
            hide()
        } else {
            show(appState: appState, anchorToPrompter: anchorToPrompter)
        }
    }

    func positionAdjacentToPrompter(appState: AppState) {
        guard let panel,
              let prompterFrame = PrompterWindowController.shared.prompterFrame else { return }

        let size = windowSize(for: appState)
        let origin = NSPoint(
            x: prompterFrame.maxX,
            y: prompterTopY(for: size)
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        saveFrame(panel.frame)
    }

    func alignTopToPrompter() {
        guard let panel,
              let prompterFrame = PrompterWindowController.shared.prompterFrame else { return }

        var frame = panel.frame
        frame.origin.y = prompterTopY(for: frame.size)
        panel.setFrame(frame, display: true)
        saveFrame(frame)
    }

    func prompterDidMove() {
        guard prompterAttachment != .none,
              let panel,
              let prompterFrame = PrompterWindowController.shared.prompterFrame else { return }

        let size: NSSize
        if appState?.cameraMirrorShape == .rectangle {
            size = prompterMatchedRectangleSize(prompterFrame: prompterFrame)
        } else {
            size = panel.frame.size
        }

        let frame = attachedFrame(for: prompterAttachment, prompterFrame: prompterFrame, size: size)
        isApplyingSnap = true
        panel.setFrame(frame, display: true)
        isApplyingSnap = false
        saveFrame(frame)
    }

    func applySettings(appState: AppState) {
        guard let panel else { return }

        panel.configure(shape: appState.cameraMirrorShape)

        let shape = appState.cameraMirrorShape
        panel.minSize = shape.minSize
        panel.maxSize = shape.maxSize

        let size = resolvedSize(for: appState, panel: panel)
        let origin: NSPoint

        if prompterAttachment != .none, let prompterFrame = PrompterWindowController.shared.prompterFrame {
            origin = attachedFrame(
                for: prompterAttachment,
                prompterFrame: prompterFrame,
                size: size
            ).origin
        } else if let savedOrigin = savedManualOrigin() {
            origin = savedOrigin
        } else {
            let screen = targetScreen(for: appState)
            origin = appState.cameraMirrorSnapPosition.origin(
                for: size,
                in: screen.visibleFrame
            )
        }

        panel.setFrame(NSRect(origin: origin, size: size), display: true)

        if appState.cameraMirrorLockAspectRatio && shape == .rectangle {
            lockedAspectRatio = size.width / size.height
        }
    }

    func applyShape(_ shape: CameraMirrorShape) {
        guard let appState else { return }
        applySettings(appState: appState)
    }

    private func createPanel(appState: AppState) {
        let frame = frameForNewPanel(appState: appState)
        let panel = CameraMirrorPanel(contentRect: frame)
        panel.delegate = self

        let rootView = CameraMirrorView(appState: appState)
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = panel.contentView?.bounds ?? .zero
        hosting.autoresizingMask = [.width, .height]
        hosting.wantsLayer = true
        hosting.layer?.masksToBounds = false
        panel.contentView = hosting
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.masksToBounds = false

        self.panel = panel
        self.hostingView = hosting
    }

    private func frameForNewPanel(appState: AppState) -> NSRect {
        let size = windowSize(for: appState)
        let origin: NSPoint

        if let savedOrigin = savedManualOrigin() {
            origin = savedOrigin
        } else {
            let screen = targetScreen(for: appState)
            origin = appState.cameraMirrorSnapPosition.origin(for: size, in: screen.visibleFrame)
        }

        return NSRect(origin: origin, size: size)
    }

    private func resolvedSize(for appState: AppState, panel: NSWindow?) -> NSSize {
        if appState.cameraMirrorShape == .circle, let panel {
            let side = clamp(
                max(panel.frame.width, panel.frame.height),
                min: appState.cameraMirrorShape.minSize.width,
                max: appState.cameraMirrorShape.maxSize.width
            )
            return NSSize(width: side, height: side)
        }
        return windowSize(for: appState)
    }

    private func windowSize(for appState: AppState) -> NSSize {
        switch appState.cameraMirrorShape {
        case .rectangle:
            return savedRectangleSize(for: appState)
        case .circle:
            let side = UserDefaults.standard.object(forKey: Self.circleSizeKey) as? Double
                ?? Double(appState.cameraMirrorShape.defaultSize.width)
            let clamped = clamp(CGFloat(side), min: appState.cameraMirrorShape.minSize.width, max: appState.cameraMirrorShape.maxSize.width)
            return NSSize(width: clamped, height: clamped)
        }
    }

    private func applyPrompterMatchedSize(appState: AppState) {
        guard appState.cameraMirrorShape == .rectangle,
              let panel,
              let prompterFrame = PrompterWindowController.shared.prompterFrame else { return }

        let size = prompterMatchedRectangleSize(prompterFrame: prompterFrame)
        var frame = panel.frame
        frame.size = size
        frame.origin.y = prompterTopY(for: size, fallbackY: frame.origin.y)
        panel.setFrame(frame, display: true)
        saveFrame(frame)
    }

    private func prompterMatchedRectangleSize(prompterFrame: NSRect) -> NSSize {
        let shape = CameraMirrorShape.rectangle
        let height = clamp(prompterFrame.height, min: shape.minSize.height, max: shape.maxSize.height)
        let aspect = shape.defaultSize.height / shape.defaultSize.width
        let baseWidth = height / aspect
        let width = clamp(
            baseWidth * Self.prompterWidthMultiplier,
            min: max(shape.minSize.width, 520),
            max: shape.maxSize.width
        )
        return NSSize(width: width, height: height)
    }

    private func prompterTopY(for size: NSSize, fallbackY: CGFloat? = nil) -> CGFloat {
        guard let prompterFrame = PrompterWindowController.shared.prompterFrame else {
            return fallbackY ?? 0
        }
        return prompterFrame.maxY - size.height
    }

    private func attachedFrame(
        for attachment: PrompterAttachment,
        prompterFrame: NSRect,
        size: NSSize
    ) -> NSRect {
        switch attachment {
        case .none:
            return NSRect(origin: .zero, size: size)
        case .right:
            return NSRect(
                x: prompterFrame.maxX,
                y: prompterFrame.maxY - size.height,
                width: size.width,
                height: size.height
            )
        case .left:
            return NSRect(
                x: prompterFrame.minX - size.width,
                y: prompterFrame.maxY - size.height,
                width: size.width,
                height: size.height
            )
        case .bottom:
            return NSRect(
                x: prompterFrame.minX,
                y: prompterFrame.minY - size.height,
                width: size.width,
                height: size.height
            )
        }
    }

    private func snapFrame(_ frame: NSRect, to prompterFrame: NSRect) -> (NSRect, PrompterAttachment)? {
        let threshold = Self.snapThreshold

        let rightOrigin = NSPoint(x: prompterFrame.maxX, y: prompterFrame.maxY - frame.height)
        if abs(frame.minX - rightOrigin.x) < threshold,
           abs(frame.maxY - prompterFrame.maxY) < threshold {
            return (NSRect(origin: rightOrigin, size: frame.size), .right)
        }

        let leftOrigin = NSPoint(x: prompterFrame.minX - frame.width, y: prompterFrame.maxY - frame.height)
        if abs(frame.maxX - prompterFrame.minX) < threshold,
           abs(frame.maxY - prompterFrame.maxY) < threshold {
            return (NSRect(origin: leftOrigin, size: frame.size), .left)
        }

        let bottomOrigin = NSPoint(x: prompterFrame.minX, y: prompterFrame.minY - frame.height)
        if abs(frame.minY - bottomOrigin.y) < threshold,
           frame.minX >= prompterFrame.minX - threshold,
           frame.maxX <= prompterFrame.maxX + threshold {
            return (NSRect(origin: bottomOrigin, size: frame.size), .bottom)
        }

        return nil
    }

    private func targetScreen(for appState: AppState) -> NSScreen {
        NSScreen.screen(forDisplayIdentifier: appState.cameraMirrorDisplayID) ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private func savedManualOrigin() -> NSPoint? {
        let defaults = UserDefaults.standard
        guard let x = defaults.object(forKey: Self.originXKey) as? Double,
              let y = defaults.object(forKey: Self.originYKey) as? Double else {
            return nil
        }
        return NSPoint(x: x, y: y)
    }

    private func savedRectangleSize(for appState: AppState) -> NSSize {
        let defaults = UserDefaults.standard
        let hasSavedSize = defaults.object(forKey: Self.widthKey) != nil
            || defaults.object(forKey: Self.heightKey) != nil

        if !hasSavedSize,
           let prompterFrame = PrompterWindowController.shared.prompterFrame {
            return prompterMatchedRectangleSize(prompterFrame: prompterFrame)
        }

        let defaultSize = appState.cameraMirrorShape.defaultSize
        let width = CGFloat(defaults.object(forKey: Self.widthKey) as? Double ?? Double(defaultSize.width))
        let height = CGFloat(defaults.object(forKey: Self.heightKey) as? Double ?? Double(defaultSize.height))
        let shape = appState.cameraMirrorShape
        return NSSize(
            width: clamp(width, min: shape.minSize.width, max: shape.maxSize.width),
            height: clamp(height, min: shape.minSize.height, max: shape.maxSize.height)
        )
    }

    private func saveFrame(_ frame: NSRect) {
        let defaults = UserDefaults.standard
        defaults.set(Double(frame.origin.x), forKey: Self.originXKey)
        defaults.set(Double(frame.origin.y), forKey: Self.originYKey)

        guard let shape = appState?.cameraMirrorShape else { return }
        switch shape {
        case .rectangle:
            defaults.set(Double(frame.size.width), forKey: Self.widthKey)
            defaults.set(Double(frame.size.height), forKey: Self.heightKey)
        case .circle:
            let side = min(frame.size.width, frame.size.height)
            defaults.set(Double(side), forKey: Self.circleSizeKey)
        }
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(maxValue, Swift.max(minValue, value))
    }

    func windowWillClose(_ notification: Notification) {
        Task { @MainActor in
            await CameraMirrorService.shared.stopAndWait()
        }
        appState?.cameraMirrorVisible = false
        panel = nil
        hostingView = nil
        prompterAttachment = .none
    }

    func windowDidMove(_ notification: Notification) {
        guard let panel = notification.object as? NSWindow, !isApplyingSnap else { return }

        var frame = panel.frame
        if let prompterFrame = PrompterWindowController.shared.prompterFrame,
           let (snappedFrame, attachment) = snapFrame(frame, to: prompterFrame) {
            isApplyingSnap = true
            panel.setFrame(snappedFrame, display: true)
            isApplyingSnap = false
            frame = snappedFrame
            prompterAttachment = attachment
        } else if prompterAttachment != .none {
            prompterAttachment = .none
        }

        saveFrame(frame)
    }

    func windowWillStartLiveResize(_ notification: Notification) {
        guard let panel = notification.object as? NSWindow,
              appState?.cameraMirrorShape == .rectangle,
              appState?.cameraMirrorLockAspectRatio == true else { return }
        lockedAspectRatio = panel.frame.width / panel.frame.height
    }

    func windowDidResize(_ notification: Notification) {
        guard let panel = notification.object as? NSWindow, !isApplyingAspectLock else { return }

        isApplyingAspectLock = true
        var frame = panel.frame

        if appState?.cameraMirrorShape == .circle {
            let shape = CameraMirrorShape.circle
            let side = clamp(max(frame.size.width, frame.size.height), min: shape.minSize.width, max: shape.maxSize.width)
            frame.size = NSSize(width: side, height: side)
            if prompterAttachment != .none, let prompterFrame = PrompterWindowController.shared.prompterFrame {
                frame.origin.y = prompterFrame.maxY - side
            } else {
                frame.origin.y = prompterTopY(for: frame.size, fallbackY: frame.origin.y)
            }
        } else if appState?.cameraMirrorLockAspectRatio == true,
                  let ratio = lockedAspectRatio {
            frame.size.height = frame.size.width / ratio
        }

        if prompterAttachment != .none,
           let prompterFrame = PrompterWindowController.shared.prompterFrame {
            let attached = attachedFrame(for: prompterAttachment, prompterFrame: prompterFrame, size: frame.size)
            frame.origin = attached.origin
        }

        if frame != panel.frame {
            panel.setFrame(frame, display: true)
        }
        isApplyingAspectLock = false

        saveFrame(panel.frame)
    }

    func windowDidResignKey(_ notification: Notification) {
        panel?.orderFrontRegardless()
        guard appState?.cameraMirrorCloseWhenUnfocused == true else { return }
        hide()
    }
}
