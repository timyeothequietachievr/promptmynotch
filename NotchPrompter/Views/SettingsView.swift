import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var googleClientID = GoogleOAuthService.shared.clientID
    @State private var googleClientSecret = GoogleOAuthService.shared.clientSecret

    var body: some View {
        Form {
            Section("Scrolling") {
                Slider(value: Bindable(appState).scrollSpeed, in: 10...200, step: 5) {
                    Text("Default speed")
                }
                Slider(value: Binding(
                    get: { appState.fontSize },
                    set: { appState.setFontSize($0) }
                ), in: 12...48, step: 1) {
                    Text("Text size")
                }
                Stepper("Countdown: \(appState.countdownSeconds)s", value: Bindable(appState).countdownSeconds, in: 0...10)
            }

            Section("Camera mirror") {
                CameraMirrorSettingsView()
            }

            Section("Voice activation") {
                Toggle("Advance line when last word is spoken", isOn: Bindable(appState).voiceActivationEnabled)
                Slider(value: Bindable(appState).micSensitivity, in: 0...1) {
                    Text("Microphone sensitivity")
                }
                Text("Uses speech recognition to detect when you finish each line, then scrolls to the next.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Google Slides") {
                Toggle("Follow Google Slides presenter mode", isOn: Binding(
                    get: { appState.googleSlidesSyncEnabled },
                    set: { appState.setGoogleSlidesSyncEnabled($0) }
                ))
                Text("Reads the current slide from your Google Slides browser tab URL and shows matching speaker notes in the notch. Works in edit and present mode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SlideSyncPermissionsSettingsSection()

                TextField("OAuth Client ID", text: $googleClientID)
                SecureField("OAuth Client Secret", text: $googleClientSecret)
                Button("Save Google Credentials") {
                    GoogleOAuthService.shared.setCredentials(
                        clientID: googleClientID,
                        clientSecret: googleClientSecret
                    )
                }
                Button("Sign Out of Google", role: .destructive) {
                    GoogleOAuthService.shared.signOut()
                }
            }

            Section("Privacy") {
                Text("Scripts and imported notes stay on your Mac. Google Slides import only requests read-only access to presentations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .padding()
    }
}
