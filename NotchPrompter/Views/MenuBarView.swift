import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let script = appState.selectedScript {
                Text(script.title).font(.headline)
                Text(script.source.rawValue).font(.caption).foregroundStyle(.secondary)
            } else {
                Text("No script loaded").foregroundStyle(.secondary)
            }

            Divider()

            Button(appState.isPresenting ? "Stop Presentation" : "Start Presentation") {
                appState.togglePresentation()
            }

            Button("Open Editor") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title == "Scripts" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }

            Button("Request Slide Sync Permissions…") {
                SlideSyncPermissions.promptNow()
            }

            Divider()

            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding()
        .frame(width: 220)
    }
}

import AppKit
