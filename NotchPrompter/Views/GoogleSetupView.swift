import AppKit
import SwiftUI

struct GoogleSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var clientID = GoogleOAuthService.shared.clientID
    @State private var clientSecret = GoogleOAuthService.shared.clientSecret

    private var redirectURI: String { GoogleOAuthService.redirectURI }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Google Slides Setup")
                .font(.title2.bold())

            Text("Use a Desktop app OAuth client from Google Cloud. NotchPrompter signs in via localhost — no redirect URI to register.")
                .foregroundStyle(.secondary)

            GroupBox("Desktop app (recommended)") {
                VStack(alignment: .leading, spacing: 8) {
                    setupStep("1", "Google Cloud Console → APIs & Services → Credentials")
                    setupStep("2", "Create Credentials → OAuth client ID → Desktop app")
                    setupStep("3", "Enable Google Slides API (APIs & Services → Library)")
                    setupStep("4", "Copy Client ID and Client Secret from the credentials popup")
                    setupStep("5", "Paste both below and Save")
                    Text("Desktop clients auto-allow \(redirectURI) — do not add a redirect URI manually.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GroupBox("Only if using Web application client") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add this Authorized redirect URI:")
                        .font(.caption)
                    Text(redirectURI)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    Button("Copy redirect URI") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(redirectURI, forType: .string)
                    }
                }
            }

            TextField("Client ID", text: $clientID)
                .textFieldStyle(.roundedBorder)

            SecureField("Client Secret", text: $clientSecret)
                .textFieldStyle(.roundedBorder)

            Text("Client Secret is shown once when you create the Desktop app credential. Required for sign-in to complete.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Save") {
                    GoogleOAuthService.shared.setCredentials(clientID: clientID, clientSecret: clientSecret)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Sign Out of Google") {
                    GoogleOAuthService.shared.signOut()
                }

                Spacer()

                Link("Open Google Cloud Console", destination: URL(string: "https://console.cloud.google.com/apis/credentials")!)

                Button("Close") { dismiss() }
            }
        }
        .padding(24)
        .frame(width: 580)
    }

    private func setupStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number).fontWeight(.bold).frame(width: 16, alignment: .trailing)
            Text(text)
        }
        .font(.caption)
    }
}
