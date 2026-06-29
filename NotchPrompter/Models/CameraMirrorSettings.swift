import AppKit

enum CameraMirrorWindowType: String, CaseIterable, Identifiable {
    case smartWindow
    case popover

    var id: String { rawValue }

    var label: String {
        switch self {
        case .smartWindow: return "Smart Window"
        case .popover: return "Popover"
        }
    }

    var systemImage: String {
        switch self {
        case .smartWindow: return "macwindow"
        case .popover: return "rectangle"
        }
    }
}

enum CameraMirrorSnapPosition: String, CaseIterable, Identifiable {
    case topLeft
    case topCenter
    case topRight
    case middleLeft
    case center
    case middleRight
    case bottomLeft
    case bottomCenter
    case bottomRight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .topLeft: return "Top left"
        case .topCenter: return "Top center"
        case .topRight: return "Top right"
        case .middleLeft: return "Middle left"
        case .center: return "Center"
        case .middleRight: return "Middle right"
        case .bottomLeft: return "Bottom left"
        case .bottomCenter: return "Bottom center"
        case .bottomRight: return "Bottom right"
        }
    }

    static let gridRows: [[CameraMirrorSnapPosition]] = [
        [.topLeft, .topCenter, .topRight],
        [.middleLeft, .center, .middleRight],
        [.bottomLeft, .bottomCenter, .bottomRight],
    ]

    func origin(for size: NSSize, in visibleFrame: NSRect, margin: CGFloat = 24) -> NSPoint {
        let x: CGFloat
        let y: CGFloat

        switch self {
        case .topLeft, .middleLeft, .bottomLeft:
            x = visibleFrame.minX + margin
        case .topCenter, .center, .bottomCenter:
            x = visibleFrame.midX - size.width / 2
        case .topRight, .middleRight, .bottomRight:
            x = visibleFrame.maxX - size.width - margin
        }

        switch self {
        case .topLeft, .topCenter, .topRight:
            y = visibleFrame.maxY - size.height - margin
        case .middleLeft, .center, .middleRight:
            y = visibleFrame.midY - size.height / 2
        case .bottomLeft, .bottomCenter, .bottomRight:
            y = visibleFrame.minY + margin
        }

        return NSPoint(x: x, y: y)
    }
}

extension NSScreen {
    var displayIdentifier: String {
        if let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            return "display_\(screenNumber.uint32Value)"
        }
        return localizedName
    }

    static func screen(forDisplayIdentifier identifier: String?) -> NSScreen? {
        guard let identifier else { return NSScreen.main }
        return NSScreen.screens.first { $0.displayIdentifier == identifier } ?? NSScreen.main
    }
}
