import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum SlideSyncPermission: String, CaseIterable, Identifiable {
    case automation
    case inputMonitoring
    case accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automation: "Automation (Google Chrome)"
        case .inputMonitoring: "Input Monitoring"
        case .accessibility: "Accessibility"
        }
    }

    var explanation: String {
        switch self {
        case .automation:
            "Lets NotchPrompter read your Google Slides tabs to detect presenter mode and slide changes."
        case .inputMonitoring:
            "Lets NotchPrompter follow arrow keys and space while Chrome is focused, so the notch advances with your slides."
        case .accessibility:
            "Lets NotchPrompter read the slide number from the Presenter View window."
        }
    }

    var settingsURL: URL? {
        let id: String
        switch self {
        case .automation:
            id = "Privacy_Automation"
        case .inputMonitoring:
            id = "Privacy_ListenEvent"
        case .accessibility:
            id = "Privacy_Accessibility"
        }
        return URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(id)")
    }
}

struct SlideSyncPermissionStatus: Equatable {
    let permission: SlideSyncPermission
    let granted: Bool
    let detail: String
}

@MainActor
enum SlideSyncPermissions {
    private static let lastPromptKey = "slideSyncPermissionsLastPrompt"
    private static let promptCooldown: TimeInterval = 300

    static func statuses() -> [SlideSyncPermissionStatus] {
        SlideSyncPermission.allCases.map { status(for: $0) }
    }

    static func missingPermissions() -> [SlideSyncPermission] {
        requiredMissingPermissions()
    }

    static func requiredMissingPermissions() -> [SlideSyncPermission] {
        status(for: .automation).granted ? [] : [.automation]
    }

    static func allGranted() -> Bool {
        requiredMissingPermissions().isEmpty
    }

    static func isAccessibilityAvailable() -> Bool {
        status(for: .accessibility).granted
    }

    static func status(for permission: SlideSyncPermission) -> SlideSyncPermissionStatus {
        switch permission {
        case .automation:
            let granted = isAutomationGranted()
            return SlideSyncPermissionStatus(
                permission: permission,
                granted: granted,
                detail: granted ? "Chrome automation allowed" : "Allow NotchPrompter to control Google Chrome"
            )
        case .inputMonitoring:
            let granted = hasInputMonitoringAccess()
            return SlideSyncPermissionStatus(
                permission: permission,
                granted: granted,
                detail: granted ? "Keyboard sync enabled" : "Required for arrow-key slide sync in Chrome"
            )
        case .accessibility:
            let trusted = AXIsProcessTrusted()
            let functional = PresenterAccessibilityReader.canProbeChrome()
            let granted = trusted || functional
            let detail: String
            if granted {
                detail = "Presenter View slide reading enabled"
            } else if trusted == false, functional == false {
                detail = "Optional — quit & reopen NotchPrompter after enabling in Accessibility, or use arrow keys to sync"
            } else {
                detail = "Optional — improves Presenter View slide detection"
            }
            return SlideSyncPermissionStatus(
                permission: permission,
                granted: granted,
                detail: detail
            )
        }
    }

    /// Checks permissions and prompts for any that are missing. Returns whether all are granted afterward.
    @discardableResult
    static func ensureGranted(promptIfMissing: Bool = true, forcePrompt: Bool = false) -> Bool {
        let missing = missingPermissions()
        guard !missing.isEmpty else { return true }
        guard promptIfMissing else { return false }

        if !forcePrompt, recentlyPrompted() { return false }

        prompt(for: missing)
        recordPrompt()
        return allGranted()
    }

    /// Always shows the permission prompt for anything still missing, ignoring the cooldown.
    @discardableResult
    static func promptNow() -> Bool {
        ensureGranted(promptIfMissing: true, forcePrompt: true)
    }

    static func request(_ permission: SlideSyncPermission) {
        switch permission {
        case .automation:
            openSettings(for: permission)
        case .inputMonitoring:
            _ = CGRequestListenEventAccess()
            if !hasInputMonitoringAccess() {
                openSettings(for: permission)
            }
        case .accessibility:
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            if !AXIsProcessTrusted() {
                openSettings(for: permission)
            }
        }
    }

    static func openSettings(for permission: SlideSyncPermission) {
        guard let url = permission.settingsURL else { return }
        NSWorkspace.shared.open(url)
    }

    static func syncStatusMessage() -> String? {
        let missing = requiredMissingPermissions()
        guard !missing.isEmpty else { return nil }

        if missing.count == 1, let only = missing.first {
            return "Slide sync needs \(only.title): \(only.explanation)"
        }
        let names = missing.map(\.title).joined(separator: ", ")
        return "Slide sync needs permissions: \(names). Open Settings → Privacy & Security."
    }

    static func runningAppPath() -> String {
        Bundle.main.bundlePath
    }

    // MARK: - Private

    private static func isAutomationGranted() -> Bool {
        let runningBrowsers = NSWorkspace.shared.runningApplications
            .compactMap(\.bundleIdentifier)
            .filter { BrowserURLReader.browserBundleIDs.contains($0) }

        guard !runningBrowsers.isEmpty else {
            // Chrome may not be open yet; probe with a lightweight AppleScript anyway.
            return probeAutomation(appName: "Google Chrome")
        }

        for bundleID in runningBrowsers {
            let appName = browserAppName(for: bundleID)
            if probeAutomation(appName: appName) { return true }
        }
        return false
    }

    private static func browserAppName(for bundleID: String) -> String {
        switch bundleID {
        case "com.google.Chrome": "Google Chrome"
        case "com.apple.Safari": "Safari"
        case "com.microsoft.edgemac": "Microsoft Edge"
        case "com.brave.Browser": "Brave Browser"
        case "company.thebrowser.Browser": "Arc"
        default: "Google Chrome"
        }
    }

    private static func probeAutomation(appName: String) -> Bool {
        let script = """
        tell application "\(appName)"
            return (count of windows) >= 0
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return false }
        var error: NSDictionary?
        _ = appleScript.executeAndReturnError(&error)
        guard let error else { return true }

        let code = error["NSAppleScriptErrorNumber"] as? Int ?? 0
        // -1743: not authorized to send Apple events; -600: app not running (not a denial)
        if code == -1743 { return false }
        if code == -600 { return true }
        return false
    }

    private static func hasInputMonitoringAccess() -> Bool {
        CGPreflightListenEventAccess()
    }

    private static func recentlyPrompted() -> Bool {
        guard let last = UserDefaults.standard.object(forKey: lastPromptKey) as? Date else { return false }
        return Date().timeIntervalSince(last) < promptCooldown
    }

    private static func recordPrompt() {
        UserDefaults.standard.set(Date(), forKey: lastPromptKey)
    }

    private static func prompt(for missing: [SlideSyncPermission]) {
        let required = missing.filter { $0 != .accessibility }
        let toPrompt = required.isEmpty ? missing : required
        guard !toPrompt.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "Permissions needed for Google Slides sync"
        alert.informativeText = toPrompt
            .map { "• \($0.title): \($0.explanation)" }
            .joined(separator: "\n\n")
            + "\n\nRunning from:\n\(runningAppPath())"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Grant Permissions")
        alert.addButton(withTitle: "Not Now")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        for permission in toPrompt {
            request(permission)
        }
    }
}
