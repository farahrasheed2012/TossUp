import Foundation

enum AnswerNormalizer {
    private static let articles: Set<String> = ["A", "AN", "THE"]

    static func normalize(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: #"[^\w\s\-\+\(\)\./]"#, with: "", options: .regularExpression)

        let words = text.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return "" }

        if words.count > 1, articles.contains(words[0]) {
            return words.dropFirst().joined(separator: " ")
        }
        return words.joined(separator: " ")
    }

    static func matches(user: String, correct: String) -> Bool {
        let left = normalize(user)
        let right = normalize(correct)
        guard !left.isEmpty, !right.isEmpty else { return false }
        if left == right { return true }

        // Accept MC letter only when correct answer is a single letter.
        if right.count == 1, right.first?.isLetter == true, left == right {
            return true
        }

        // Allow numeric tolerance for simple fractions/decimals.
        if let a = Double(left.replacingOccurrences(of: " ", with: "")),
           let b = Double(right.replacingOccurrences(of: " ", with: "")),
           abs(a - b) < 0.001 {
            return true
        }

        return false
    }
}

#if DEBUG
extension AnswerNormalizer {
    static func debugNormalize(_ raw: String) -> String {
        normalize(raw)
    }
}
#endif
