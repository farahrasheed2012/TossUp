import Foundation
import SwiftData

@Model
final class QuizSessionRecord {
    var id: UUID
    var date: Date
    var subjectsRaw: String
    var totalQuestions: Int
    var correctCount: Int

    @Relationship(deleteRule: .cascade, inverse: \QuestionAttemptRecord.session)
    var attempts: [QuestionAttemptRecord]

    init(
        id: UUID = UUID(),
        date: Date = .now,
        subjects: [Subject],
        totalQuestions: Int,
        correctCount: Int,
        attempts: [QuestionAttemptRecord] = []
    ) {
        self.id = id
        self.date = date
        self.subjectsRaw = subjects.map(\.rawValue).joined(separator: ",")
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.attempts = attempts
    }

    var subjects: [Subject] {
        subjectsRaw.split(separator: ",").compactMap { Subject(rawValue: String($0)) }
    }

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctCount) / Double(totalQuestions)
    }
}

@Model
final class QuestionAttemptRecord {
    var id: UUID
    var questionID: UUID
    var wasCorrect: Bool
    var timeToAnswer: Double
    var session: QuizSessionRecord?

    init(
        id: UUID = UUID(),
        questionID: UUID,
        wasCorrect: Bool,
        timeToAnswer: Double,
        session: QuizSessionRecord? = nil
    ) {
        self.id = id
        self.questionID = questionID
        self.wasCorrect = wasCorrect
        self.timeToAnswer = timeToAnswer
        self.session = session
    }
}
