import SwiftUI
import UniformTypeIdentifiers

struct ImportPanelView: View {
    @Environment(AppState.self) private var appState
    @Binding var selectedTab: ImportTab
    var onOpenEditor: (() -> Void)?

    @State private var googleSlidesURL = ""
    @State private var statusMessage: String?
    @State private var showGoogleSetup = false
    @State private var showBrowserPicker = false

    enum ImportTab: String, CaseIterable, Identifiable {
        case googleSlides = "Google Slides"
        case keynote = "Keynote"
        case powerPoint = "PowerPoint"
        case richText = "Write / Paste"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import Speaker Notes")
                .font(.title2.bold())

            Text("Google Slides, Keynote, PowerPoint, or paste rich text into the editor.")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Picker("Source", selection: $selectedTab) {
                ForEach(ImportTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedTab {
                case .googleSlides:
                    googleSlidesImportSection
                case .keynote:
                    keynoteImportSection
                case .powerPoint:
                    powerPointImportSection
                case .richText:
                    richTextImportSection
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if appState.isImporting {
                ProgressView("Importing speaker notes…")
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(statusMessage.contains("failed") || statusMessage.contains("Error") ? .red : .green)
            }

            if let error = appState.importError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .sheet(isPresented: $showGoogleSetup) {
            GoogleSetupView()
        }
        .sheet(isPresented: $showBrowserPicker) {
            BrowserPickerView { browser in
                Task { await importFromGoogleSlides(using: browser) }
            }
        }
    }

    private var googleSlidesImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Priority 1 — Live Google Slides", systemImage: "1.circle.fill")
                .font(.headline)

            Text("Paste a Google Slides link. NotchPrompter reads each slide's speaker notes via the Google Slides API.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("https://docs.google.com/presentation/d/…/edit", text: $googleSlidesURL)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Import from Google Slides") {
                    showBrowserPicker = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(googleSlidesURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isImporting)

                Button("Google Setup…") {
                    showGoogleSetup = true
                }
            }

            if !GoogleOAuthService.shared.isConfigured {
                Text("Requires a Google Cloud OAuth Client ID (Desktop app). Open Google Setup for instructions.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if appState.selectedScript?.googlePresentationID == nil,
               appState.selectedScript?.source == .googleSlides {
                Text("Re-import this deck to enable live slide sync with Google Slides presenter mode.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var keynoteImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Priority 2 — Keynote (.key)", systemImage: "2.circle.fill")
                .font(.headline)

            Text("Choose a local Keynote presentation. Keynote opens briefly to read presenter notes, then closes without saving.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Choose Keynote File…") {
                pickKeynoteFile()
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isImporting)
        }
    }

    private var powerPointImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Local PowerPoint (.pptx)", systemImage: "doc.richtext")
                .font(.headline)

            Text("Import speaker notes from any local .pptx file — Microsoft PowerPoint, Google Slides exports, etc.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Choose PowerPoint File…") {
                pickPowerPointFile()
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isImporting)
        }
    }

    private var richTextImportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Write or paste rich text", systemImage: "text.quote")
                .font(.headline)

            Text("Open the WYSIWYG editor and paste from Word, Google Docs, Apple Notes, or any app that copies formatted text. Bold, italic, and headings are preserved while editing.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("New Script & Open Editor") {
                appState.createRichTextScript()
                onOpenEditor?()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func importFromGoogleSlides(using browser: InstalledBrowser) async {
        appState.isImporting = true
        appState.importError = nil
        statusMessage = nil
        defer { appState.isImporting = false }

        do {
            let presentation = try await PresentationImportService.importGoogleSlides(
                urlOrID: googleSlidesURL,
                browser: browser
            )
            appState.applyImport(presentation)
            let withNotes = presentation.slides.filter { !$0.isEmpty }.count
            statusMessage = "Imported \(withNotes) slides with speaker notes from \(presentation.title)."
            onOpenEditor?()
        } catch {
            appState.importError = error.localizedDescription
        }
    }

    private func pickKeynoteFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "key") ?? .data]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a Keynote presentation"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task { await importKeynote(from: url) }
    }

    private func pickPowerPointFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "pptx") ?? .data,
            UTType(filenameExtension: "ppt") ?? .data,
        ]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a PowerPoint presentation"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        importPowerPoint(from: url)
    }

    private func importKeynote(from url: URL) async {
        appState.isImporting = true
        appState.importError = nil
        statusMessage = nil
        defer { appState.isImporting = false }

        do {
            let presentation = try await PresentationImportService.importKeynote(from: url)
            appState.applyImport(presentation)
            let withNotes = presentation.slides.filter { !$0.isEmpty }.count
            statusMessage = "Imported \(withNotes) slides with presenter notes from \(presentation.title)."
            onOpenEditor?()
        } catch {
            appState.importError = error.localizedDescription
        }
    }

    private func importPowerPoint(from url: URL) {
        appState.isImporting = true
        appState.importError = nil
        statusMessage = nil
        defer { appState.isImporting = false }

        do {
            let presentation = try PresentationImportService.importPowerPoint(from: url)
            appState.applyImport(presentation)
            let withNotes = presentation.slides.filter { !$0.isEmpty }.count
            statusMessage = "Imported \(withNotes) slides with speaker notes from \(presentation.title)."
            onOpenEditor?()
        } catch {
            appState.importError = error.localizedDescription
        }
    }
}

import AppKit
