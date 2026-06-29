import SwiftUI

/// Root container — applies shared app state to the full window hierarchy.
struct AppRootView: View {
    @Bindable var appState: AppState

    var body: some View {
        EditorView()
            .environment(appState)
            .background {
                PresentationLifecycleView()
                    .environment(appState)
            }
            .sheet(isPresented: Bindable(appState).showNewScriptPicker) {
                NewScriptSheet { choice in
                    appState.handleNewScriptChoice(choice)
                }
            }
            .onAppear {
                GoogleSlidesPresenterMonitor.shared.bind(appState: appState)
                CameraMirrorWindowController.shared.bind(appState: appState)
            }
    }
}
