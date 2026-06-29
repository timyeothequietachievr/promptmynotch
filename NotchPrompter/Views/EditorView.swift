import SwiftUI

struct EditorView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var richTextController = RichTextEditorController()
    @State private var draftTitle = ""
    @State private var draftContent = ""
    @State private var draftRTF = Data()
    @State private var isSyncingScript = false
    @State private var isScriptEditing = false
    @State private var preEditTitle = ""
    @State private var preEditContent = ""
    @State private var preEditRTF = Data()

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
                            Text(script.source.rawValue)
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
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { appState.openNewScriptPicker() }) {
                        Label("New", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button(action: { appState.showImportPanel.toggle() }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { appState.toggleCameraMirror(anchorToPrompter: appState.isPresenting) }) {
                    PrompterToolbarStyle.editorFilledCircleIcon(
                        systemName: "video.circle.fill",
                        active: appState.cameraMirrorVisible
                    )
                }
                .buttonStyle(.plain)
                .help("Open camera mirror")
            }
        }
        .onAppear { syncDraftFromSelection() }
        .onChange(of: appState.selectedScriptID) { _, _ in
            isScriptEditing = false
            syncDraftFromSelection()
        }
        .onChange(of: appState.presentationSlideRevision) { _, _ in
            guard !isScriptEditing else { return }
            syncDraftFromSelection()
        }
    }

    private var editorDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TextField("Title", text: $draftTitle)
                    .font(.title2.bold())
                    .textFieldStyle(.plain)
                    .disabled(!isScriptEditing)
                    .onSubmit { saveDraftNow() }

                if let source = appState.selectedScript?.source, source != .manual {
                    Label(source.rawValue, systemImage: sourceIcon(source))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }

                Spacer()

                if isScriptEditing {
                    Button("Cancel") {
                        cancelScriptEditing()
                    }
                    .buttonStyle(.bordered)

                    Button("Save") {
                        saveScriptEditing()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Edit") {
                        beginScriptEditing()
                    }
                    .buttonStyle(.bordered)
                }

                Button(appState.isPresenting ? "Stop" : "Present") {
                    saveDraftNow()
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

            RichTextFormattingToolbar(textView: isScriptEditing ? richTextController.textView : nil)
                .opacity(isScriptEditing ? 1 : 0.45)
                .allowsHitTesting(isScriptEditing)

            Divider()

            ZStack(alignment: .topLeading) {
                RichTextEditor(
                    controller: richTextController,
                    rtfData: $draftRTF,
                    plainText: $draftContent,
                    isEditable: isScriptEditing
                )

                if !isScriptEditing {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            beginScriptEditing()
                        }
                }
            }
        }
    }

    private func beginScriptEditing() {
        preEditTitle = draftTitle
        preEditContent = draftContent
        preEditRTF = draftRTF
        isScriptEditing = true
        DispatchQueue.main.async {
            richTextController.textView?.isEditable = true
            richTextController.textView?.window?.makeFirstResponder(richTextController.textView)
        }
    }

    private func cancelScriptEditing() {
        draftTitle = preEditTitle
        draftContent = preEditContent
        draftRTF = preEditRTF
        isScriptEditing = false
    }

    private func saveScriptEditing() {
        saveDraftNow()
        isScriptEditing = false
    }

    private func syncDraftFromSelection() {
        isSyncingScript = true
        defer { isSyncingScript = false }

        draftTitle = appState.selectedScript?.title ?? ""
        draftContent = appState.selectedScript?.content ?? ""
        draftRTF = appState.selectedScript?.richContentRTF ?? Data()
    }

    private func saveDraftNow() {
        appState.saveSelectedScriptEditorChanges(
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
