import AppKit
import Foundation

struct InstalledBrowser: Identifiable, Hashable {
    let id: String
    let name: String
    let appURL: URL
    let bundleIdentifier: String?

    init(appURL: URL) {
        self.appURL = appURL
        self.id = appURL.path
        self.name = FileManager.default.displayName(atPath: appURL.path)
            .replacingOccurrences(of: ".app", with: "")
        self.bundleIdentifier = Bundle(url: appURL)?.bundleIdentifier
    }
}

enum BrowserDiscovery {
    private static let preferredBrowserKey = "preferred_oauth_browser_path"

    static var preferredBrowser: InstalledBrowser? {
        guard let path = UserDefaults.standard.string(forKey: preferredBrowserKey) else { return nil }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return InstalledBrowser(appURL: url)
    }

    static func setPreferredBrowser(_ browser: InstalledBrowser) {
        UserDefaults.standard.set(browser.appURL.path, forKey: preferredBrowserKey)
    }

    static func installedBrowsers() -> [InstalledBrowser] {
        guard let probe = URL(string: "https://accounts.google.com") else { return [] }

        let apps = NSWorkspace.shared.urlsForApplications(toOpen: probe)
        var seen = Set<String>()

        return apps
            .map(InstalledBrowser.init(appURL:))
            .filter { browser in
                guard browser.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
                guard !seen.contains(browser.id) else { return false }
                seen.insert(browser.id)
                return true
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @MainActor
    static func open(_ url: URL, in browser: InstalledBrowser) async throws {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        _ = try await NSWorkspace.shared.open([url], withApplicationAt: browser.appURL, configuration: config)
    }
}
