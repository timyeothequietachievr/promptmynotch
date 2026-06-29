import AppKit
import SwiftUI

// MARK: - Sticker overlay (AppKit — reliable drag / resize / delete)

struct PolaroidStickersOverlay: NSViewRepresentable {
    @Binding var stickers: [PolaroidSticker]
    @Binding var selectedStickerID: UUID?
    let cardSize: CGSize

    func makeCoordinator() -> Coordinator {
        Coordinator(stickers: $stickers, selectedStickerID: $selectedStickerID)
    }

    func makeNSView(context: Context) -> PolaroidStickersView {
        let view = PolaroidStickersView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: PolaroidStickersView, context: Context) {
        nsView.coordinator = context.coordinator
        nsView.cardSize = cardSize
        nsView.stickers = stickers
        nsView.selectedStickerID = selectedStickerID
        nsView.syncFromModel()
    }

    final class Coordinator: NSObject {
        @Binding var stickers: [PolaroidSticker]
        @Binding var selectedStickerID: UUID?

        init(stickers: Binding<[PolaroidSticker]>, selectedStickerID: Binding<UUID?>) {
            _stickers = stickers
            _selectedStickerID = selectedStickerID
        }

        func commit(stickers: [PolaroidSticker], selected: UUID?) {
            self.stickers = stickers
            selectedStickerID = selected
        }
    }
}

final class PolaroidStickersView: NSView {
    weak var coordinator: PolaroidStickersOverlay.Coordinator?

    var cardSize: CGSize = .zero
    var stickers: [PolaroidSticker] = []
    var selectedStickerID: UUID?

    private enum DragMode {
        case none
        case move(stickerID: UUID, origin: PolaroidSticker, startPoint: NSPoint)
        case resize(stickerID: UUID, originScale: CGFloat, accumulated: CGFloat)
    }

    private var dragMode: DragMode = .none
    private var keyMonitor: Any?

    override var isOpaque: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    deinit {
        removeKeyMonitor()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            installKeyMonitor()
        } else {
            removeKeyMonitor()
        }
    }

    func syncFromModel() {
        needsDisplay = true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point) else { return nil }
        if hitTestResizeHandle(at: point) != nil { return self }
        if hitTestSticker(at: point) != nil { return self }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)

        if let handleID = hitTestResizeHandle(at: point) {
            guard let index = stickers.firstIndex(where: { $0.id == handleID }) else { return }
            selectedStickerID = handleID
            dragMode = .resize(stickerID: handleID, originScale: stickers[index].scale, accumulated: 0)
            coordinator?.commit(stickers: stickers, selected: handleID)
            return
        }

        if let stickerID = hitTestSticker(at: point) {
            selectedStickerID = stickerID
            guard let sticker = stickers.first(where: { $0.id == stickerID }) else { return }
            dragMode = .move(stickerID: stickerID, origin: sticker, startPoint: point)
            coordinator?.commit(stickers: stickers, selected: stickerID)
            return
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        switch dragMode {
        case .none:
            break
        case .move(let id, let origin, let startPoint):
            guard let index = stickers.firstIndex(where: { $0.id == id }) else { return }
            let dx = (point.x - startPoint.x) / bounds.width
            let dy = -(point.y - startPoint.y) / bounds.height
            stickers[index].x = clamp(origin.x + dx, min: 0.06, max: 0.94)
            stickers[index].y = clamp(origin.y + dy, min: 0.06, max: 0.94)
            coordinator?.commit(stickers: stickers, selected: selectedStickerID)
            needsDisplay = true
        case .resize(let id, let originScale, var accumulated):
            guard let index = stickers.firstIndex(where: { $0.id == id }) else { return }
            accumulated += event.deltaX + event.deltaY
            dragMode = .resize(stickerID: id, originScale: originScale, accumulated: accumulated)
            stickers[index].scale = clamp(originScale + accumulated / 80, min: 0.45, max: 3.5)
            coordinator?.commit(stickers: stickers, selected: selectedStickerID)
            needsDisplay = true
        }
    }

    override func mouseUp(with event: NSEvent) {
        dragMode = .none
    }

    override func draw(_ dirtyRect: NSRect) {
        guard cardSize.width > 0, cardSize.height > 0 else { return }

        for sticker in stickers {
            let isSelected = sticker.id == selectedStickerID
            let fontSize = PolaroidLayout.baseStickerFontSize * sticker.scale
            let center = NSPoint(
                x: sticker.x * bounds.width,
                y: bounds.height - sticker.y * bounds.height
            )

            let font = NSFont.systemFont(ofSize: fontSize)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let size = (sticker.emoji as NSString).size(withAttributes: attrs)
            let rect = NSRect(
                x: center.x - size.width / 2 - 6,
                y: center.y - size.height / 2 - 6,
                width: size.width + 12,
                height: size.height + 12
            )

            if isSelected {
                NSColor.controlAccentColor.withAlphaComponent(0.15).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()
                NSColor.controlAccentColor.setStroke()
                let border = NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6)
                border.lineWidth = 2
                border.stroke()

                let handleRect = NSRect(
                    x: rect.maxX - 11,
                    y: rect.minY - 11,
                    width: 22,
                    height: 22
                )
                NSColor.controlAccentColor.setFill()
                NSBezierPath(ovalIn: handleRect).fill()
            }

            (sticker.emoji as NSString).draw(
                at: NSPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
                withAttributes: attrs
            )
        }
    }

    private func hitTestSticker(at point: NSPoint) -> UUID? {
        for sticker in stickers.reversed() {
            let fontSize = PolaroidLayout.baseStickerFontSize * sticker.scale
            let center = NSPoint(
                x: sticker.x * bounds.width,
                y: bounds.height - sticker.y * bounds.height
            )
            let font = NSFont.systemFont(ofSize: fontSize)
            let size = (sticker.emoji as NSString).size(withAttributes: [.font: font])
            let rect = NSRect(
                x: center.x - size.width / 2 - 8,
                y: center.y - size.height / 2 - 8,
                width: size.width + 16,
                height: size.height + 16
            )
            if rect.contains(point) { return sticker.id }
        }
        return nil
    }

    private func hitTestResizeHandle(at point: NSPoint) -> UUID? {
        guard let id = selectedStickerID,
              let sticker = stickers.first(where: { $0.id == id }) else { return nil }
        let rect = resizeHandleRect(for: sticker)
        return rect.contains(point) ? id : nil
    }

    private func resizeHandleRect(for sticker: PolaroidSticker) -> NSRect {
        let fontSize = PolaroidLayout.baseStickerFontSize * sticker.scale
        let center = NSPoint(
            x: sticker.x * bounds.width,
            y: bounds.height - sticker.y * bounds.height
        )
        let font = NSFont.systemFont(ofSize: fontSize)
        let size = (sticker.emoji as NSString).size(withAttributes: [.font: font])
        let stickerRect = NSRect(
            x: center.x - size.width / 2 - 6,
            y: center.y - size.height / 2 - 6,
            width: size.width + 12,
            height: size.height + 12
        )
        return NSRect(x: stickerRect.maxX - 11, y: stickerRect.minY - 11, width: 22, height: 22)
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, window?.firstResponder === self else { return event }
            guard event.keyCode == 51 || event.keyCode == 117 else { return event }
            deleteSelectedSticker()
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func deleteSelectedSticker() {
        guard let id = selectedStickerID else { return }
        stickers.removeAll { $0.id == id }
        selectedStickerID = nil
        coordinator?.commit(stickers: stickers, selected: nil)
        needsDisplay = true
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.min(maxValue, Swift.max(minValue, value))
    }
}

