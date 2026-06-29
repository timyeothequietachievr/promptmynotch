import AppKit
import Foundation

struct GoogleSlidesPresenterSession: Equatable {
    let presentationID: String
    let slideObjectId: String?
    let slideIndex: Int
    let url: String
    let sourceMode: String
}

struct GoogleSlidesLiveState: Equatable {
    let session: GoogleSlidesPresenterSession
    /// True when Presenter View, /present slideshow, or speaker-notes popup is open.
    let inPresenterMode: Bool
}

enum BrowserPresenterPollResult: Equatable {
    case live(GoogleSlidesLiveState)
    case notPresenting
    case unknown
}

enum BrowserURLReader {
    private struct BrowserTarget {
        let bundleID: String
        let appName: String
        let usesChromiumJS: Bool
    }

    private struct BrowserTabProbe {
        let url: String
        let tabTitle: String?
        let slideObjectId: String?
        let slideIndex: Int?
        let presentationId: String?
        let mode: String
        let isActiveTab: Bool
        let isPresenterNotesTab: Bool
        let isAudienceSlideshowTab: Bool
    }

    private static let browsers: [BrowserTarget] = [
        BrowserTarget(bundleID: "com.google.Chrome", appName: "Google Chrome", usesChromiumJS: true),
        BrowserTarget(bundleID: "com.apple.Safari", appName: "Safari", usesChromiumJS: false),
        BrowserTarget(bundleID: "com.microsoft.edgemac", appName: "Microsoft Edge", usesChromiumJS: true),
        BrowserTarget(bundleID: "com.brave.Browser", appName: "Brave Browser", usesChromiumJS: true),
        BrowserTarget(bundleID: "company.thebrowser.Browser", appName: "Arc", usesChromiumJS: true),
    ]

    static let browserBundleIDs: Set<String> = Set(browsers.map(\.bundleID))

    static var lastProbeError: String?

    static func pollPresenterState() async -> BrowserPresenterPollResult {
        await MainActor.run {
            pollPresenterStateSync()
        }
    }

    static func findGoogleSlidesPresenterSession() async -> GoogleSlidesPresenterSession? {
        await MainActor.run {
            currentBrowserSlideSession()
        }
    }

    /// Reads the current slide from any open Google Slides browser tab (edit or present URL).
    static func currentBrowserSlideSession() -> GoogleSlidesPresenterSession? {
        lastProbeError = nil
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        var probes: [BrowserTabProbe] = []

        for browser in browsers where running.contains(browser.bundleID) {
            let browserProbes = browser.usesChromiumJS
                ? probeChromiumBrowser(appName: browser.appName)
                : probeSafari()
            probes.append(contentsOf: browserProbes)
        }

        if probes.isEmpty, lastProbeError != nil { return nil }

        return pickCurrentSlideSession(from: probes)
    }

    static func pollPresenterStateSync() -> BrowserPresenterPollResult {
        if let session = currentBrowserSlideSession() {
            return .live(GoogleSlidesLiveState(
                session: session,
                inPresenterMode: session.sourceMode == "present"
            ))
        }
        if lastProbeError != nil { return .unknown }
        return .notPresenting
    }

    private static func pickCurrentSlideSession(from probes: [BrowserTabProbe]) -> GoogleSlidesPresenterSession? {
        let withSlide = probes.filter { probe in
            probe.presentationId != nil && (probe.slideObjectId != nil || probe.slideIndex != nil)
        }
        guard !withSlide.isEmpty else { return nil }

        let ranked = withSlide.sorted { rank(for: $0) < rank(for: $1) }
        guard let pick = ranked.first else { return nil }

        guard let presentationID = pick.presentationId else { return nil }

        return GoogleSlidesPresenterSession(
            presentationID: presentationID,
            slideObjectId: pick.slideObjectId,
            slideIndex: pick.slideIndex ?? 0,
            url: pick.url,
            sourceMode: pick.isAudienceSlideshowTab ? "present" : pick.mode
        )
    }

    /// Lower rank = higher priority. Audience slideshow wins over edit and presenter notes.
    private static func rank(for probe: BrowserTabProbe) -> Int {
        if probe.isAudienceSlideshowTab { return 0 }
        if probe.mode == "edit" { return 1 }
        if probe.mode == "view" { return 2 }
        if probe.isPresenterNotesTab { return 4 }
        if probe.mode == "present" { return 0 }
        return 3
    }

    private static func isPresenterNotesTab(url: String, tabTitle: String?) -> Bool {
        let lowerURL = url.lowercased()
        if lowerURL.contains("speakernotes") { return true }

        guard let title = tabTitle?.lowercased() else { return false }
        if title.contains("presenter view") { return true }
        if title.contains("speaker notes") { return true }
        return false
    }

    private static func isAudienceSlideshowTab(url: String, tabTitle: String?, mode: String) -> Bool {
        guard mode == "present" else { return false }
        return !isPresenterNotesTab(url: url, tabTitle: tabTitle)
    }

    private static func probeChromiumBrowser(appName: String) -> [BrowserTabProbe] {
        let script = """
        tell application "\(appName)"
            set output to {}
            if (count of windows) is 0 then return output
            repeat with w in windows
                repeat with t in tabs of w
                    try
                        set tabURL to URL of t
                        if tabURL contains "docs.google.com/presentation" then
                            set tabTitle to title of t
                            set end of output to tabURL
                            set end of output to tabTitle
                            set end of output to "false"
                        end if
                    end try
                end repeat
            end repeat
            return output
        end tell
        """

        return decodeProbes(fromAppleScriptList: script)
    }

