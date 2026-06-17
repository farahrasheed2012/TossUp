import Foundation

struct AnswerFeedback {
    let wasCorrect: Bool
    let headline: String
    let correctAnswerDisplay: String
    let userAnswerDisplay: String?
    let explanation: String
    let distractorNotes: [String]
}

enum AnswerExplainer {

    static func feedback(for question: NSBQuestion, userAnswer: String, wasCorrect: Bool, wasSkipped: Bool = false) -> AnswerFeedback {
        switch question.type {
        case .multipleChoice:
            return multipleChoiceFeedback(for: question, userAnswer: userAnswer, wasCorrect: wasCorrect, wasSkipped: wasSkipped)
        case .shortAnswer:
            return shortAnswerFeedback(for: question, userAnswer: userAnswer, wasCorrect: wasCorrect, wasSkipped: wasSkipped)
        }
    }

    static func explanationOnly(for question: NSBQuestion) -> String {
        AIStyleExplainer.longExplanation(for: question, userAnswer: question.correctAnswer, wasCorrect: true)
    }

    static func displayCorrectAnswer(for question: NSBQuestion) -> String {
        if question.type == .multipleChoice, let choices = question.choices {
            let letter = question.correctAnswer.uppercased()
            let body = choiceBody(for: letter, in: choices)
            return body.isEmpty ? letter : "\(letter)) \(body)"
        }
        return question.correctAnswer
    }

    // MARK: - Multiple choice

    private static func multipleChoiceFeedback(
        for question: NSBQuestion,
        userAnswer: String,
        wasCorrect: Bool,
        wasSkipped: Bool
    ) -> AnswerFeedback {
        let choices = question.choices ?? []
        let correctLetter = question.correctAnswer.uppercased()
        let correctText = choiceBody(for: correctLetter, in: choices)
        let correctDisplay = formattedChoice(letter: correctLetter, body: correctText)

        let userLetter = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let userText = choiceBody(for: userLetter, in: choices)
        let userDisplay: String? = {
            guard !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !userLetter.isEmpty else { return nil }
            if userLetter == correctLetter, wasCorrect { return nil }
            return formattedChoice(letter: userLetter, body: userText)
        }()

        return AnswerFeedback(
            wasCorrect: wasCorrect,
            headline: headline(wasCorrect: wasCorrect, wasSkipped: wasSkipped),
            correctAnswerDisplay: correctDisplay,
            userAnswerDisplay: userDisplay,
            explanation: AIStyleExplainer.longExplanation(
                for: question,
                userAnswer: userAnswer,
                wasCorrect: wasCorrect,
                wasSkipped: wasSkipped
            ),
            distractorNotes: AIStyleExplainer.allDistractorNotes(for: question, correctLetter: correctLetter)
        )
    }

    // MARK: - Short answer

    private static func shortAnswerFeedback(
        for question: NSBQuestion,
        userAnswer: String,
        wasCorrect: Bool,
        wasSkipped: Bool
    ) -> AnswerFeedback {
        let trimmedUser = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let userDisplay: String? = wasCorrect || trimmedUser.isEmpty ? nil : trimmedUser

        return AnswerFeedback(
            wasCorrect: wasCorrect,
            headline: headline(wasCorrect: wasCorrect, wasSkipped: wasSkipped),
            correctAnswerDisplay: question.correctAnswer,
            userAnswerDisplay: userDisplay,
            explanation: AIStyleExplainer.longExplanation(
                for: question,
                userAnswer: userAnswer,
                wasCorrect: wasCorrect,
                wasSkipped: wasSkipped
            ),
            distractorNotes: []
        )
    }

    // MARK: - Helpers

    private static func headline(wasCorrect: Bool, wasSkipped: Bool) -> String {
        if wasSkipped { return "Skipped" }
        return wasCorrect ? "Correct!" : "Not quite"
    }

    private static func choiceBody(for letter: String, in choices: [String]) -> String {
        guard let match = choices.first(where: { $0.uppercased().hasPrefix("\(letter))") }) else { return "" }
        if let idx = match.firstIndex(of: ")") {
            return String(match[match.index(after: idx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return match
    }

    private static func formattedChoice(letter: String, body: String) -> String {
        body.isEmpty ? letter : "\(letter)) \(body)"
    }
}
