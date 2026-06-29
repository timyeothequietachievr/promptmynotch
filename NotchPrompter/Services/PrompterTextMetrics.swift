import AppKit

enum PrompterTextMetrics {
    static let horizontalPadding: CGFloat = 20
    static let topPadding: CGFloat = 24
    static let lineSpacing: CGFloat = 6

    static func font(size: CGFloat, weight: NSFont.Weight = .medium) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        if let rounded = base.fontDescriptor.withDesign(.rounded) {
            return NSFont(descriptor: rounded, size: size) ?? base
        }
        return base
    }

    static func paragraphStyle() -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = lineSpacing
        return paragraph
    }

    static func textContainerWidth(for containerWidth: CGFloat) -> CGFloat {
        max(1, containerWidth - horizontalPadding * 2)
    }

    private static let textContainerHeight: CGFloat = 10_000_000

    static func makeTextKitStack(
        text: String,
        fontSize: Double,
        containerWidth: CGFloat
    ) -> (NSTextStorage, NSLayoutManager, NSTextContainer) {
        let font = font(size: fontSize)
        let storage = NSTextStorage(
            string: text,
            attributes: [.font: font, .paragraphStyle: paragraphStyle()]
        )
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(
            size: CGSize(width: textContainerWidth(for: containerWidth), height: textContainerHeight)
        )
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        layoutManager.ensureLayout(for: textContainer)

        return (storage, layoutManager, textContainer)
    }

    static func viewPointToTextPoint(
        _ viewPoint: CGPoint,
        scrollOffset: CGFloat,
        topChromeInset: CGFloat = 0
    ) -> CGPoint {
        CGPoint(
            x: viewPoint.x - horizontalPadding,
            y: viewPoint.y + scrollOffset - topPadding - topChromeInset
        )
    }
}