    private static func probeSafari() -> [BrowserTabProbe] {
        let script = """
        tell application "Safari"
            set output to {}
            if (count of windows) is 0 then return output
            repeat with w in windows
                repeat with t in tabs of w
                    try
                        set tabURL to URL of t
                        if tabURL contains "docs.google.com/presentation" then
                            set tabTitle to name of t
                            set end of output to tabURL
                            set end of output to tabTitle
                            set end of output to "false"
                        end if
                    end try
                end repeat
            end repeat
            return output
        end tell
        """

        return decodeProbes(fromAppleScriptList: script)
    }

    private static func decodeProbes(fromAppleScriptList script: String) -> [BrowserTabProbe] {
        guard let appleScript = NSAppleScript(source: script) else { return [] }
        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)
        if let error {
            lastProbeError = (error["NSAppleScriptErrorMessage"] as? String)
                ?? (error["NSAppleScriptErrorBriefMessage"] as? String)
                ?? "AppleScript failed"
            return []
        }

        let rawValues = stringList(from: result)
        var probes: [BrowserTabProbe] = []
        var index = 0

        while index < rawValues.count {
            let url = rawValues[index]
            index += 1
            guard index < rawValues.count else { break }
            let tabTitle = rawValues[index]
            index += 1

            let isActive = index < rawValues.count && rawValues[index].lowercased() == "true"
            if index < rawValues.count,
               rawValues[index].lowercased() == "true" || rawValues[index].lowercased() == "false" {
                index += 1
            }

            if let probe = probeFromURL(url, tabTitle: tabTitle, isActiveTab: isActive) {
                probes.append(probe)
            }
        }

        return probes
    }

    private static func probeFromURL(_ url: String, tabTitle: String, isActiveTab: Bool) -> BrowserTabProbe? {
        guard url.contains("docs.google.com/presentation") else { return nil }
        guard let presentationID = GoogleSlidesURLParser.presentationID(from: url) else { return nil }

        let parsed = parseSlideFromURL(url)
        guard parsed.objectId != nil || parsed.index != nil else { return nil }

        let mode: String
        if url.contains("/present") || url.contains("/htmlpresent") {
            mode = "present"
        } else if url.contains("/edit") {
            mode = "edit"
        } else {
            mode = "view"
        }

        let presenterNotes = isPresenterNotesTab(url: url, tabTitle: tabTitle)
        let audience = isAudienceSlideshowTab(url: url, tabTitle: tabTitle, mode: mode)

        return BrowserTabProbe(
            url: url,
            tabTitle: tabTitle,
            slideObjectId: parsed.objectId,
            slideIndex: parsed.index,
            presentationId: presentationID,
            mode: mode,
            isActiveTab: isActiveTab,
            isPresenterNotesTab: presenterNotes,
            isAudienceSlideshowTab: audience
        )
    }

    static func parsePresenterURL(
        _ urlString: String,
        slideObjectId explicitObjectId: String? = nil,
        slideIndex explicitSlideIndex: Int? = nil
    ) -> GoogleSlidesPresenterSession? {
        guard urlString.contains("docs.google.com/presentation") else { return nil }
        guard urlString.contains("/present") || urlString.contains("/htmlpresent") else { return nil }
        guard let presentationID = GoogleSlidesURLParser.presentationID(from: urlString) else { return nil }

        var slideObjectId = explicitObjectId.map(normalizeSlideObjectId)
        var slideIndex = explicitSlideIndex

        if slideObjectId == nil || slideIndex == nil {
            let parsed = parseSlideFromURL(urlString)
            if slideObjectId == nil { slideObjectId = parsed.objectId }
            if slideIndex == nil { slideIndex = parsed.index }
        }

        return GoogleSlidesPresenterSession(
            presentationID: presentationID,
            slideObjectId: slideObjectId,
            slideIndex: slideIndex ?? 0,
            url: urlString,
            sourceMode: "present"
        )
    }

    private static func parseEditorSession(_ urlString: String) -> (presentationID: String, slideObjectId: String?, slideIndex: Int?)? {
        guard urlString.contains("/edit") else { return nil }
        guard let presentationID = GoogleSlidesURLParser.presentationID(from: urlString) else { return nil }
        let parsed = parseSlideFromURL(urlString)
        return (presentationID, parsed.objectId, parsed.index)
    }

    private static func parseSlideFromURL(_ urlString: String) -> (objectId: String?, index: Int?) {
        guard let url = URL(string: urlString) else { return (nil, nil) }

        // Hash fragment is updated immediately when clicking slides in the editor.
        // Query ?slide= often lags behind — using it first caused jumps back to slide 1.
        var candidates: [String] = []
        if let fragment = url.fragment {
            for part in fragment.split(separator: "&") where part.hasPrefix("slide=") {
                candidates.append(String(part.dropFirst("slide=".count)))
            }
        }
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let slideValue = components.queryItems?.first(where: { $0.name == "slide" })?.value {
            candidates.append(slideValue)
        }

        for raw in candidates {
            if let index = Int(raw), index > 0 {
                return (nil, index - 1)
            }
            let objectId = normalizeSlideObjectId(raw)
            if !objectId.isEmpty {
                return (objectId, nil)
            }
        }

        return (nil, nil)
    }

    private static func normalizeSlideObjectId(_ raw: String) -> String {
        if raw.hasPrefix("id.") {
            return String(raw.dropFirst(3))
        }
        return raw
    }

    private static func stringList(from descriptor: NSAppleEventDescriptor) -> [String] {
        guard descriptor.numberOfItems > 0 else {
            if let value = descriptor.stringValue, !value.isEmpty {
                return [value]
            }
            return []
        }

        var values: [String] = []
        for index in 1...descriptor.numberOfItems {
            if let value = descriptor.atIndex(index)?.stringValue, !value.isEmpty {
                values.append(value)
            }
        }
        return values
    }
}
