import AppKit
import SwiftUI

/// Editable speaker-notes surface for prompter edit mode. Double-click toggles ALL CAPS emphasis.
struct PrompterSlideEditor: NSViewRepresentable {
    @Binding var text: String
    let fontSize: Double
    let textColor: Color

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = PrompterEditTextView()
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        scrollView.documentView = textView

        configure(textView: textView, context: context)
        textView.string = text
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PrompterEditTextView else { return }
        context.coordinator.parent = self
        context.coordinator.textView = textView

        guard !context.coordinator.isUpdating else { return }
        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            let length = (text as NSString).length
            let location = min(selected.location, length)
            let selLength = min(selected.length, max(0, length - location))
            textView.setSelectedRange(NSRange(location: location, length: selLength))
        }

        applyStyle(to: textView)
    }

    private func configure(textView: PrompterEditTextView, context: Context) {
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 20, height: 24)
        textView.delegate = context.coordinator
        textView.onTextChange = { [weak coordinator = context.coordinator] newText in
            coordinator?.textDidChange(newText)
        }
        applyStyle(to: textView)
    }

    private func applyStyle(to textView: NSTextView) {
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        textView.font = font
        textView.textColor = NSColor(textColor)
        textView.insertionPointColor = NSColor(textColor)
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor(textColor),
            .paragraphStyle: centeredParagraphStyle(),
        ]
        syncBaseTypography(in: textView)
    }

    private func syncBaseTypography(in textView: NSTextView) {
        guard let storage = textView.textStorage else { return }
        let font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let paragraph = centeredParagraphStyle()
        let foreground = NSColor(textColor)
        let fullRange = NSRange(location: 0, length: storage.length)

        storage.enumerateAttributes(in: fullRange) { attributes, range, _ in
            var updated = attributes
            updated[.font] = font
            updated[.foregroundColor] = foreground
            updated[.paragraphStyle] = paragraph
            storage.setAttributes(updated, range: range)
        }
    }

    private func centeredParagraphStyle() -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = PrompterTextMetrics.lineSpacing
        return paragraph
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PrompterSlideEditor
        weak var textView: NSTextView?
        var isUpdating = false

        init(parent: PrompterSlideEditor) {
            self.parent = parent
        }

        func textDidChange(_ newText: String) {
            isUpdating = true
            parent.text = newText
            DispatchQueue.main.async { [weak self] in
                self?.isUpdating = false
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            textDidChange(textView.string)
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            true
        }
    }
}

private final class PrompterEditTextView: NSTextView {
    var onTextChange: ((String) -> Void)?

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        let isDoubleClick = event.clickCount == 2
        super.mouseDown(with: event)
        guard isDoubleClick else { return }
        DispatchQueue.main.async { [weak self] in
            self?.toggleSelectedWordEmphasis()
        }
    }

    private func toggleSelectedWordEmphasis() {
        var range = selectedRange()
        if range.length == 0 {
            selectWord(nil)
            range = selectedRange()
        }
        guard range.length > 0 else { return }

        let word = (string as NSString).substring(with: range)
        let replacement = PrompterTextTokenizer.isAllCapsWord(word)
            ? word.lowercased()
            : word.uppercased()
        guard word != replacement else { return }

        if let storage = textStorage {
            storage.replaceCharacters(in: range, with: replacement)
        }
        didChangeText()

        let newRange = NSRange(location: range.location, length: (replacement as NSString).length)
        setSelectedRange(newRange)
        pulseWordBackground(at: newRange)
    }

    private func pulseWordBackground(at range: NSRange) {
        guard let storage = textStorage else { return }
        let ember = NSColor(red: 0.93, green: 0.35, blue: 0.10, alpha: 1)

        func setPulse(_ amount: CGFloat) {
            guard NSMaxRange(range) <= storage.length else { return }
            if amount <= 0 {
                storage.removeAttribute(.backgroundColor, range: range)
            } else {
                storage.addAttribute(
                    .backgroundColor,
                    value: ember.withAlphaComponent(0.22 + 0.58 * amount),
                    range: range
                )
            }
        }

        setPulse(1)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(180))
            for step: CGFloat in [0.75, 0.5, 0.25, 0] {
                setPulse(step)
                try? await Task.sleep(for: .milliseconds(100))
            }
            guard self?.string != nil else { return }
            setPulse(0)
        }
    }
}
