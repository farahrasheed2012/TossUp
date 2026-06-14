import Foundation
import SwiftData

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var sessions: [QuizSessionRecord] = []
    @Published private(set) var overallAccuracy: Double = 0
    @Published private(set) var subjectAccuracy: [Subject: Double] = [:]
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var weakestSubject: Subject?

    func refresh(context: ModelContext) {
        let descriptor = FetchDescriptor<QuizSessionRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        sessions = (try? context.fetch(descriptor)) ?? []
        computeStats()
    }

    private func computeStats() {
        let totalAttempts = sessions.flatMap(\.attempts)
        guard !totalAttempts.isEmpty else {
            overallAccuracy = 0
            subjectAccuracy = [:]
            currentStreak = 0
            weakestSubject = nil
            return
        }

        let correct = totalAttempts.filter(\.wasCorrect).count
        overallAccuracy = Double(correct) / Double(totalAttempts.count)

        var bySubject: [Subject: (correct: Int, total: Int)] = [:]
        for session in sessions {
            for attempt in session.attempts {
                guard let question = QuestionBank.shared.question(withID: attempt.questionID) else { continue }
                var bucket = bySubject[question.subject, default: (0, 0)]
                bucket.total += 1
                if attempt.wasCorrect { bucket.correct += 1 }
                bySubject[question.subject] = bucket
            }
        }

        subjectAccuracy = bySubject.mapValues { Double($0.correct) / Double(max($0.total, 1)) }
        weakestSubject = subjectAccuracy.min(by: { $0.value < $1.value })?.key
        currentStreak = computeStreak()
    }

    private func computeStreak() -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        guard !uniqueDays.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: Date())

        if uniqueDays.first != cursor {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            if uniqueDays.first != cursor && uniqueDays.first != calendar.startOfDay(for: Date()) {
                return 0
            }
        }

        for day in uniqueDays {
            if day == cursor {
                streak += 1
                cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            } else if day < cursor {
                break
            }
        }
        return streak
    }
}
