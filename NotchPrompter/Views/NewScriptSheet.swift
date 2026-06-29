import SwiftUI

struct NewScriptSheet: View {
    @Environment(\.dismiss) private var dismiss

    enum Choice: String, CaseIterable, Identifiable {
        case googleSlides = "Google Slides"
        case keynote = "Keynote"
        case powerPoint = "PowerPoint"
        case richText = "Write / Paste"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .googleSlides: return "g.circle.fill"
            case .keynote: return "k.circle.fill"
            case .powerPoint: return "doc.richtext.fill"
            case .richText: return "text.quote"
            }
        }

        var subtitle: String {
            switch self {
            case .googleSlides: return "Import speaker notes from a live Google Slides URL"
            case .keynote: return "Import from a local .key presentation"
            case .powerPoint: return "Import from a local .pptx file"
            case .richText: return "Start with a blank rich-text script"
            }
        }
    }

    let onSelect: (Choice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("New Script")
                .font(.title2.bold())

            Text("Choose how you want to create your script.")
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(Choice.allCases) { choice in
                    Button {
                        dismiss()
                        onSelect(choice)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: choice.icon)
                                .font(.title2)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(choice.rawValue)
                                    .font(.headline)
                                Text(choice.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}
