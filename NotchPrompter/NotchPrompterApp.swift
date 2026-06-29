import SwiftUI

@main
struct NotchPrompterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup("Scripts", id: "editor") {
            AppRootView(appState: appState)
        }
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Script") {
                    appState.openNewScriptPicker()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Prompter") {
                Button(appState.isPresenting ? "Stop Presentation" : "Start Presentation") {
                    appState.togglePresentation()
                }
                .keyboardShortcut("p", modifiers: .command)

                Divider()

                Button("Increase Speed") { appState.adjustSpeed(by: 10) }
                    .keyboardShortcut(.upArrow, modifiers: .command)
                Button("Decrease Speed") { appState.adjustSpeed(by: -10) }
                    .keyboardShortcut(.downArrow, modifiers: .command)
                Button("Larger Text") { appState.adjustFontSize(by: 2) }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Smaller Text") { appState.adjustFontSize(by: -2) }
                    .keyboardShortcut("-", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }

        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.menu)
    }
}
