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

    var body: some View {
        GeometryReader { geo in
            let cardWidth = PolaroidLayout.cardWidth(for: geo.size.width)
            let slotHeight = polaroidCapture != nil
                ? PolaroidLayout.slotHeight(for: cardWidth)
                : 0
            let videoSize = CGSize(width: geo.size.width, height: max(120, geo.size.height - slotHeight))

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

                    Color.clear
                        .frame(height: slotHeight)
                }

                if polaroidCapture != nil {
                    PolaroidDragBlockingHost {
                        PolaroidEjectStack(
                            capture: Binding(
                                get: {
                                    polaroidCapture ?? PolaroidCaptureState(
                                        photo: NSImage(),
                                        cardWidth: cardWidth,
                                        caption: ""
                                    )
                                },
                                set: { polaroidCapture = $0 }
                            ),
                            onCancel: cancelPolaroid,
                            onSave: savePolaroid
                        )
                    }
                    .frame(width: geo.size.width)
                    .padding(.top, videoSize.height - 12)
                    .zIndex(2)
                }

                VStack(spacing: 0) {
                    controlBar
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

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
        .task {
            cameraService.start()
            reactionMonitor.bind(to: cameraService)
            reactionMonitor.start()
        }
        .onDisappear {
            reactionMonitor.stop()
            CameraMirrorWindowController.shared.setPolaroidEditingActive(false)
            Task { await cameraService.stopAndWait() }
        }
        .onChange(of: polaroidCapture != nil) { _, isEditing in
            CameraMirrorWindowController.shared.setPolaroidEditingActive(isEditing)
        }
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
        case .circle:
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
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.caption.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .background(.black.opacity(0.55), in: Circle())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .help("Take Polaroid photo")
            .disabled(!cameraService.isRunning || isPolaroidFlowActive)

            CameraReactionsMenu(reactionMonitor: reactionMonitor)

            Button {
                appState.toggleCameraMirrorFlip()
            } label: {
                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    .font(.caption.weight(.semibold))
                    .frame(width: 28, height: 28)
                    .background(.black.opacity(0.55), in: Circle())
                    .foregroundStyle(appState.cameraMirrorFlippedHorizontally ? Color.white : Color.white.opacity(0.55))
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
            .padding(.vertical, 6)
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
                caption: PolaroidComposer.defaultCaption()
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
            photoWidth: capture.cardWidth,
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

private struct CameraReactionsMenu: View {
    @ObservedObject var reactionMonitor: CameraReactionMonitor

    var body: some View {
        Menu {
            if reactionMonitor.canPerformReactions {
                Text(reactionMonitor.gesturesEnabled ? "Gestures: On" : "Gestures: Off (Control Center)")
                    .font(.caption)
                Divider()
                reactionButton("Thumbs Up", type: .thumbsUp)
                reactionButton("Thumbs Down", type: .thumbsDown)
                reactionButton("Balloons", type: .balloons)
                reactionButton("Hearts", type: .heart)
                reactionButton("Fireworks", type: .fireworks)
                reactionButton("Confetti", type: .confetti)
                reactionButton("Rain", type: .rain)
                reactionButton("Lasers", type: .lasers)
            } else {
                Text("Reactions unavailable on this camera")
            }
        } label: {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.55), in: Circle())
                .foregroundStyle(reactionMonitor.gesturesEnabled ? Color.yellow : Color.white.opacity(0.55))
        }
        .menuStyle(.borderlessButton)
        .help("FaceTime reactions — hold gestures away from your face")
    }

    private func reactionButton(_ title: String, type: AVCaptureReactionType) -> some View {
        Button(title) {
            reactionMonitor.trigger(type)
        }
    }
}

private struct CameraMirrorShapeSwitch: View {
    let shape: CameraMirrorShape
    let onSelect: (CameraMirrorShape) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segment(for: .rectangle, systemImage: "rectangle")
            segment(for: .circle, systemImage: "circle")
        }
        .padding(3)
        .background(.black.opacity(0.55), in: Capsule())
    }

    private func segment(for option: CameraMirrorShape, systemImage: String) -> some View {
        let isSelected = shape == option
        return Button {
            onSelect(option)
        } label: {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .frame(width: 30, height: 24)
                .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.75))
                .background(isSelected ? Color.white : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .help(option.label)
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
