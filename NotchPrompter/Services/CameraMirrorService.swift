import AVFoundation
import AppKit
import Combine
import Foundation

struct CameraDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let position: AVCaptureDevice.Position
}

/// Owns the AVCaptureSession and performs all session mutations on one serial queue.
final class CameraSessionWorker: @unchecked Sendable {
    let session = AVCaptureSession()
    let frameCapture = CameraFrameCapture()
    private let queue = DispatchQueue(label: "com.notchprompter.camera.session")
    private let frameQueue = DispatchQueue(label: "com.notchprompter.camera.frames")
    private var hasVideoOutput = false

    func stop() async {
        await withCheckedContinuation { continuation in
            queue.async { [session] in
                if session.isRunning {
                    session.stopRunning()
                }
                continuation.resume()
            }
        }
    }

    func configureAndStart(device: AVCaptureDevice) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            queue.async { [session] in
                if session.isRunning {
                    session.stopRunning()
                }

                session.beginConfiguration()

                for input in session.inputs {
                    session.removeInput(input)
                }

                let result: Result<Void, Error>
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    guard session.canAddInput(input) else {
                        session.commitConfiguration()
                        continuation.resume(returning: .failure(CameraSessionError.unableToAddInput))
                        return
                    }
                    session.addInput(input)

                    if !self.hasVideoOutput {
                        let output = AVCaptureVideoDataOutput()
                        output.videoSettings = [
                            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                        ]
                        output.alwaysDiscardsLateVideoFrames = true
                        output.setSampleBufferDelegate(self.frameCapture, queue: self.frameQueue)
                        if session.canAddOutput(output) {
                            session.addOutput(output)
                            self.hasVideoOutput = true
                        }
                    }

                    result = .success(())
                } catch {
                    session.commitConfiguration()
                    continuation.resume(returning: .failure(error))
                    return
                }

                session.commitConfiguration()

                if !session.isRunning {
                    session.startRunning()
                }

                continuation.resume(returning: result)
            }
        }
    }
}

enum CameraSessionError: LocalizedError {
    case unableToAddInput

    var errorDescription: String? {
        switch self {
        case .unableToAddInput: return "Unable to use this camera."
        }
    }
}

@MainActor
final class CameraMirrorService: ObservableObject {
    static let shared = CameraMirrorService()

    @Published private(set) var devices: [CameraDevice] = []
    @Published var selectedDeviceID: String?
    @Published private(set) var isRunning = false
    @Published private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var errorMessage: String?

    private let worker = CameraSessionWorker()
    private var startTask: Task<Void, Never>?

    var session: AVCaptureSession { worker.session }

    var activeCaptureDevice: AVCaptureDevice? {
        guard let selectedDeviceID else { return nil }
        return AVCaptureDevice(uniqueID: selectedDeviceID)
    }

    private init() {
        selectedDeviceID = UserDefaults.standard.string(forKey: Self.selectedCameraKey)
    }

    func refreshDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .external],
            mediaType: .video,
            position: .unspecified
        )
        devices = discovery.devices.map {
            CameraDevice(id: $0.uniqueID, name: $0.localizedName, position: $0.position)
        }
        if selectedDeviceID == nil || !devices.contains(where: { $0.id == selectedDeviceID }) {
            selectedDeviceID = devices.first?.id
        }
    }

    func requestAccessIfNeeded() async -> Bool {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authorizationStatus {
        case .authorized:
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            return granted
        default:
            return false
        }
    }

    func start() {
        startTask?.cancel()
        startTask = Task { await startSession() }
    }

    func stop() {
        startTask?.cancel()
        startTask = Task { await stopAndWait() }
    }

    func stopAndWait() async {
        startTask?.cancel()
        startTask = nil
        await worker.stop()
        isRunning = false
    }

    func selectDevice(_ deviceID: String) {
        guard deviceID != selectedDeviceID else { return }
        selectedDeviceID = deviceID
        UserDefaults.standard.set(deviceID, forKey: Self.selectedCameraKey)

        guard isRunning, let device = AVCaptureDevice(uniqueID: deviceID) else { return }

        Task { await applyDevice(device) }
    }

    private func startSession() async {
        errorMessage = nil
        guard !Task.isCancelled else { return }

        await worker.stop()

        guard await requestAccessIfNeeded() else {
            errorMessage = "Camera access is required. Enable it in System Settings → Privacy & Security → Camera."
            return
        }

        refreshDevices()
        guard let deviceID = selectedDeviceID,
              let device = AVCaptureDevice(uniqueID: deviceID) else {
            errorMessage = devices.isEmpty ? "No camera found." : "Select a camera."
            return
        }

        await applyDevice(device)
    }

    private func applyDevice(_ device: AVCaptureDevice) async {
        guard !Task.isCancelled else { return }

        switch await worker.configureAndStart(device: device) {
        case .failure(let error):
            errorMessage = error.localizedDescription
            isRunning = false
        case .success:
            isRunning = worker.session.isRunning
            if !isRunning {
                errorMessage = "Unable to start camera."
            }
        }
    }

    func captureSnapshot(mirrored: Bool) -> NSImage? {
        worker.frameCapture.makeSnapshot(mirrored: mirrored)
    }

    func composePolaroid(
        from photo: NSImage,
        caption: String,
        capturedAt: Date,
        photoWidth: CGFloat,
        photoIsCircular: Bool = false,
        stickers: [PolaroidSticker] = []
    ) -> NSImage {
        PolaroidComposer.compose(
            from: photo,
            caption: caption,
            capturedAt: capturedAt,
            photoWidth: photoWidth,
            photoIsCircular: photoIsCircular,
            stickers: stickers
        )
    }

    private static let selectedCameraKey = "camera_mirror_device_id"
}
