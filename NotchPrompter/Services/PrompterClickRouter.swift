import AppKit
import Foundation

/// Routes mouse clicks from the prompter panel into SwiftUI when hosting-view hit testing fails.
@MainActor
final class PrompterClickRouter {
    static let shared = PrompterClickRouter()

    weak var textAreaView: NSView?
    weak var interactionState: PrompterInteractionState?

    private init() {}

    func handleClick(at location: CGPoint) {
        interactionState?.handleClick(at: location)
    }

    func clear() {
        textAreaView = nil
        interactionState = nil
    }
}
