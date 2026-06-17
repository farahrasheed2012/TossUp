import Foundation
import SwiftUI

enum QuizPhase: Equatable {
    case setup
    case inProgress
    case feedback
    case summary
}

struct QuizResultItem: Identifiable {
    let id: UUID
    let question: NSBQuestion
    let userAnswer: String
    let wasCorrect: Bool
    let wasSkipped: Bool
    let timeToAnswer: TimeInterval
}

@MainActor
final class QuizViewModel: ObservableObject {
    @Published var phase: QuizPhase = .setup
    @Published var selectedTopicIDs: Set<String> = TopicCatalog.normalizedTopicIDs([
        TopicCatalog.allTopicID(for: .chemistry),
        TopicCatalog.allTopicID(for: .biology),
        TopicCatalog.allTopicID(for: .math),
    ])
    @Published var selectedSimpleSubjects: Set<Subject> = []
    @Published var quizLength: QuizLength = SettingsStore.shared.defaultQuizLength
    @Published var timerPreset: TimerPreset = SettingsStore.shared.timerPreset

    @Published private(set) var sessionQuestions: [NSBQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var remainingSeconds: Int?
    @Published private(set) var results: [QuizResultItem] = []
    @Published private(set) var lastFeedbackCorrect = false
    @Published private(set) var lastCorrectAnswer = ""
    @Published private(set) var lastFeedback: AnswerFeedback?
    @Published private(set) var lastUserAnswer = ""
    @Published var shortAnswerText = ""

    private var questionStartedAt = Date()
    private var timerTask: Task<Void, Never>?

    var currentQuestion: NSBQuestion? {
        guard currentIndex < sessionQuestions.count else { return nil }
        return sessionQuestions[currentIndex]
    }

    var progressLabel: String {
        guard !sessionQuestions.isEmpty else { return "0 / 0" }
        return "\(currentIndex + 1) / \(sessionQuestions.count)"
    }

    var scoreSummary: (correct: Int, total: Int, skipped: Int, percent: Double) {
        let correct = results.filter(\.wasCorrect).count
        let skipped = results.filter(\.wasSkipped).count
        let total = results.count
        let percent = total == 0 ? 0 : Double(correct) / Double(total)
        return (correct, total, skipped, percent)
    }

    func startSession(from bank: QuestionBank) {
        timerTask?.cancel()
        let pool = bank.questions(
            matchingTopicIDs: selectedTopicIDs,
            otherSubjects: selectedSimpleSubjects
        )
        guard !pool.isEmpty else { return }

        let count: Int
        switch quizLength {
        case .all:
            count = pool.count
        default:
            count = min(quizLength.rawValue, pool.count)
        }

        sessionQuestions = Array(pool.shuffled().prefix(count))
        currentIndex = 0
        results = []
        phase = .inProgress
        shortAnswerText = ""
        prepareCurrentQuestion()
    }

    func submitMultipleChoice(_ letter: Character) {
        guard phase == .inProgress, let question = currentQuestion else { return }
        gradeAnswer(String(letter), for: question)
    }

    func submitShortAnswer() {
        guard phase == .inProgress, let question = currentQuestion else { return }
        gradeAnswer(shortAnswerText, for: question)
    }

    /// Skip the current question — counts as incorrect and shows the explanation.
    func skipQuestion() {
        guard phase == .inProgress, let question = currentQuestion else { return }
        SpeechManager.shared.stop()
        gradeAnswer("", for: question, skipped: true)
    }

    /// End the quiz early and jump to the session summary.
    func endSessionEarly() {
        timerTask?.cancel()
        SpeechManager.shared.stop()
        remainingSeconds = nil
        phase = .summary
    }

    func skipTimerAndSubmitEmpty() {
        guard phase == .inProgress, let question = currentQuestion else { return }
        gradeAnswer("", for: question)
    }

    func continueAfterFeedback() {
        guard phase == .feedback else { return }
        timerTask?.cancel()
        shortAnswerText = ""
        if currentIndex + 1 >= sessionQuestions.count {
            phase = .summary
        } else {
            currentIndex += 1
            phase = .inProgress
            prepareCurrentQuestion()
        }
    }

    /// Called after read-aloud finishes; starts the countdown if it has not begun yet.
    func startQuestionTimerAfterReadAloud() {
        guard phase == .inProgress, remainingSeconds == nil else { return }
        beginQuestionTimer()
    }

    private func prepareCurrentQuestion() {
        timerTask?.cancel()
        remainingSeconds = nil
        questionStartedAt = Date()
        if !SettingsStore.shared.readQuestionsAloud {
            beginQuestionTimer()
        }
    }

    func restartSetup() {
        timerTask?.cancel()
        phase = .setup
        sessionQuestions = []
        currentIndex = 0
        results = []
        shortAnswerText = ""
    }

    func missedQuestions(in bank: QuestionBank) -> [NSBQuestion] {
        results.filter { !$0.wasCorrect }.compactMap { bank.question(withID: $0.question.id) }
    }

    private func gradeAnswer(_ answer: String, for question: NSBQuestion, skipped: Bool = false) {
        timerTask?.cancel()
        SpeechManager.shared.stop()
        let elapsed = Date().timeIntervalSince(questionStartedAt)
        let correct = !skipped && AnswerNormalizer.matches(user: answer, correct: question.correctAnswer)
        lastFeedbackCorrect = correct
        lastCorrectAnswer = question.correctAnswer
        lastUserAnswer = skipped ? "" : answer
        lastFeedback = SettingsStore.shared.showDetailedExplanations
            ? AnswerExplainer.feedback(for: question, userAnswer: answer, wasCorrect: correct, wasSkipped: skipped)
            : nil
        results.append(
            QuizResultItem(
                id: UUID(),
                question: question,
                userAnswer: skipped ? "(skipped)" : answer,
                wasCorrect: correct,
                wasSkipped: skipped,
                timeToAnswer: elapsed
            )
        )
        phase = .feedback
        scheduleAutoAdvance()
    }

    private func beginQuestionTimer() {
        guard let question = currentQuestion else { return }
        remainingSeconds = timerPreset.seconds(for: question.type)
        timerTask?.cancel()
        guard let initial = remainingSeconds else { return }

        timerTask = Task {
            var seconds = initial
            while seconds > 0, !Task.isCancelled {
                remainingSeconds = seconds
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                seconds -= 1
            }
            if !Task.isCancelled {
                remainingSeconds = 0
                skipTimerAndSubmitEmpty()
            }
        }
    }

    private func scheduleAutoAdvance() {
        let delay = SettingsStore.shared.autoAdvanceDelay
        timerTask?.cancel()
        timerTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                continueAfterFeedback()
            }
        }
    }
}
