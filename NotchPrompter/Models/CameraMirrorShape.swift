import AppKit

enum CameraMirrorShape: String, CaseIterable, Identifiable {
    case rectangle
    case bigCircle
    case smallCircle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .bigCircle: return "Circle"
        case .smallCircle: return "Smaller Circle"
        }
    }

    var systemImage: String {
        switch self {
        case .rectangle: return "rectangle"
        case .bigCircle: return "circle.fill"
        case .smallCircle: return "smallcircle.filled.circle"
        }
    }

    var toggled: CameraMirrorShape {
        switch self {
        case .rectangle: return .bigCircle
        case .bigCircle: return .smallCircle
        case .smallCircle: return .rectangle
        }
    }

    var defaultSize: NSSize {
        switch self {
        case .rectangle: return NSSize(width: 320, height: 240)
        case .bigCircle: return NSSize(width: 320, height: 320)
        case .smallCircle: return NSSize(width: 320, height: 320)
        }
    }

    /// Placeholder toggle in the camera toolbar — not active yet.
    var isSelectable: Bool {
        switch self {
        case .smallCircle: return false
        default: return true
        }
    }

    var isResizable: Bool { true }

    var minSize: NSSize {
        switch self {
        case .rectangle: return NSSize(width: 160, height: 120)
        case .bigCircle: return NSSize(width: 200, height: 200)
        case .smallCircle: return defaultSize
        }
    }

    var maxSize: NSSize {
        switch self {
        case .rectangle: return NSSize(width: 1200, height: 900)
        case .bigCircle: return NSSize(width: 600, height: 600)
        case .smallCircle: return defaultSize
        }
    }

    var keepsSquareAspect: Bool { self != .rectangle }
    var isCircle: Bool { self != .rectangle }
}
