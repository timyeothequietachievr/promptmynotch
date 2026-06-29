import Foundation

enum PrompterWordDisplay {
    /// Prompter rendering for a word token, given whether small-caps emphasis is enabled.
    static func text(for word: String, emphasized: Bool) -> String {
        if emphasized {
            return word.uppercased()
        }
        return word
    }
}
