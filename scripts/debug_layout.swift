import AppKit

let text = "Hello world from test"
let fontSize = 18.0
let width = 520.0
let (_, lm, tc) = PrompterTextMetrics.makeTextKitStack(text: text, fontSize: fontSize, containerWidth: width)
let gr = lm.glyphRange(forCharacterRange: NSRange(location: 0, length: 5), actualCharacterRange: nil)
print("glyphs", lm.numberOfGlyphs, "gr", gr)
print("rect0", lm.boundingRect(forGlyphRange: gr, in: tc))
var pt = CGPoint.zero
var frac: CGFloat = 0
let idx = lm.glyphIndex(for: CGPoint(x: 50, y: 5), in: tc, fractionOfDistanceThroughGlyph: &frac)
print("glyph at 50,5", idx)
