import AppKit
import Foundation

struct PrompterLine: Identifiable, Equatable {
    let index: Int
    let text: String
    let words: [String]
    let firstWordIndex: Int
    let lastWordIndex: Int
    let yOffset: CGFloat
    let height: CGFloat

    var id: Int { index }

    var lastWord: String? {
        words.last
    }
}

enum PrompterLineLayout {
    private static let readingLineRatio: CGFloat = 0.22

    static func computeLines(text: String, fontSize: Double, containerWidth: CGFloat) -> [PrompterLine] {
        guard !text.isEmpty else { return [] }

        let (_, layoutManager, textContainer) = PrompterTextMetrics.makeTextKitStack(
            text: text,
            fontSize: fontSize,
            containerWidth: containerWidth
        )

        var lines: [PrompterLine] = []
        var lineIndex = 0
        let fullRange = NSRange(location: 0, length: layoutManager.numberOfGlyphs)

        layoutManager.enumerateLineFragments(forGlyphRange: fullRange) { _, usedRect, _, glyphRange, _ in
            let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            let lineText = (text as NSString).substring(with: charRange).trimmingCharacters(in: .whitespacesAndNewlines)

            var words: [String] = []
            var firstWordIndex = 0
            var lastWordIndex = -1

            for token in PrompterTextTokenizer.tokens(from: text) {
                guard case .word(let index) = token.kind else { continue }
                guard let (range, word) = PrompterTextTokenizer.wordRange(at: index, in: text) else { continue }

                let wordRange = NSRange(range, in: text)
                if wordRange.location >= charRange.location + charRange.length {
                    break
                }
                if wordRange.location + wordRange.length <= charRange.location {
                    continue
                }
                guard NSIntersectionRange(wordRange, charRange).length > 0 else { continue }

                words.append(word)
                if lastWordIndex < 0 {
                    firstWordIndex = index
                }
                lastWordIndex = index
            }

            let resolvedLast = max(firstWordIndex, lastWordIndex)
            lines.append(
                PrompterLine(
                    index: lineIndex,
                    text: lineText,
                    words: words,
                    firstWordIndex: firstWordIndex,
                    lastWordIndex: resolvedLast,
                    yOffset: usedRect.origin.y,
                    height: usedRect.height
                )
            )
            lineIndex += 1
        }

        _ = textContainer
        return lines
    }

    static func activeLineIndex(
        at scrollOffset: CGFloat,
        viewportHeight: CGFloat,
        lines: [PrompterLine]
    ) -> Int {
        guard !lines.isEmpty else { return 0 }
        let readingY = scrollOffset + viewportHeight * readingLineRatio - PrompterTextMetrics.topPadding

        var active = 0
        for line in lines where line.yOffset <= readingY + line.height * 0.4 {
            active = line.index
        }
        return active
    }

    static func scrollOffset(for line: PrompterLine, viewportHeight: CGFloat) -> CGFloat {
        max(0, line.yOffset + PrompterTextMetrics.topPadding - viewportHeight * readingLineRatio)
    }

    static func wordIndex(
        at viewPoint: CGPoint,
        text: String,
        fontSize: Double,
        containerWidth: CGFloat,
        scrollOffset: CGFloat,
        topChromeInset: CGFloat = 0
    ) -> Int? {
        guard !text.isEmpty else { return nil }

        let textPoint = PrompterTextMetrics.viewPointToTextPoint(
            viewPoint,
            scrollOffset: scrollOffset,
            topChromeInset: topChromeInset
        )
        let lines = computeLines(text: text, fontSize: fontSize, containerWidth: containerWidth)
        guard !lines.isEmpty else { return nil }

        let targetLine = line(containingTextY: textPoint.y, in: lines)
        let (_, layoutManager, textContainer) = PrompterTextMetrics.makeTextKitStack(
            text: text,
            fontSize: fontSize,
            containerWidth: containerWidth
        )

        var directHit: Int?
        var nearestIndex: Int?
        var nearestDistance = CGFloat.greatestFiniteMagnitude
        let horizontalSlop: CGFloat = 8
        let verticalSlop: CGFloat = 6

        for token in PrompterTextTokenizer.tokens(from: text) {
            guard case .word(let index) = token.kind else { continue }
            guard index >= targetLine.firstWordIndex, index <= targetLine.lastWordIndex else { continue }
            guard let (range, _) = PrompterTextTokenizer.wordRange(at: index, in: text) else { continue }

            let nsRange = NSRange(range, in: text)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
            guard glyphRange.length > 0 else { continue }

            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let hitRect = rect.insetBy(dx: -horizontalSlop, dy: -verticalSlop)
            if hitRect.contains(textPoint) {
                directHit = index
                break
            }

            let center = CGPoint(x: rect.midX, y: rect.midY)
            let distance = hypot(center.x - textPoint.x, center.y - textPoint.y)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }

        if let directHit {
            return directHit
        }

        let lineHeight = max(targetLine.height, PrompterTextMetrics.font(size: fontSize).boundingRectForFont.height)
        if let nearestIndex, nearestDistance <= lineHeight * 1.5 {
            return nearestIndex
        }

        if let fallback = wordIndexByLinePosition(
            textPoint: textPoint,
            line: targetLine,
            layoutManager: layoutManager,
            textContainer: textContainer,
            text: text
        ) {
            return fallback
        }

        return wordIndexAnywhere(
            at: textPoint,
            text: text,
            fontSize: fontSize,
            layoutManager: layoutManager,
            textContainer: textContainer
        )
    }

    private static func wordIndexAnywhere(
        at textPoint: CGPoint,
        text: String,
        fontSize: Double,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer
    ) -> Int? {
        var nearestIndex: Int?
        var nearestDistance = CGFloat.greatestFiniteMagnitude

        for token in PrompterTextTokenizer.tokens(from: text) {
            guard case .word(let index) = token.kind else { continue }
            guard let (range, _) = PrompterTextTokenizer.wordRange(at: index, in: text) else { continue }

            let nsRange = NSRange(range, in: text)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
            guard glyphRange.length > 0 else { continue }

            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let distance = hypot(center.x - textPoint.x, center.y - textPoint.y)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }

        let lineHeight = PrompterTextMetrics.font(size: fontSize).boundingRectForFont.height
        if let nearestIndex, nearestDistance <= lineHeight * 2 {
            return nearestIndex
        }
        return nil
    }

    private static func line(containingTextY y: CGFloat, in lines: [PrompterLine]) -> PrompterLine {
        if let match = lines.first(where: { y >= $0.yOffset - 6 && y <= $0.yOffset + $0.height + 6 }) {
            return match
        }
        return lines.min {
            abs(($0.yOffset + $0.height / 2) - y) < abs(($1.yOffset + $1.height / 2) - y)
        } ?? lines[0]
    }

    /// Fallback when glyph rects are unavailable or the click is slightly off.
    private static func wordIndexByLinePosition(
        textPoint: CGPoint,
        line: PrompterLine,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        text: String
    ) -> Int? {
        guard !line.words.isEmpty else { return nil }

        var bestIndex: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for wordOffset in 0..<line.words.count {
            let index = line.firstWordIndex + wordOffset
            guard let (range, _) = PrompterTextTokenizer.wordRange(at: index, in: text) else { continue }
            let nsRange = NSRange(range, in: text)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
            guard glyphRange.length > 0 else { continue }

            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let distance = abs(rect.midX - textPoint.x)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        return bestIndex
    }
}
