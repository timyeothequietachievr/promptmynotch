import SwiftUI

/// Bridges AppState presentation flag to the floating prompter window.
struct PresentationLifecycleView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: appState.isPresenting) { _, presenting in
                if presenting {
                    PrompterWindowController.shared.show(appState: appState)
                } else {
                    PrompterWindowController.shared.hide()
                }
            }
    }
}
