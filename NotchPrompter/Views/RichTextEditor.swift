import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

struct RichTextEditor: NSViewRepresentable {
    @ObservedObject var controller: RichTextEditorController
    @Binding var rtfData: Data
    @Binding var plainText: String
    var isEditable: Bool = true

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.isRichText = true
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFontPanel = true
        textView.usesRuler = false
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.font = NSFont.systemFont(ofSize: 15)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.delegate = context.coordinator

        loadContent(into: textView)
        context.coordinator.textView = textView
        controller.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.parent = self
        controller.textView = textView

        guard !context.coordinator.isUpdating else { return }
        textView.isEditable = isEditable
        textView.isSelectable = true
        if textView.string != plainText {
            loadContent(into: textView)
        }
    }

    private func loadContent(into textView: NSTextView) {
        if !rtfData.isEmpty,
           let attributed = try? NSAttributedString(
               data: rtfData,
               options: [.documentType: NSAttributedString.DocumentType.rtf],
               documentAttributes: nil
           ) {
            textView.textStorage?.setAttributedString(attributed)
        } else {
            textView.string = plainText
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        weak var textView: NSTextView?
        var isUpdating = false

        init(parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.plainText = textView.string
            let range = NSRange(location: 0, length: textView.textStorage?.length ?? 0)
            if let rtf = textView.rtf(from: range) {
                parent.rtfData = rtf
            }
            DispatchQueue.main.async { [weak self] in
                self?.isUpdating = false
            }
        }
    }
}

struct RichTextFormattingToolbar: View {
    let textView: NSTextView?

    var body: some View {
        HStack(spacing: 4) {
            FormatButton(title: "Bold", systemImage: "bold") {
                applyFontTrait(.boldFontMask)
            }
            FormatButton(title: "Italic", systemImage: "italic") {
                applyFontTrait(.italicFontMask)
            }
            FormatButton(title: "Underline", systemImage: "underline") {
                toggleUnderline()
            }

            Divider().frame(height: 18)

            FormatButton(title: "Heading", systemImage: "textformat.size.larger") {
                applyHeading()
            }
            FormatButton(title: "Body", systemImage: "textformat") {
                applyBody()
            }

            Divider().frame(height: 18)

            FormatButton(title: "Bullet List", systemImage: "list.bullet") {
                insertPrefix("• ")
            }

            Spacer()

            Text("Paste rich text from Word, Docs, Notes, etc.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func applyFontTrait(_ trait: NSFontTraitMask) {
        guard let textView else { return }
        textView.window?.makeFirstResponder(textView)
        NSFontManager.shared.target = textView
        NSFontManager.shared.addFontTrait(trait)
        textView.didChangeText()
    }

    private func toggleUnderline() {
        guard let textView else { return }
        textView.window?.makeFirstResponder(textView)
        let range = textView.selectedRange()
        guard range.length > 0,
              let storage = textView.textStorage else { return }

        var hasUnderline = false
        storage.enumerateAttribute(.underlineStyle, in: range) { value, _, _ in
            if let style = value as? Int, style != 0 { hasUnderline = true }
        }

        storage.addAttribute(
            .underlineStyle,
            value: hasUnderline ? 0 : NSUnderlineStyle.single.rawValue,
            range: range
        )
        textView.didChangeText()
    }

    private func applyHeading() {
        guard let textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0, let storage = textView.textStorage else { return }
        storage.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 22), range: range)
        textView.didChangeText()
    }

    private func applyBody() {
        guard let textView else { return }
        let range = textView.selectedRange()
        guard range.length > 0, let storage = textView.textStorage else { return }
        storage.addAttribute(.font, value: NSFont.systemFont(ofSize: 15), range: range)
        textView.didChangeText()
    }

    private func insertPrefix(_ prefix: String) {
        guard let textView else { return }
        let range = textView.selectedRange()
        guard let storage = textView.textStorage else { return }
        let lineRange = (storage.string as NSString).lineRange(for: range)
        storage.replaceCharacters(in: NSRange(location: lineRange.location, length: 0), with: prefix)
        textView.didChangeText()
    }
}

private struct FormatButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
        }
        .buttonStyle(.borderless)
        .help(title)
    }
}

/// Bridges the AppKit text view reference for the formatting toolbar.
final class RichTextEditorController: ObservableObject {
    weak var textView: NSTextView?
}
