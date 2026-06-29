import AVFoundation
import Combine
import Foundation

struct CameraReactionOption: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let type: AVCaptureReactionType

    static let all: [CameraReactionOption] = [
        CameraReactionOption(id: "thumbsUp", title: "Thumbs Up", systemImage: "hand.thumbsup.fill", type: .thumbsUp),
        CameraReactionOption(id: "thumbsDown", title: "Thumbs Down", systemImage: "hand.thumbsdown.fill", type: .thumbsDown),
        CameraReactionOption(id: "balloons", title: "Balloons", systemImage: "balloon.2.fill", type: .balloons),
        CameraReactionOption(id: "heart", title: "Hearts", systemImage: "heart.fill", type: .heart),
        CameraReactionOption(id: "fireworks", title: "Fireworks", systemImage: "fireworks", type: .fireworks),
        CameraReactionOption(id: "confetti", title: "Confetti", systemImage: "party.popper.fill", type: .confetti),
        CameraReactionOption(id: "rain", title: "Rain", systemImage: "cloud.rain.fill", type: .rain),
        CameraReactionOption(id: "lasers", title: "Lasers", systemImage: "bolt.fill", type: .lasers),
    ]

    static func option(for type: AVCaptureReactionType) -> CameraReactionOption? {
        all.first { $0.type == type }
    }

    static func option(id: String) -> CameraReactionOption? {
        all.first { $0.id == id }
    }
}

@MainActor
final class CameraReactionMonitor: ObservableObject {
    @Published private(set) var gesturesEnabled = false
    @Published private(set) var canPerformReactions = false
    @Published private(set) var activeReactionLabel: String?
    @Published private(set) var activeReactionSystemImage: String?
    @Published private(set) var lastUsedReaction: CameraReactionOption?

    private var pollTask: Task<Void, Never>?
    private weak var deviceProvider: CameraMirrorService?

    private static let lastReactionKey = "camera_mirror_last_reaction"

    init() {
        if let storedID = UserDefaults.standard.string(forKey: Self.lastReactionKey) {
            lastUsedReaction = CameraReactionOption.option(id: storedID)
        }
    }

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
        rememberLastUsed(type)
    }

    func retriggerLast() {
        guard let lastUsedReaction else { return }
        trigger(lastUsedReaction.type)
    }

    private func rememberLastUsed(_ type: AVCaptureReactionType) {
        guard let option = CameraReactionOption.option(for: type) else { return }
        lastUsedReaction = option
        UserDefaults.standard.set(option.id, forKey: Self.lastReactionKey)
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
            activeReactionLabel = CameraReactionOption.option(for: active.reactionType)?.title ?? "Reaction"
            activeReactionSystemImage = active.reactionType.systemImageName
        } else {
            activeReactionLabel = nil
            activeReactionSystemImage = nil
        }
    }
}
