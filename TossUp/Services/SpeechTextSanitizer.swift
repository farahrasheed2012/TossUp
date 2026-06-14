import Foundation

enum SpeechTextSanitizer {
    static func speakable(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "\n", with: " ")
        s = s.replacingOccurrences(of: "**", with: "")
        s = s.replacingOccurrences(of: "*", with: "")
        s = s.replacingOccurrences(of: "_", with: " ")
        s = s.replacingOccurrences(of: "×", with: " times ")
        s = s.replacingOccurrences(of: "÷", with: " divided by ")
        s = s.replacingOccurrences(of: "−", with: " minus ")
        s = s.replacingOccurrences(of: "°", with: " degrees ")
        s = s.replacingOccurrences(of: "²", with: " squared ")
        s = s.replacingOccurrences(of: "³", with: " cubed ")
        s = s.replacingOccurrences(of: "μ", with: " micro ")
        s = s.replacingOccurrences(of: "Ω", with: " ohms ")
        s = s.replacingOccurrences(of: "→", with: " to ")
        s = s.replacingOccurrences(of: "≈", with: " approximately ")
        s = s.replacingOccurrences(of: "≤", with: " less than or equal to ")
        s = s.replacingOccurrences(of: "≥", with: " greater than or equal to ")
        s = s.replacingOccurrences(
            of: #"([A-Z][a-z]?)(\d+)"#,
            with: "$1 $2",
            options: .regularExpression
        )
        s = s.replacingOccurrences(
            of: #"\^(\d+)"#,
            with: " times ten to the $1 ",
            options: .regularExpression
        )
        while s.contains("  ") {
            s = s.replacingOccurrences(of: "  ", with: " ")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