// MARK: - Caption field

struct PolaroidCaptionEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    let fontSize: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> PolaroidCaptionContainer {
        let container = PolaroidCaptionContainer()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.cgColor

        let field = PolaroidCaptionField(string: text, fontSize: fontSize)
        field.onClick = { [weak coordinator = context.coordinator] in
            CameraMirrorWindowController.shared.setPolaroidEditingActive(true)
            coordinator?.beginEditing()
        }
        field.delegate = context.coordinator
        field.translatesAutoresizingMaskIntoConstraints = false
        container.captionField = field
        container.addSubview(field)
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.field = field
        return container
    }

    func updateNSView(_ container: PolaroidCaptionContainer, context: Context) {
        guard let field = context.coordinator.field else { return }
        if field.stringValue != text {
            field.stringValue = text
        }
        field.applyCaptionStyle(fontSize: fontSize)
        if isEditing, !context.coordinator.isEditingActive {
            context.coordinator.beginEditing()
        } else if !isEditing, context.coordinator.isEditingActive {
            context.coordinator.endEditing()
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PolaroidCaptionEditor
        weak var field: PolaroidCaptionField?
        var isEditingActive = false

        init(parent: PolaroidCaptionEditor) {
            self.parent = parent
        }

        func beginEditing() {
            guard let field, !isEditingActive else { return }
            isEditingActive = true
            parent.isEditing = true
            field.isEditable = true
            field.isSelectable = true
            DispatchQueue.main.async { [weak self] in
                guard let self, let field = self.field else { return }
                field.window?.makeFirstResponder(field)
                if let editor = field.currentEditor() as? NSTextView {
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.alignment = .center
                    editor.alignment = .center
                    editor.typingAttributes[.paragraphStyle] = paragraph
                    editor.selectedRange = NSRange(location: field.stringValue.count, length: 0)
                }
            }
        }

        func endEditing() {
            guard let field else { return }
            isEditingActive = false
            field.isEditable = false
            field.isSelectable = false
            if field.window?.firstResponder === field.currentEditor() {
                field.window?.makeFirstResponder(nil)
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                isEditingActive = false
                parent.isEditing = false
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isEditingActive = false
            parent.isEditing = false
        }
    }
}

final class PolaroidCaptionContainer: NSView {
    weak var captionField: NSView?

    override var isOpaque: Bool { false }

    override var mouseDownCanMoveWindow: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        return result === self ? captionField : result
    }
}

final class PolaroidCaptionField: NSTextField {
    var onClick: (() -> Void)?

    convenience init(string: String, fontSize: CGFloat) {
        self.init(frame: .zero)
        stringValue = string
        isEditable = false
        isSelectable = false
        applyCaptionStyle(fontSize: fontSize)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        isBezeled = false
        drawsBackground = false
        backgroundColor = .clear
        focusRingType = .none
        alignment = .center
        lineBreakMode = .byWordWrapping
        maximumNumberOfLines = 2
        cell?.wraps = true
        cell?.isScrollable = false
    }

    required init?(coder: NSCoder) {
        nil
    }

    func applyCaptionStyle(fontSize: CGFloat) {
        let font = PolaroidFont.nsFont(size: fontSize)
        self.font = font
        textColor = .black

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        placeholderAttributedString = NSAttributedString(
            string: "Click to add text",
            attributes: [
                .font: font,
                .foregroundColor: NSColor(white: 0.58, alpha: 1),
                .paragraphStyle: paragraph,
            ]
        )

        if let editor = currentEditor() {
            editor.alignment = .center
        }
    }

    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        onClick?()
        super.mouseDown(with: event)
    }
}
