import Foundation
import QuartzCore

@MainActor
final class ScrollEngine: ObservableObject {
    @Published private(set) var offset: CGFloat = 0
    @Published private(set) var countdown: Int?
    @Published private(set) var isScrolling = false

    private var ticker: Timer?
    private var lastFrameTime: CFTimeInterval = 0
    private var contentHeight: CGFloat = 0
    private var viewportHeight: CGFloat = 0
    private var pixelsPerSecond: CGFloat = 60
    private var voiceActive = false
    private var paused = false
    private var voiceEnabled = true
    private var lineByVoiceMode = false

    private var targetOffset: CGFloat = 0
    private var displayOffset: CGFloat = 0
    private var offsetAnimation: OffsetAnimation?

    private let lineScrollDuration: CFTimeInterval = 0.45
    private let frameInterval: CFTimeInterval = 1.0 / 120.0

    private struct OffsetAnimation {
        let from: CGFloat
        let to: CGFloat
        let start: CFTimeInterval
        let duration: CFTimeInterval
    }

    func configure(speed: Double, voiceEnabled: Bool) {
        pixelsPerSecond = CGFloat(speed)
        self.voiceEnabled = voiceEnabled
        lineByVoiceMode = voiceEnabled
        if voiceEnabled {
            voiceActive = false
        } else {
            voiceActive = true
        }
    }

    func setContentHeight(_ height: CGFloat, viewport: CGFloat) {
        contentHeight = height
        viewportHeight = viewport
        let clamped = clampOffset(targetOffset)
        targetOffset = clamped
        if offsetAnimation == nil {
            displayOffset = clamped
            if offset != displayOffset {
                offset = displayOffset
            }
        }
    }

    func setVoiceActive(_ active: Bool) {
        voiceActive = active
    }

    func setPaused(_ value: Bool) {
        paused = value
    }

    func scrollToLine(_ line: PrompterLine, animated: Bool = true) {
        setOffset(PrompterLineLayout.scrollOffset(for: line, viewportHeight: viewportHeight), animated: animated)
    }

    func reset() {
        cancelAnimation()
        targetOffset = 0
        displayOffset = 0
        offset = 0
    }

    func setOffset(_ value: CGFloat, animated: Bool = false) {
        let clamped = clampOffset(value)
        targetOffset = clamped
        if animated {
            startAnimation(to: clamped, duration: lineScrollDuration)
        } else {
            cancelAnimation()
            displayOffset = clamped
            offset = clamped
        }
    }

    func adjustOffset(by delta: CGFloat) {
        cancelAnimation()
        let clamped = clampOffset(targetOffset + delta)
        targetOffset = clamped
        displayOffset = clamped
        offset = clamped
    }

    func startCountdown(seconds: Int, completion: @escaping () -> Void) {
        guard seconds > 0 else {
            completion()
            start()
            return
        }
        countdown = seconds
        Task {
            for remaining in stride(from: seconds, through: 1, by: -1) {
                countdown = remaining
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            countdown = nil
            completion()
            start()
        }
    }

    func start() {
        guard ticker == nil else {
            isScrolling = true
            return
        }
        isScrolling = true
        lastFrameTime = CACurrentMediaTime()
        let timer = Timer(timeInterval: frameInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.frame()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func stop() {
        isScrolling = false
        ticker?.invalidate()
        ticker = nil
    }

    private func frame() {
        let now = CACurrentMediaTime()
        let delta = min(0.05, max(0, now - lastFrameTime))
        lastFrameTime = now

        if let animation = offsetAnimation {
            applyAnimation(animation, at: now)
        } else if shouldAutoScroll {
            targetOffset = clampOffset(targetOffset + pixelsPerSecond * CGFloat(delta))
            displayOffset = targetOffset
        }

        offset = displayOffset

        if shouldAutoScroll, displayOffset >= maxScrollOffset(), maxScrollOffset() > 0 {
            stop()
        }
    }

    private var shouldAutoScroll: Bool {
        isScrolling && !paused && !lineByVoiceMode && (!voiceEnabled || voiceActive)
    }

    private func applyAnimation(_ animation: OffsetAnimation, at now: CFTimeInterval) {
        let progress = min(1, max(0, (now - animation.start) / animation.duration))
        let eased = easeOutCubic(progress)
        displayOffset = animation.from + (animation.to - animation.from) * eased
        if progress >= 1 {
            displayOffset = animation.to
            offsetAnimation = nil
        }
    }

    private func startAnimation(to value: CGFloat, duration: CFTimeInterval) {
        offsetAnimation = OffsetAnimation(
            from: displayOffset,
            to: value,
            start: CACurrentMediaTime(),
            duration: duration
        )
        targetOffset = value
    }

    private func cancelAnimation() {
        offsetAnimation = nil
    }

    private func maxScrollOffset() -> CGFloat {
        max(0, contentHeight - viewportHeight)
    }

    private func clampOffset(_ value: CGFloat) -> CGFloat {
        min(maxScrollOffset(), max(0, value))
    }

    private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        let u = 1 - t
        return 1 - u * u * u
    }
}
