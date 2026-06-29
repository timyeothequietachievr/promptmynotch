import AVFoundation
import Combine
import Foundation

@MainActor
final class CameraReactionMonitor: ObservableObject {
    @Published private(set) var gesturesEnabled = false
    @Published private(set) var canPerformReactions = false
    @Published private(set) var activeReactionLabel: String?
    @Published private(set) var activeReactionSystemImage: String?

    private var pollTask: Task<Void, Never>?
    private weak var deviceProvider: CameraMirrorService?

    func bind(to service: CameraMirrorService) {
        deviceProvider = service
    }

    func start() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                refresh()
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        gesturesEnabled = false
        canPerformReactions = false
        activeReactionLabel = nil
        activeReactionSystemImage = nil
    }

    func trigger(_ type: AVCaptureReactionType) {
        guard let device = deviceProvider?.activeCaptureDevice,
              device.canPerformReactionEffects else { return }
        device.performEffect(for: type)
    }

    private func refresh() {
        gesturesEnabled = AVCaptureDevice.reactionEffectGesturesEnabled

        guard let device = deviceProvider?.activeCaptureDevice else {
            canPerformReactions = false
            activeReactionLabel = nil
            activeReactionSystemImage = nil
            return
        }

        canPerformReactions = device.canPerformReactionEffects

        if let active = device.reactionEffectsInProgress.last {
            activeReactionLabel = label(for: active.reactionType)
            activeReactionSystemImage = active.reactionType.systemImageName
        } else {
            activeReactionLabel = nil
            activeReactionSystemImage = nil
        }
    }

    private func label(for type: AVCaptureReactionType) -> String {
        if type == AVCaptureReactionType.thumbsUp { return "Thumbs Up" }
        if type == AVCaptureReactionType.thumbsDown { return "Thumbs Down" }
        if type == AVCaptureReactionType.balloons { return "Balloons" }
        if type == AVCaptureReactionType.heart { return "Hearts" }
        if type == AVCaptureReactionType.fireworks { return "Fireworks" }
        if type == AVCaptureReactionType.rain { return "Rain" }
        if type == AVCaptureReactionType.confetti { return "Confetti" }
        if type == AVCaptureReactionType.lasers { return "Lasers" }
        return "Reaction"
    }
}
