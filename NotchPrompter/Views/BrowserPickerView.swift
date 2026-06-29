import SwiftUI

struct BrowserPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (InstalledBrowser) -> Void

    @State private var browsers: [InstalledBrowser] = []
    @State private var selectedBrowserID: String?
    @State private var rememberChoice = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose browser for Google sign-in")
                .font(.title2.bold())

            Text("Pick the browser where you're signed into Google. NotchPrompter will open sign-in there and return here when done.")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            if browsers.isEmpty {
                ContentUnavailableView(
                    "No browsers found",
                    systemImage: "globe",
                    description: Text("Install a web browser such as Safari or Chrome.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(browsers, id: \.id) { (browser: InstalledBrowser) in
                            Button {
                                selectedBrowserID = browser.id
                            } label: {
                                HStack(spacing: 12) {
                                    let icon = NSWorkspace.shared.icon(forFile: browser.appURL.path)
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                    Text(browser.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedBrowserID == browser.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    selectedBrowserID == browser.id
                                        ? Color.accentColor.opacity(0.12)
                                        : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: 200, maxHeight: 280)
            }

            Toggle("Remember this browser", isOn: $rememberChoice)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Continue") {
                    guard let id = selectedBrowserID,
                          let browser = browsers.first(where: { $0.id == id }) else { return }
                    if rememberChoice {
                        BrowserDiscovery.setPreferredBrowser(browser)
                    }
                    dismiss()
                    onSelect(browser)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedBrowserID == nil)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear { loadBrowsers() }
    }

    private func loadBrowsers() {
        browsers = BrowserDiscovery.installedBrowsers()
        if let preferred = BrowserDiscovery.preferredBrowser,
           browsers.contains(where: { $0.id == preferred.id }) {
            selectedBrowserID = preferred.id
        } else {
            selectedBrowserID = browsers.first?.id
        }
    }
}

import AppKit
