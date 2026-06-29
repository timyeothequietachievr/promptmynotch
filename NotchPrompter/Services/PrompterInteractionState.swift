import Foundation
import SwiftUI

@MainActor
@Observable
final class PrompterInteractionState {
    var text = ""
    var fontSize: Double = 18
    var containerWidth: CGFloat = 560
    var scrollOffset: CGFloat = 0
    var pulseWordIndex: Int?
    var pulseAmount: CGFloat = 0
    var onToggleWord: ((Int) -> Void)?

    func handleClick(at location: CGPoint) {
        guard let wordIndex = PrompterLineLayout.wordIndex(
            at: location,
            text: text,
            fontSize: fontSize,
            containerWidth: containerWidth,
            scrollOffset: scrollOffset
        ) else {
            return
        }

        pulseWord(at: wordIndex)
        onToggleWord?(wordIndex)
    }

    private func pulseWord(at wordIndex: Int) {
        withAnimation(.easeOut(duration: 0.12)) {
            pulseWordIndex = wordIndex
            pulseAmount = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeOut(duration: 0.5)) {
                pulseAmount = 0
            }
            try? await Task.sleep(for: .milliseconds(520))
            if pulseWordIndex == wordIndex {
                pulseWordIndex = nil
            }
        }
    }
}
