import SwiftUI

struct SlideSyncPermissionsSettingsSection: View {
    @State private var statuses = SlideSyncPermissions.statuses()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Slide sync permissions")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Check again") {
                    SlideSyncPermissions.promptNow()
                    refresh(forcePrompt: false)
                }
            }

            ForEach(statuses, id: \.permission) { status in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: status.granted ? "checkmark.circle.fill" : (status.permission == .accessibility ? "info.circle.fill" : "exclamationmark.triangle.fill"))
                        .foregroundStyle(status.granted ? .green : (status.permission == .accessibility ? .secondary : .orange))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.permission.title)
                            .font(.caption.weight(.semibold))
                        Text(status.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !status.granted {
                        Button("Fix") {
                            SlideSyncPermissions.request(status.permission)
                            refresh(forcePrompt: false)
                        }
                        .controlSize(.small)
                    }
                }
            }

            Text("App path: \(SlideSyncPermissions.runningAppPath())")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
        .onAppear { refresh(forcePrompt: false) }
    }

    private func refresh(forcePrompt: Bool) {
        statuses = SlideSyncPermissions.statuses()
        if forcePrompt || statuses.contains(where: { !$0.granted }) {
            SlideSyncPermissions.ensureGranted(promptIfMissing: forcePrompt, forcePrompt: forcePrompt)
            statuses = SlideSyncPermissions.statuses()
        }
    }
}
