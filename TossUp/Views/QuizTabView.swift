import SwiftUI
import SwiftData

struct QuizTabView: View {
    @EnvironmentObject private var bank: QuestionBank
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = QuizViewModel()

    var body: some View {
        Group {
            switch viewModel.phase {
            case .setup:
                QuizSetupView(viewModel: viewModel, questionCount: bank.questions.count) {
                    viewModel.startSession(from: bank)
                }
            case .inProgress, .feedback:
                QuizSessionView(viewModel: viewModel)
            case .summary:
                QuizSummaryView(viewModel: viewModel, bank: bank) {
                    persistSession()
                    viewModel.restartSetup()
                }
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Quiz")
    }

    private func persistSession() {
        let summary = viewModel.scoreSummary
        let attempts = viewModel.results.map { result in
            QuestionAttemptRecord(
                questionID: result.question.id,
                wasCorrect: result.wasCorrect,
                timeToAnswer: result.timeToAnswer
            )
        }
        let session = QuizSessionRecord(
            subjects: Array(viewModel.selectedSubjects),
            totalQuestions: summary.total,
            correctCount: summary.correct,
            attempts: attempts
        )
        for attempt in attempts {
            attempt.session = session
        }
        modelContext.insert(session)
        try? modelContext.save()
    }
}

struct QuizSetupView: View {
    @ObservedObject var viewModel: QuizViewModel
    let questionCount: Int
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                EncouragingHeader(name: SettingsStore.shared.studentName)
                    .cardStyle()

                SectionCard(title: "Subjects") {
                    VStack(spacing: 8) {
                        ForEach(Subject.allCases) { subject in
                            Toggle(isOn: binding(for: subject)) {
                                HStack(spacing: 8) {
                                    Text(subject.emoji)
                                    Text(subject.displayName)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                    }
                }

                SectionCard(title: "Session size") {
                    Picker("Questions", selection: $viewModel.quizLength) {
                        ForEach(QuizLength.allCases) { length in
                            Text(length.label).tag(length)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("\(questionCount) questions loaded from PDFs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SectionCard(title: "Time per question") {
                    Picker("Timer", selection: $viewModel.timerPreset) {
                        ForEach(TimerPreset.allCases) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    #if os(macOS)
                    .pickerStyle(.menu)
                    #endif
                }

                Button(action: onStart) {
                    Text("Start Quiz")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.selectedSubjects.isEmpty || questionCount == 0)
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
    }

    private func binding(for subject: Subject) -> Binding<Bool> {
        Binding(
            get: { viewModel.selectedSubjects.contains(subject) },
            set: { enabled in
                if enabled {
                    viewModel.selectedSubjects.insert(subject)
                } else {
                    viewModel.selectedSubjects.remove(subject)
                }
            }
        )
    }
}

struct QuizSummaryView: View {
    @ObservedObject var viewModel: QuizViewModel
    let bank: QuestionBank
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Session Complete!")
                    .font(.largeTitle.bold())

                AccuracyRingView(progress: viewModel.scoreSummary.percent, label: "Accuracy")

                let summary = viewModel.scoreSummary
                Text("\(summary.correct) of \(summary.total) correct")
                    .font(.title3)

                if !viewModel.missedQuestions(in: bank).isEmpty {
                    SectionCard(title: "Review missed questions") {
                        VStack(spacing: 10) {
                            ForEach(viewModel.results.filter { !$0.wasCorrect }) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.question.questionText)
                                        .font(.subheadline)
                                    Text("Correct: \(item.question.correctAnswer)")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                Button("New Session", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
    }
}
