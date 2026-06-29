import Foundation

struct PrompterWordToken: Identifiable, Equatable {
    enum Kind: Equatable {
        case word(index: Int)
        case whitespace(String)
    }

    let kind: Kind
    let text: String

    var id: String {
        switch kind {
        case .word(let index):
            return "word-\(index)"
        case .whitespace(let value):
            return "ws-\(value.hashValue)-\(text.hashValue)"
        }
    }
}

enum PrompterTextTokenizer {
    static func tokens(from text: String) -> [PrompterWordToken] {
        guard !text.isEmpty else { return [] }

        var result: [PrompterWordToken] = []
        var wordIndex = 0
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if character.isWhitespace {
                var whitespace = String(character)
                let next = text.index(after: index)
                var cursor = next
                while cursor < text.endIndex, text[cursor].isWhitespace {
                    whitespace.append(text[cursor])
                    cursor = text.index(after: cursor)
                }
                result.append(PrompterWordToken(kind: .whitespace(whitespace), text: whitespace))
                index = cursor
            } else {
                var word = String(character)
                let next = text.index(after: index)
                var cursor = next
                while cursor < text.endIndex, !text[cursor].isWhitespace {
                    word.append(text[cursor])
                    cursor = text.index(after: cursor)
                }
                result.append(PrompterWordToken(kind: .word(index: wordIndex), text: word))
                wordIndex += 1
                index = cursor
            }
        }

        return result
    }

    static func normalizedWords(from text: String) -> [String] {
        tokens(from: text).compactMap { token in
            guard case .word = token.kind else { return nil }
            return normalizeWord(token.text)
        }
    }

    static func normalizeWord(_ word: String) -> String {
        word.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    static func wordRange(at wordIndex: Int, in text: String) -> (range: Range<String.Index>, word: String)? {
        var current = 0
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if character.isWhitespace {
                let next = text.index(after: index)
                var cursor = next
                while cursor < text.endIndex, text[cursor].isWhitespace {
                    cursor = text.index(after: cursor)
                }
                index = cursor
            } else {
                let start = index
                var cursor = text.index(after: index)
                while cursor < text.endIndex, !text[cursor].isWhitespace {
                    cursor = text.index(after: cursor)
                }
                let end = cursor
                if current == wordIndex {
                    return (start..<end, String(text[start..<end]))
                }
                current += 1
                index = cursor
            }
        }

        return nil
    }

    static func isAllCapsWord(_ word: String) -> Bool {
        let letters = word.filter(\.isLetter)
        guard !letters.isEmpty else { return false }
        return letters.allSatisfy(\.isUppercase)
    }

    /// UTF-16 code unit range for Google Slides API text ranges.
    static func utf16CodeUnitRange(at wordIndex: Int, in text: String) -> (start: Int, end: Int)? {
        guard let (range, _) = wordRange(at: wordIndex, in: text) else { return nil }
        let nsRange = NSRange(range, in: text)
        return (nsRange.location, nsRange.location + nsRange.length)
    }
}
