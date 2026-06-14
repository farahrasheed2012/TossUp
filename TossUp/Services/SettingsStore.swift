import Foundation
import SwiftData
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @AppStorage("timerPreset") var timerPresetRaw: Int = TimerPreset.officialMC.rawValue
    @AppStorage("defaultQuizLength") var defaultQuizLengthRaw: Int = QuizLength.ten.rawValue
    @AppStorage("enabledSubjects") private var enabledSubjectsRaw: String = Subject.allCases.map(\.rawValue).joined(separator: ",")
    @AppStorage("autoAdvanceDelay") var autoAdvanceDelay: Double = 1.5
    @AppStorage("studentName") var studentName: String = "Soha"
    @AppStorage("readQuestionsAloud") var readQuestionsAloud: Bool = true

    var timerPreset: TimerPreset {
        get { TimerPreset(rawValue: timerPresetRaw) ?? .officialMC }
        set { timerPresetRaw = newValue.rawValue }
    }

    var defaultQuizLength: QuizLength {
        get { QuizLength(rawValue: defaultQuizLengthRaw) ?? .ten }
        set { defaultQuizLengthRaw = newValue.rawValue }
    }

    var enabledSubjects: Set<Subject> {
        get {
            let values = enabledSubjectsRaw.split(separator: ",").compactMap { Subject(rawValue: String($0)) }
            return Set(values.isEmpty ? Subject.allCases : values)
        }
        set {
            enabledSubjectsRaw = newValue.map(\.rawValue).sorted().joined(separator: ",")
        }
    }

    func isSubjectEnabled(_ subject: Subject) -> Bool {
        enabledSubjects.contains(subject)
    }

    func toggleSubject(_ subject: Subject) {
        var current = enabledSubjects
        if current.contains(subject) {
            current.remove(subject)
        } else {
            current.insert(subject)
        }
        enabledSubjects = current.isEmpty ? Set(Subject.allCases) : current
    }

    func resetProgress(modelContext: ModelContext?) {
        guard let modelContext else { return }
        do {
            try modelContext.delete(model: QuizSessionRecord.self)
            try modelContext.delete(model: QuestionAttemptRecord.self)
            try modelContext.save()
        } catch {
            print("Failed to reset progress: \(error)")
        }
    }
}
