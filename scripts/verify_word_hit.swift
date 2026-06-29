import AppKit
import Foundation

@main
enum VerifyWordHit {
    static func main() {
        _ = NSApplication.shared

        let sample = "Hello world from the teleprompter test line"
        let fontSize: Double = 18
        let width: CGFloat = 520
        let scrollOffset: CGFloat = 0

        let (_, layoutManager, textContainer) = PrompterTextMetrics.makeTextKitStack(
            text: sample,
            fontSize: fontSize,
            containerWidth: width
        )
        guard layoutManager.numberOfGlyphs > 0 else {
            print("FAIL: TextKit produced zero glyphs")
            exit(1)
        }

        var failures = 0

        for token in PrompterTextTokenizer.tokens(from: sample) {
            guard case .word(let index) = token.kind else { continue }
            guard let (range, _) = PrompterTextTokenizer.wordRange(at: index, in: sample) else {
                print("FAIL: missing range for word \(index)")
                failures += 1
                continue
            }
            let nsRange = NSRange(range, in: sample)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: nsRange, actualCharacterRange: nil)
            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let center = CGPoint(
                x: rect.midX + PrompterTextMetrics.horizontalPadding,
                y: rect.midY + PrompterTextMetrics.topPadding
            )

            guard let hit = PrompterLineLayout.wordIndex(
                at: center,
                text: sample,
                fontSize: fontSize,
                containerWidth: width,
                scrollOffset: scrollOffset
            ) else {
                print("FAIL: no hit for word \(index) '\(token.text)' at \(center)")
                failures += 1
                continue
            }

            if hit != index {
                print("FAIL: word \(index) center hit word \(hit)")
                failures += 1
            } else {
                print("OK: word \(index) '\(token.text)'")
            }
        }

        if failures == 0 {
            print("ALL HIT TESTS PASSED")
        } else {
            print("\(failures) FAILURES")
            exit(1)
        }
    }
}
