import SwiftUI

struct EditorView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var richTextController = RichTextEditorController()
    @State private var draftTitle = ""
    @State private var draftContent = ""
    @State private var draftRTF = Data()
    @State private var isSyncingScript = false

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { appState.selectedScriptID },
                set: { appState.selectedScriptID = $0 }
            )) {
                Section("Scripts") {
                    ForEach(appState.scripts) { script in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(script.title).font(.headline)
                            HStack {
                                Text(script.source.rawValue)
                                Text("·")
                                Text(script.updatedAt, style: .relative)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .tag(script.id)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                appState.deleteScript(script)
                                syncDraftFromSelection()
                            }
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            .toolbar {
                ToolbarItem {
                    Button(action: { appState.openNewScriptPicker() }) {
                        Label("New", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: { appState.showImportPanel.toggle() }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem {
                    Button(action: { appState.toggleCameraMirror() }) {
                        Label("Camera", systemImage: "video.fill")
                    }
                    .help("Open camera mirror")
                }
            }
        } detail: {
            VStack(spacing: 0) {
                if appState.showImportPanel {
                    ImportPanelView(
                        selectedTab: Bindable(appState).importPanelTab,
                        onOpenEditor: { appState.showImportPanel = false }
                    )
                    Divider()
                }

                if appState.selectedScript != nil {
                    editorDetail
                } else {
                    ContentUnavailableView(
                        "No script selected",
                        systemImage: "doc.text",
                        description: Text("Click + to create or import a script.")
                    )
                }
            }
        }
        .onAppear { syncDraftFromSelection() }
        .onChange(of: appState.selectedScriptID) { _, _ in syncDraftFromSelection() }
        .onChange(of: appState.scripts) { _, _ in syncDraftFromSelection() }
        .onChange(of: appState.selectedScript?.updatedAt) { _, _ in syncDraftFromSelection() }
        .onChange(of: appState.presentationSlideRevision) { _, _ in syncDraftFromSelection() }
    }

    private var editorDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TextField("Title", text: $draftTitle)
                    .font(.title2.bold())
                    .textFieldStyle(.plain)
                    .onSubmit { saveDraft() }

                Spacer()

                if let source = appState.selectedScript?.source, source != .manual {
                    Label(source.rawValue, systemImage: sourceIcon(source))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }

                Button(appState.isPresenting ? "Stop" : "Present") {
                    saveDraft()
                    if appState.isPresenting {
                        appState.stopPresentation()
                    } else {
                        appState.currentSlideIndex = 0
                        appState.presentationSlideRevision += 1
                        appState.startPresentation()
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("p", modifiers: .command)
            }
            .padding()

            RichTextFormattingToolbar(textView: richTextController.textView)

            Divider()

            RichTextEditor(controller: richTextController, rtfData: $draftRTF, plainText: $draftContent)
                .id("\(appState.selectedScriptID?.uuidString ?? "none")-\(appState.selectedScript?.updatedAt.timeIntervalSinceReferenceDate ?? 0)")
                .onChange(of: draftContent) { _, _ in
                    guard !isSyncingScript else { return }
                    saveDraft()
                }
                .onChange(of: draftRTF) { _, _ in
                    guard !isSyncingScript else { return }
                    saveDraft()
                }
        }
    }

    private func syncDraftFromSelection() {
        isSyncingScript = true
        defer { isSyncingScript = false }

        draftTitle = appState.selectedScript?.title ?? ""
        draftContent = appState.selectedScript?.content ?? ""
        draftRTF = appState.selectedScript?.richContentRTF ?? Data()
    }

    private func saveDraft() {
        appState.updateSelectedScript(
            title: draftTitle,
            content: draftContent,
            richContentRTF: draftRTF
        )
    }

    private func sourceIcon(_ source: ImportSource) -> String {
        switch source {
        case .googleSlides: return "g.circle"
        case .keynote: return "k.circle"
        case .powerPoint: return "doc.richtext"
        case .richText: return "text.quote"
        case .manual: return "pencil"
        }
    }
}
