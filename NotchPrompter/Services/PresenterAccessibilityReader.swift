import AppKit
import ApplicationServices

enum PresenterAccessibilityReader {
    /// Reads the current slide number (1-based) from a Chrome Presenter View window via Accessibility.
    static func currentSlideNumber(inBrowser bundleID: String = "com.google.Chrome") -> Int? {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return nil
        }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        guard let windows = axWindows(axApp) ?? axChildren(axApp) else { return nil }

        for window in windows {
            guard let title = axString(window, kAXTitleAttribute as CFString),
                  title.localizedCaseInsensitiveContains("Presenter view") else { continue }
            if let slide = scanForSlideNumber(in: window) {
                return slide
            }
        }

        // Fallback: scan all Chrome windows for a slide counter.
        for window in windows {
            if let slide = scanForSlideNumber(in: window) {
                return slide
            }
        }
        return nil
    }

    /// True when macOS reports trust, or we can actually read Chrome's UI tree.
    static func canProbeChrome(bundleID: String = "com.google.Chrome") -> Bool {
        if AXIsProcessTrusted() { return true }
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return false
        }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        return axWindows(axApp) != nil
    }

    static var isTrusted: Bool { canProbeChrome() }

    private static func scanForSlideNumber(in element: AXUIElement) -> Int? {
        if let value = axString(element, kAXValueAttribute as CFString),
           let slide = parseSlideNumber(from: value) {
            return slide
        }
        if let title = axString(element, kAXTitleAttribute as CFString),
           let slide = parseSlideNumber(from: title) {
            return slide
        }
        if let desc = axString(element, kAXDescriptionAttribute as CFString),
           let slide = parseSlideNumber(from: desc) {
            return slide
        }

        guard let children = axChildren(element) else { return nil }
        for child in children {
            if let slide = scanForSlideNumber(in: child) {
                return slide
            }
        }
        return nil
    }

    /// Matches "3", "3 / 110", "Slide 3 of 110", etc.
    private static func parseSlideNumber(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let n = Int(trimmed), n > 0 { return n }

        let patterns = [
            #"^(\d+)\s*/"#,
            #"(\d+)\s+of\s+\d+"#,
            #"slide\s*(\d+)"#
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
                  match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: trimmed),
                  let n = Int(trimmed[range]), n > 0 else { continue }
            return n
        }
        return nil
    }

    private static func axWindows(_ element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXWindowsAttribute as CFString, &value)
        guard result == .success else { return nil }
        if let array = value as? [AXUIElement] { return array }
        return nil
    }

    private static func axChildren(_ element: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value)
        guard result == .success, let array = value as? [AXUIElement] else { return nil }
        return array
    }

    private static func axString(_ element: AXUIElement, _ attribute: CFString) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else { return nil }
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }
}
