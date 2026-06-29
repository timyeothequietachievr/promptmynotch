import AVFoundation
import AppKit
import SwiftUI

struct CameraMirrorView: View {
    @ObservedObject var cameraService = CameraMirrorService.shared
    @StateObject private var reactionMonitor = CameraReactionMonitor()
    @Bindable var appState: AppState

    @State private var polaroidCapture: PolaroidCaptureState?
    @State private var showCaptureFlash = false
    @State private var polaroidSaveMessage: String?
    @State private var isPolaroidFlowActive = false
    @State private var isPointerInsideWindow = false

    var body: some View {
        GeometryReader { geo in
            let isCircle = appState.cameraMirrorShape.isCircle
            let polaroidActive = polaroidCapture != nil
            let cardWidth = PolaroidLayout.cardWidth(for: geo.size.width)
            let slotHeight = polaroidActive
                ? PolaroidLayout.slotHeight(for: cardWidth)
                : 0
            let videoSize = CGSize(
                width: geo.size.width,
                height: isCircle
                    ? geo.size.width
                    : max(120, geo.size.height - slotHeight)
            )

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    ZStack {
                        videoLayer(size: videoSize)

                        if showCaptureFlash {
                            Color.white.opacity(0.92)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: videoSize.width, height: videoSize.height)
                    .clipShape(contentClipShape)

                    if isCircle {
                        if polaroidActive {
                            polaroidSection(cardWidth: cardWidth, ejectDirection: .circleTopDown)
                                .frame(width: geo.size.width, height: slotHeight, alignment: .top)
                                .clipped()
                        }
                    } else {
                        Color.clear
                            .frame(height: slotHeight)
                    }
                }

                if !isCircle && polaroidActive {
                    polaroidSection(
                        cardWidth: cardWidth,
                        ejectDirection: .overlayUp
                    )
                    .frame(width: geo.size.width, height: slotHeight, alignment: .top)
                    .padding(.top, videoSize.height - 12)
                    .zIndex(2)
                }

                VStack(spacing: 0) {
                    controlBar
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .opacity(controlsVisible ? 1 : 0)
                        .allowsHitTesting(controlsVisible)

                    if let activeLabel = reactionMonitor.activeReactionLabel {
                        reactionBadge(label: activeLabel, systemImage: reactionMonitor.activeReactionSystemImage)
                            .padding(.top, 8)
                    } else if !reactionMonitor.gesturesEnabled, reactionMonitor.canPerformReactions {
                        Text("Enable gesture reactions in Control Center → Video Effects")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.45), in: Capsule())
                            .padding(.top, 8)
                    }

                    if let polaroidSaveMessage {
                        Text(polaroidSaveMessage)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.55), in: Capsule())
                            .padding(.top, 6)
                    }

                    Spacer(minLength: 0)
                }
                .frame(height: videoSize.height, alignment: .top)
                .zIndex(3)
            }
        }
        .background(Color.clear)
        .animation(.easeOut(duration: 0.12), value: showCaptureFlash)
        .animation(.easeOut(duration: 0.2), value: controlsVisible)
        .task {
            cameraService.start()
            reactionMonitor.bind(to: cameraService)
            reactionMonitor.start()
        }
        .onDisappear {
            reactionMonitor.stop()
            CameraMirrorWindowController.shared.setPolaroidEditingActive(false)
            cameraService.stop()
        }
        .onChange(of: polaroidCapture != nil) { _, isEditing in
            CameraMirrorWindowController.shared.setPolaroidEditingActive(isEditing)
        }
        .onHover { hovering in
            isPointerInsideWindow = hovering
        }
    }

    private var controlsVisible: Bool {
        isPointerInsideWindow || isPolaroidFlowActive
    }

    @ViewBuilder
    private func videoLayer(size: CGSize) -> some View {
        Group {
            if cameraService.authorizationStatus == .authorized, cameraService.isRunning {
                CameraPreviewView(
                    session: cameraService.session,
                    mirrored: appState.cameraMirrorFlippedHorizontally
                )
            } else if let errorMessage = cameraService.errorMessage {
                placeholder(message: errorMessage)
            } else {
                placeholder(message: "Starting camera…")
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var contentClipShape: AnyShape {
        switch appState.cameraMirrorShape {
        case .rectangle:
            AnyShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .bigCircle, .smallCircle:
            AnyShape(Circle())
        }
    }

    private var controlBar: some View {
        HStack(spacing: 8) {
            cameraPicker

            Spacer(minLength: 0)

            Button {
                startPolaroidFlow()
            } label: {
                CaptureCameraIcon()
                    .frame(width: 18, height: 18)
                    .cameraControlCircleIcon()
            }
            .buttonStyle(.plain)
            .help("Take Polaroid photo")
            .disabled(!cameraService.isRunning || isPolaroidFlowActive)

            CameraReactionsPill(reactionMonitor: reactionMonitor)

            Button {
                appState.toggleCameraMirrorFlip()
            } label: {
                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .cameraControlCircleIcon(
                        foreground: appState.cameraMirrorFlippedHorizontally ? .white : Color.white.opacity(0.55)
                    )
            }
            .buttonStyle(.plain)
            .help("Flip horizontally")

            CameraMirrorShapeSwitch(shape: appState.cameraMirrorShape) { shape in
                appState.setCameraMirrorShape(shape)
            }
        }
    }

    private var cameraPicker: some View {
        Menu {
            if cameraService.devices.isEmpty {
                Text("No cameras found")
            } else {
                ForEach(cameraService.devices) { device in
                    Button(device.name) {
                        cameraService.selectDevice(device.id)
                    }
                }
            }
            Divider()
            Button("Refresh cameras") {
                cameraService.refreshDevices()
            }
        } label: {
            Label(
                cameraService.devices.first(where: { $0.id == cameraService.selectedDeviceID })?.name ?? "Camera",
                systemImage: "video.fill"
            )
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .frame(height: CameraControlBarMetrics.height)
            .background(.black.opacity(0.55), in: Capsule())
            .foregroundStyle(.white)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func reactionBadge(label: String, systemImage: String?) -> some View {
        Label(label, systemImage: systemImage ?? "sparkles")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.55), in: Capsule())
            .foregroundStyle(.white)
    }

    private func polaroidSection(cardWidth: CGFloat, ejectDirection: PolaroidEjectDirection) -> some View {
        PolaroidEjectStack(
            capture: Binding(
                get: { polaroidCapture! },
                set: { polaroidCapture = $0 }
            ),
            onCancel: cancelPolaroid,
            onSave: savePolaroid,
            ejectDirection: ejectDirection
        )
    }

    private func startPolaroidFlow() {
        guard !isPolaroidFlowActive else { return }
        isPolaroidFlowActive = true
        polaroidSaveMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            capturePolaroidPhoto()
        }
    }

    private func capturePolaroidPhoto() {
        guard isPolaroidFlowActive else { return }

        withAnimation(.easeOut(duration: 0.08)) {
            showCaptureFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            showCaptureFlash = false

            guard let photo = cameraService.captureSnapshot(
                mirrored: appState.cameraMirrorFlippedHorizontally
            ) else {
                isPolaroidFlowActive = false
                return
            }

            let cardWidth = PolaroidLayout.cardWidth(
                for: CameraMirrorWindowController.shared.panelWidth ?? 320
            )
            let extraHeight = PolaroidLayout.slotHeight(for: cardWidth)
            CameraMirrorWindowController.shared.beginPolaroidEject(extraHeight: extraHeight)
            polaroidCapture = PolaroidCaptureState(
                photo: photo,
                cardWidth: cardWidth,
                capturedAt: Date(),
                photoIsCircular: appState.cameraMirrorShape.isCircle,
                caption: ""
            )
        }
    }

    private func cancelPolaroid() {
        polaroidCapture = nil
        isPolaroidFlowActive = false
        CameraMirrorWindowController.shared.setPolaroidEditingActive(false)
        CameraMirrorWindowController.shared.endPolaroidEject()
    }

    private func savePolaroid() {
        guard let capture = polaroidCapture else { return }
        let composed = cameraService.composePolaroid(
            from: capture.photo,
            caption: capture.caption,
            capturedAt: capture.capturedAt,
            photoWidth: capture.cardWidth,
            photoIsCircular: capture.photoIsCircular,
            stickers: capture.stickers
        )
        do {
            let url = try ScreenshotFolder.savePNG(composed)
            polaroidCapture = nil
            isPolaroidFlowActive = false
            CameraMirrorWindowController.shared.setPolaroidEditingActive(false)
            CameraMirrorWindowController.shared.endPolaroidEject()
            polaroidSaveMessage = "Saved to \(url.lastPathComponent)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                polaroidSaveMessage = nil
            }
        } catch {
            polaroidSaveMessage = error.localizedDescription
        }
    }

    private func placeholder(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.88)
            VStack(spacing: 8) {
                Image(systemName: "video.slash")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

private enum CameraControlBarMetrics {
    static let height: CGFloat = 32
}

private struct CameraReactionsPill: View {
    @ObservedObject var reactionMonitor: CameraReactionMonitor

    private var pillForeground: Color {
        reactionMonitor.gesturesEnabled ? .white : Color.white.opacity(0.55)
    }

    private var mainLabel: String {
        reactionMonitor.lastUsedReaction?.title ?? "Reactions"
    }

    private var mainSystemImage: String {
        reactionMonitor.lastUsedReaction?.systemImage ?? "sparkles"
    }

    var body: some View {
        Group {
            if reactionMonitor.canPerformReactions {
                HStack(spacing: 0) {
                    Button {
                        reactionMonitor.retriggerLast()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: mainSystemImage)
                                .font(.caption.weight(.semibold))
                            Text(mainLabel)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 4)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(reactionMonitor.lastUsedReaction == nil)

                    Rectangle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 1, height: 18)

                    Menu {
                        Text(reactionMonitor.gesturesEnabled ? "Gestures: On" : "Gestures: Off (Control Center)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Divider()
                        ForEach(CameraReactionOption.all) { option in
                            Button {
                                reactionMonitor.trigger(option.type)
                            } label: {
                                Text(option.title)
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 24)
                            .frame(maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .padding(.trailing, 4)
                }
                .frame(height: CameraControlBarMetrics.height)
                .foregroundStyle(pillForeground)
                .background(.black.opacity(0.55), in: Capsule())
                .fixedSize()
                .help(reactionMonitor.lastUsedReaction == nil
                    ? "Choose a reaction from the menu"
                    : "Replay \(mainLabel), or open the menu with the arrow")
            } else {
                Label("Reactions unavailable", systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .frame(height: CameraControlBarMetrics.height)
                    .background(.black.opacity(0.55), in: Capsule())
                    .foregroundStyle(Color.white.opacity(0.45))
                    .fixedSize()
            }
        }
    }
}

private struct CameraMirrorShapeSwitch: View {
    let shape: CameraMirrorShape
    let onSelect: (CameraMirrorShape) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segment(for: .rectangle, systemImage: "rectangle")
            segment(for: .bigCircle, systemImage: "circle")
            segment(for: .smallCircle, systemImage: "smallcircle.filled.circle")
        }
        .padding(2)
        .frame(height: CameraControlBarMetrics.height)
        .background(.black.opacity(0.55), in: Capsule())
    }

    private func segment(for option: CameraMirrorShape, systemImage: String) -> some View {
        let isSelected = shape == option
        return Button {
            guard option.isSelectable else { return }
            onSelect(option)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 34, height: CameraControlBarMetrics.height - 4)
                .foregroundStyle(
                    isSelected ? Color.black : Color.white.opacity(option.isSelectable ? 0.75 : 0.45)
                )
                .background(isSelected ? Color.white : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!option.isSelectable)
        .help(option.isSelectable ? option.label : "\(option.label) (coming soon)")
    }
}

private extension View {
    func cameraControlCircleIcon(foreground: Color = .white) -> some View {
        font(.system(size: 16, weight: .semibold))
            .frame(width: CameraControlBarMetrics.height, height: CameraControlBarMetrics.height)
            .background(.black.opacity(0.55), in: Circle())
            .foregroundStyle(foreground)
    }
}

struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}
