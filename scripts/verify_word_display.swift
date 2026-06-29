import Foundation

@main
enum VerifyWordDisplay {
    static func main() {
        var failures = 0

        func expect(_ word: String, emphasized: Bool, equals expected: String, label: String) {
            let actual = PrompterWordDisplay.text(for: word, emphasized: emphasized)
            if actual != expected {
                print("FAIL \(label): got '\(actual)' expected '\(expected)'")
                failures += 1
            } else {
                print("OK \(label)")
            }
        }

        expect("hello", emphasized: true, equals: "HELLO", label: "normal emphasized")
        expect("hello", emphasized: false, equals: "hello", label: "normal plain")
        expect("HELLO", emphasized: true, equals: "HELLO", label: "all caps emphasized")
        expect("HELLO", emphasized: false, equals: "hello", label: "all caps plain")
        expect("Wi-Fi", emphasized: false, equals: "Wi-Fi", label: "mixed case preserved")

        if failures == 0 {
            print("ALL DISPLAY TESTS PASSED")
        } else {
            print("\(failures) FAILURES")
            exit(1)
        }
    }
}
