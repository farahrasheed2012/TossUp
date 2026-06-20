import Foundation
import SwiftUI

enum QuizPhase: Equatable {
    case setup
    case inProgress
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
    @Published var selectedTopicIDs: Set<String> = []
    @Published var selectedSimpleSubjects: Set<Subject> = []
    @Published var quizLength: QuizLength = SettingsStore.shared.defaultQuizLength
    @Published var timerPreset: TimerPreset = SettingsStore.shared.timerPreset

    @Published private(set) var sessionQuestions: [NSBQuestion] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var results: [QuizResultItem] = []
    @Published private(set) var drillState: DrillScreenState = .countdown
    @Published private(set) var arcProgress: CGFloat = 1.0
    @Published private(set) var countdownText = "3"
    @Published private(set) var liveCorrect = 0
    @Published private(set) var liveMissed = 0
    @Published var flashColor: Color?
    @Published var showXPFloater = false

    private var questionStartedAt = Date()
    private var arcTimer = ArcCountdownTimer()
    private var transitionTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var xpAtSessionStart = 0

    var currentQuestion: NSBQuestion? {
        guard currentIndex < sessionQuestions.count else { return nil }
        return sessionQuestions[currentIndex]
    }

    var progressLabel: String {
        guard !sessionQuestions.isEmpty else { return "0 / 0" }
        return "Question \(currentIndex + 1) of \(sessionQuestions.count)"
    }

    var scoreSummary: (correct: Int, total: Int, skipped: Int, percent: Double) {
        let correct = results.filter(\.wasCorrect).count
        let skipped = results.filter(\.wasSkipped).count
        let total = results.count
        let percent = total == 0 ? 0 : Double(correct) / Double(total)
        return (correct, total, skipped, percent)
    }

    var sessionXpEarned: Int {
        max(0, XPManager.shared.totalXP - xpAtSessionStart)
    }

    func subjectBreakdown() -> [(name: String, correct: Int, total: Int, color: Color)] {
        var totals: [Subject: (correct: Int, total: Int)] = [:]
        for item in results {
            var entry = totals[item.question.subject] ?? (0, 0)
            entry.total += 1
            if item.wasCorrect { entry.correct += 1 }
            totals[item.question.subject] = entry
        }
        return totals.keys.sorted { $0.rawValue < $1.rawValue }.map { subject in
            let entry = totals[subject]!
            return (subject.displayName, entry.correct, entry.total, subject.gameColor)
        }
    }

    func startSession(from bank: QuestionBank) {
        cancelTasks()
        let pool = bank.questions(
            matchingTopicIDs: selectedTopicIDs,
            otherSubjects: selectedSimpleSubjects
        )
        guard !pool.isEmpty else { return }

        let count: Int
        switch quizLength {
        case .all: count = pool.count
        default: count = min(quizLength.rawValue, pool.count)
        }

        sessionQuestions = Array(pool.shuffled().prefix(count))
        currentIndex = 0
        results = []
        liveCorrect = 0
        liveMissed = 0
        phase = .inProgress
        xpAtSessionStart = XPManager.shared.totalXP
        startCountdownSequence()
    }

    func buzz() {
        guard phase == .inProgress, drillState == .questionLive else { return }
        arcTimer.cancel()
        drillState = .buzzed
        HapticManager.medium()
    }

    func revealAnswer() {
        guard phase == .inProgress, drillState == .buzzed else { return }
        withAnimation(.spring(response: 0.4)) {
            drillState = .revealed
        }
    }

    func logCorrect() {
        logOutcome(correct: true)
    }

    func logMissed() {
        logOutcome(correct: false)
    }

    func skipQuestion() {
        guard phase == .inProgress, let question = currentQuestion else { return }
        SpeechManager.shared.stop()
        arcTimer.cancel()
        recordResult(for: question, correct: false, skipped: true)
        liveMissed += 1
        triggerFlash(GameColors.incorrect)
        HapticManager.error()
        beginTransition()
    }

