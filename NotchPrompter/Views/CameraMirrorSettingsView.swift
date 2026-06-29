import AppKit
import SwiftUI

struct CameraMirrorSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var availableDisplays: [(id: String, name: String)] = []

    var body: some View {
        @Bindable var appState = appState

        Group {
            windowTypePicker(appState: appState)

            VStack(alignment: .leading, spacing: 8) {
                Text("Window position")
                    .font(.subheadline.weight(.medium))
                CameraMirrorPositionGrid(
                    selection: Binding(
                        get: { appState.cameraMirrorSnapPosition },
                        set: { appState.setCameraMirrorSnapPosition($0) }
                    )
                )
            }

            Picker("Display", selection: Binding(
                get: { appState.cameraMirrorDisplayID ?? availableDisplays.first?.id ?? "" },
                set: { appState.setCameraMirrorDisplayID($0.isEmpty ? nil : $0) }
            )) {
                ForEach(availableDisplays, id: \.id) { display in
                    Text(display.name).tag(display.id)
                }
            }

            Toggle("Lock aspect ratio", isOn: Binding(
                get: { appState.cameraMirrorLockAspectRatio },
                set: { appState.setCameraMirrorLockAspectRatio($0) }
            ))

            Toggle("Manual position", isOn: Binding(
                get: { appState.cameraMirrorManualPosition },
                set: { appState.setCameraMirrorManualPosition($0) }
            ))
            Text("When off, the mirror snaps to the preset position above. Turn on to drag it anywhere.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Keep window in front", isOn: Binding(
                get: { appState.cameraMirrorKeepInFront },
                set: { appState.setCameraMirrorKeepInFront($0) }
            ))

            Toggle("Close window when unfocused", isOn: Binding(
                get: { appState.cameraMirrorCloseWhenUnfocused },
                set: { appState.setCameraMirrorCloseWhenUnfocused($0) }
            ))

            Picker("Shape", selection: Binding(
                get: { appState.cameraMirrorShape },
                set: { appState.setCameraMirrorShape($0) }
            )) {
                ForEach(CameraMirrorShape.allCases.filter(\.isSelectable)) { shape in
                    Label(shape.label, systemImage: shape.systemImage).tag(shape)
                }
            }

            Text("The camera mirror appears in screen recordings. The teleprompter stays hidden.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { refreshDisplays() }
    }

    private func windowTypePicker(appState: AppState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Window type")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 12) {
                ForEach(CameraMirrorWindowType.allCases) { type in
                    Button {
                        appState.setCameraMirrorWindowType(type)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: type.systemImage)
                                .font(.title2)
                                .frame(width: 72, height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.secondary.opacity(0.12))
                                )
                            Text(type.label)
                                .font(.caption)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(
                                    appState.cameraMirrorWindowType == type ? Color.accentColor : Color.secondary.opacity(0.25),
                                    lineWidth: appState.cameraMirrorWindowType == type ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func refreshDisplays() {
        availableDisplays = NSScreen.screens.map { ($0.displayIdentifier, $0.localizedName) }
        if appState.cameraMirrorDisplayID == nil, let first = availableDisplays.first {
            appState.setCameraMirrorDisplayID(first.id)
        }
    }
}

struct CameraMirrorPositionGrid: View {
    @Binding var selection: CameraMirrorSnapPosition

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.35, blue: 0.55),
                            Color(red: 0.45, green: 0.25, blue: 0.35),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                ForEach(Array(CameraMirrorSnapPosition.gridRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(row) { position in
                            Button {
                                selection = position
                            } label: {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(
                                        selection == position
                                            ? Color.white
                                            : Color.white.opacity(0.35)
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 22)
                            }
                            .buttonStyle(.plain)
                            .help(position.label)
                        }
                    }
                }
            }
            .padding(10)
        }
        .frame(height: 110)
    }
}
