import AppKit
import SwiftUI

/// Prevents window-background drags from stealing clicks meant for SwiftUI controls.
final class PrompterHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }
}
