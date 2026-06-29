import AppKit

enum CameraMirrorShape: String, CaseIterable, Identifiable {
    case rectangle
    case circle

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        }
    }

    var systemImage: String {
        switch self {
        case .rectangle: return "rectangle"
        case .circle: return "circle.fill"
        }
    }

    var toggled: CameraMirrorShape {
        switch self {
        case .rectangle: return .circle
        case .circle: return .rectangle
        }
    }

    var defaultSize: NSSize {
        switch self {
        case .rectangle: return NSSize(width: 320, height: 240)
        case .circle: return NSSize(width: 320, height: 320)
        }
    }

    var isResizable: Bool { true }

    var minSize: NSSize {
        switch self {
        case .rectangle: return NSSize(width: 160, height: 120)
        case .circle: return NSSize(width: 200, height: 200)
        }
    }

    var maxSize: NSSize {
        switch self {
        case .rectangle: return NSSize(width: 1200, height: 900)
        case .circle: return NSSize(width: 600, height: 600)
        }
    }

    var keepsSquareAspect: Bool { self == .circle }
}
