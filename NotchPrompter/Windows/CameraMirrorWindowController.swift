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
    private var minSizeBeforePolaroidEject: NSSize?
    private var maxSizeBeforePolaroidEject: NSSize?

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
        minSizeBeforePolaroidEject = panel.minSize
        maxSizeBeforePolaroidEject = panel.maxSize
        panel.minSize = NSSize(width: panel.frame.width, height: panel.frame.height)
        panel.maxSize = NSSize(width: 1600, height: 2000)
        var frame = panel.frame
        frame.size.height += extraHeight
        frame.origin.y -= extraHeight
        isApplyingAspectLock = true
        panel.setFrame(frame, display: true)
        isApplyingAspectLock = false
    }

    func endPolaroidEject() {
        guard let panel, let saved = frameBeforePolaroidEject else { return }
        isApplyingAspectLock = true
        panel.setFrame(saved, display: true)
        isApplyingAspectLock = false
        if let minSizeBeforePolaroidEject, let maxSizeBeforePolaroidEject {
            panel.minSize = minSizeBeforePolaroidEject
            panel.maxSize = maxSizeBeforePolaroidEject
        }
        self.minSizeBeforePolaroidEject = nil
        self.maxSizeBeforePolaroidEject = nil
        frameBeforePolaroidEject = nil
    }

    private func endPolaroidEjectOrCollapse() {
        if frameBeforePolaroidEject != nil {
            endPolaroidEject()
            return
        }

        guard let panel else { return }
        let shape = CameraMirrorShape.rectangle
        guard panel.frame.height > shape.defaultSize.height * 1.35 else { return }

        var frame = panel.frame
        let delta = frame.height - shape.defaultSize.height
        frame.size.height = shape.defaultSize.height
        frame.origin.y += delta
        isApplyingAspectLock = true
        panel.setFrame(frame, display: true)
        isApplyingAspectLock = false
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
        endPolaroidEjectOrCollapse()

        if panel == nil {
            createPanel(appState: appState)
        } else if let hostingView {
            hostingView.rootView = CameraMirrorView(appState: appState)
        }
        applySettings(appState: appState)
        syncSizeToPrompterIfNeeded(appState: appState)
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
        appState?.cameraMirrorVisible = false
        panel?.orderOut(nil)
        if let appState {
            resetToDefaultState(appState: appState)
        }
    }

    func resetToDefaultState(appState: AppState) {
        discardPolaroidEjectState()
        setPolaroidEditingActive(false)
        appState.resetCameraMirrorToDefaults()
        clearSavedRectangleDimensions()

        panel = nil
        hostingView = nil
        prompterAttachment = .none
        lockedAspectRatio = nil
    }

    /// Drops polaroid expansion state without resizing the window (used when closing).
    private func discardPolaroidEjectState() {
        if let panel, let minSizeBeforePolaroidEject, let maxSizeBeforePolaroidEject {
            panel.minSize = minSizeBeforePolaroidEject
            panel.maxSize = maxSizeBeforePolaroidEject
        }
        frameBeforePolaroidEject = nil
        minSizeBeforePolaroidEject = nil
        maxSizeBeforePolaroidEject = nil
    }

    private func clearSavedRectangleDimensions() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.widthKey)
        defaults.removeObject(forKey: Self.heightKey)
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
        let rawOrigin = NSPoint(
            x: prompterFrame.maxX,
            y: prompterTopY(for: size)
        )
        let origin = clampedOrigin(rawOrigin, size: size, in: targetScreen(for: appState).visibleFrame)
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

    func syncSizeToPrompterIfNeeded() {
        guard let appState else { return }
        syncSizeToPrompterIfNeeded(appState: appState)
    }

    private func syncSizeToPrompterIfNeeded(appState: AppState) {
        guard appState.cameraMirrorVisible,
              appState.cameraMirrorShape == .rectangle,
              panel != nil else { return }
        applyPrompterMatchedSize(appState: appState)
    }

    func prompterDidMove() {
        guard prompterAttachment != .none,
              let panel,
              let prompterFrame = PrompterWindowController.shared.prompterFrame else { return }

        let size: NSSize
        if appState?.cameraMirrorShape == .rectangle {
            size = prompterMatchedRectangleSize(prompterHeight: prompterFrame.height)
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

        let clamped = clampedOrigin(origin, size: size, in: targetScreen(for: appState).visibleFrame)
        panel.setFrame(NSRect(origin: clamped, size: size), display: true)

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

        let clamped = clampedOrigin(origin, size: size, in: targetScreen(for: appState).visibleFrame)
        return NSRect(origin: clamped, size: size)
    }

    private func resolvedSize(for appState: AppState, panel: NSWindow?) -> NSSize {
        if appState.cameraMirrorShape.isCircle, let panel {
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
        case .bigCircle:
            let side = UserDefaults.standard.object(forKey: Self.circleSizeKey) as? Double
                ?? Double(appState.cameraMirrorShape.defaultSize.width)
            let clamped = clamp(
                CGFloat(side),
                min: appState.cameraMirrorShape.minSize.width,
                max: appState.cameraMirrorShape.maxSize.width
            )
            return NSSize(width: clamped, height: clamped)
        case .smallCircle:
            return appState.cameraMirrorShape.defaultSize
        }
    }

    private func applyPrompterMatchedSize(appState: AppState) {
        guard appState.cameraMirrorShape == .rectangle,
              let panel else { return }

        let prompterHeight: CGFloat
        if PrompterWindowController.shared.isPrompterVisible,
           let prompterFrame = PrompterWindowController.shared.prompterFrame {
            prompterHeight = prompterFrame.height
        } else {
            prompterHeight = PrompterWindowController.shared.referencePrompterHeight(
                for: targetScreen(for: appState)
            )
        }

        let size = prompterMatchedRectangleSize(prompterHeight: prompterHeight)
        var frame = panel.frame
        frame.size = size
        frame.origin.y = prompterTopY(for: size, fallbackY: frame.origin.y)
        panel.setFrame(frame, display: true)
        saveFrame(frame)
    }

    private func prompterMatchedRectangleSize(prompterHeight: CGFloat) -> NSSize {
        let shape = CameraMirrorShape.rectangle
        let height = clamp(prompterHeight, min: shape.minSize.height, max: shape.maxSize.height)
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
        let shape = CameraMirrorShape.rectangle
        let defaults = UserDefaults.standard
        let hasSavedSize = defaults.object(forKey: Self.widthKey) != nil
            || defaults.object(forKey: Self.heightKey) != nil
        let referenceHeight = PrompterWindowController.shared.referencePrompterHeight(
            for: targetScreen(for: appState)
        )

        if PrompterWindowController.shared.isPrompterVisible,
           let prompterFrame = PrompterWindowController.shared.prompterFrame {
            return prompterMatchedRectangleSize(prompterHeight: prompterFrame.height)
        }

        if !hasSavedSize {
            return prompterMatchedRectangleSize(prompterHeight: referenceHeight)
        }

        let defaultSize = shape.defaultSize
        let width = CGFloat(defaults.object(forKey: Self.widthKey) as? Double ?? Double(defaultSize.width))
        let rawHeight = CGFloat(defaults.object(forKey: Self.heightKey) as? Double ?? Double(defaultSize.height))
        // Heights saved while a Polaroid was open are taller than a normal rectangle.
        let height = rawHeight > shape.defaultSize.height * 1.35 ? shape.defaultSize.height : rawHeight

        // Legacy/default camera height (240pt) — use prompter height instead.
        if height <= shape.defaultSize.height * 1.1 {
            return prompterMatchedRectangleSize(prompterHeight: referenceHeight)
        }

        return NSSize(
            width: clamp(width, min: shape.minSize.width, max: shape.maxSize.width),
            height: clamp(height, min: shape.minSize.height, max: shape.maxSize.height)
        )
    }

    private func saveFrame(_ frame: NSRect) {
        guard frameBeforePolaroidEject == nil else { return }

        let defaults = UserDefaults.standard
        defaults.set(Double(frame.origin.x), forKey: Self.originXKey)
        defaults.set(Double(frame.origin.y), forKey: Self.originYKey)

        guard let shape = appState?.cameraMirrorShape else { return }
        switch shape {
        case .rectangle:
            defaults.set(Double(frame.size.width), forKey: Self.widthKey)
            defaults.set(Double(frame.size.height), forKey: Self.heightKey)
        case .bigCircle:
            let side = min(frame.size.width, frame.size.height)
            defaults.set(Double(side), forKey: Self.circleSizeKey)
        case .smallCircle:
            break
        }
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(maxValue, Swift.max(minValue, value))
    }

    private func clampedOrigin(_ origin: NSPoint, size: NSSize, in visibleFrame: NSRect) -> NSPoint {
        let x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - size.width)
        let y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - size.height)
        return NSPoint(x: x, y: y)
    }

    func windowWillClose(_ notification: Notification) {
        if let appState {
            resetToDefaultState(appState: appState)
        }
        Task { @MainActor in
            await CameraMirrorService.shared.stopAndWait()
        }
        appState?.cameraMirrorVisible = false
        panel = nil
        hostingView = nil
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

        if appState?.cameraMirrorShape.isCircle == true,
           frameBeforePolaroidEject == nil,
           let shape = appState?.cameraMirrorShape {
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