    func endSessionEarly() {
        cancelTasks()
        SpeechManager.shared.stop()
        phase = .summary
    }

    func restartSetup() {
        cancelTasks()
        phase = .setup
        sessionQuestions = []
        currentIndex = 0
        results = []
        drillState = .countdown
    }

    func missedQuestions(in bank: QuestionBank) -> [NSBQuestion] {
        results.filter { !$0.wasCorrect }.compactMap { bank.question(withID: $0.question.id) }
    }

    func startQuestionTimerAfterReadAloud() {
        guard phase == .inProgress, drillState == .questionLive else { return }
        startArcTimer()
    }

    // MARK: - Private

    private func startCountdownSequence() {
        drillState = .countdown
        let sequence = ["3", "2", "1", "Go!"]
        countdownTask?.cancel()
        countdownTask = Task {
            for (index, label) in sequence.enumerated() {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    countdownText = label
                    HapticManager.rigid()
                }
                let delay: UInt64 = label == "Go!" ? 600_000_000 : 800_000_000
                try? await Task.sleep(nanoseconds: delay)
                if index == sequence.count - 1 {
                    await MainActor.run { beginQuestionLive() }
                }
            }
        }
    }

    private func beginQuestionLive() {
        guard phase == .inProgress else { return }
        questionStartedAt = Date()
        arcProgress = 1.0
        drillState = .questionLive
        if !SettingsStore.shared.readQuestionsAloud {
            startArcTimer()
        }
    }

    private func startArcTimer() {
        guard let question = currentQuestion else { return }
        guard let seconds = timerPreset.seconds(for: question.type), seconds > 0 else {
            arcProgress = 1
            return
        }
        arcTimer.start(duration: TimeInterval(seconds), onProgress: { [weak self] progress in
            self?.arcProgress = progress
        }, onExpired: { [weak self] in
            self?.handleTimeExpired()
        })
    }

    private func handleTimeExpired() {
        guard drillState == .questionLive, let question = currentQuestion else { return }
        recordResult(for: question, correct: false, skipped: false)
        liveMissed += 1
        triggerFlash(GameColors.incorrect)
        HapticManager.error()
        withAnimation { drillState = .revealed }
        beginTransition(after: 1.2)
    }

    private func logOutcome(correct: Bool) {
        guard drillState == .revealed, let question = currentQuestion else { return }
        recordResult(for: question, correct: correct, skipped: false)
        if correct {
            liveCorrect += 1
            _ = XPManager.shared.award(.tossupCorrect)
            triggerFlash(GameColors.correct)
            HapticManager.success()
            showXPFloater = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.showXPFloater = false
            }
        } else {
            liveMissed += 1
            triggerFlash(GameColors.incorrect)
            HapticManager.error()
        }
        beginTransition()
    }

    private func recordResult(for question: NSBQuestion, correct: Bool, skipped: Bool) {
        let elapsed = Date().timeIntervalSince(questionStartedAt)
        results.append(
            QuizResultItem(
                id: UUID(),
                question: question,
                userAnswer: skipped ? "(skipped)" : (correct ? question.correctAnswer : "(self-reported miss)"),
                wasCorrect: correct,
                wasSkipped: skipped,
                timeToAnswer: elapsed
            )
        )
    }

    private func beginTransition(after delay: TimeInterval = 0.8) {
        drillState = .transitioning
        transitionTask?.cancel()
        transitionTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.advanceQuestion() }
        }
    }

    private func advanceQuestion() {
        arcTimer.cancel()
        flashColor = nil
        if currentIndex + 1 >= sessionQuestions.count {
            phase = .summary
        } else {
            currentIndex += 1
            beginQuestionLive()
        }
    }

    private func triggerFlash(_ color: Color) {
        withAnimation(.easeOut(duration: 0.15)) { flashColor = color }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            withAnimation { self?.flashColor = nil }
        }
    }

    private func cancelTasks() {
        arcTimer.cancel()
        transitionTask?.cancel()
        countdownTask?.cancel()
        SpeechManager.shared.stop()
    }
}
