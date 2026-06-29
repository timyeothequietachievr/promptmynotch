import AppKit
import Foundation

@main
enum VerifyKeynoteHit {
    static func main() {
        _ = NSApplication.shared

        let slide27 = """
        Ezra Coaching - Keynote speech for COACH Fest. 
        4000+ coaches worldwide
        I was asked to come speak about introverted leadership because there were coaches who were giving advice that sounded like “introversion is a weakness” and they wanted an alternative view
        """

        let fontSize: Double = 18
        let width: CGFloat = 560
        let scrollOffset: CGFloat = 0

        let lines = PrompterLineLayout.computeLines(text: slide27, fontSize: fontSize, containerWidth: width)
        guard let firstLine = lines.first else {
            print("FAIL: no lines")
            exit(1)
        }

        guard firstLine.words.contains("Keynote") else {
            print("FAIL: first line missing Keynote:", firstLine.words)
            exit(1)
        }

        guard firstLine.lastWordIndex >= 3 else {
            print("FAIL: first line lastWordIndex \(firstLine.lastWordIndex) < 3 (Keynote tokenizer index)")
            exit(1)
        }

        let (_, layoutManager, textContainer) = PrompterTextMetrics.makeTextKitStack(
            text: slide27,
            fontSize: fontSize,
            containerWidth: width
        )
        guard layoutManager.numberOfGlyphs > 0 else {
            print("FAIL: zero glyphs")
            exit(1)
        }

        guard let (range, _) = PrompterTextTokenizer.wordRange(at: 3, in: slide27) else {
            print("FAIL: no tokenizer range for Keynote")
            exit(1)
        }

        let nsRange = NSRange(range, in: slide27)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let clickPoint = CGPoint(
            x: rect.midX + PrompterTextMetrics.horizontalPadding,
            y: rect.midY + PrompterTextMetrics.topPadding
        )

        guard let hit = PrompterLineLayout.wordIndex(
            at: clickPoint,
            text: slide27,
            fontSize: fontSize,
            containerWidth: width,
            scrollOffset: scrollOffset
        ) else {
            print("FAIL: no hit at Keynote center \(clickPoint)")
            exit(1)
        }

        guard hit == 3 else {
            print("FAIL: hit index \(hit), expected 3 for Keynote")
            exit(1)
        }

        print("OK: Keynote hit at tokenizer index 3")
        print("OK: first line word range \(firstLine.firstWordIndex)...\(firstLine.lastWordIndex)")
    }
}
