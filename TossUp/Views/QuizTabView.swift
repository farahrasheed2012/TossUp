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
                QuizSetupView(viewModel: viewModel, bank: bank) {
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

    private var sessionSubjects: [Subject] {
        var subjects = Set<Subject>()
        for id in viewModel.selectedTopicIDs {
            if let topic = TopicCatalog.topic(id: id) {
                subjects.insert(topic.subject)
            }
        }
        subjects.formUnion(viewModel.selectedSimpleSubjects)
        return Array(subjects).sorted { $0.rawValue < $1.rawValue }
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
            subjects: sessionSubjects,
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
    @ObservedObject var bank: QuestionBank
    let onStart: () -> Void

    private var availableCount: Int {
        bank.questions(
            matchingTopicIDs: viewModel.selectedTopicIDs,
            otherSubjects: viewModel.selectedSimpleSubjects
        ).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                EncouragingHeader(name: SettingsStore.shared.studentName)
                    .cardStyle()

                SectionCard(title: "Topics") {
                    TopicPickerView(
                        selectedTopicIDs: $viewModel.selectedTopicIDs,
                        selectedSimpleSubjects: $viewModel.selectedSimpleSubjects,
                        bank: bank
                    )
                }

                SectionCard(title: "Session") {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Length")
                                .font(.subheadline.weight(.medium))
                            Picker("Questions", selection: $viewModel.quizLength) {
                                ForEach(QuizLength.allCases) { length in
                                    Text(length.label).tag(length)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Timer")
                                .font(.subheadline.weight(.medium))
                            Picker("Timer", selection: $viewModel.timerPreset) {
                                ForEach(TimerPreset.allCases) { preset in
                                    Text(preset.label).tag(preset)
                                }
                            }
                            #if os(macOS)
                            .pickerStyle(.menu)
                            #else
                            .pickerStyle(.segmented)
                            #endif
                        }

                        Text("\(availableCount) questions available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(action: onStart) {
                    Text("Start Quiz")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(availableCount == 0)
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
    }
}

struct QuizSummaryView: View {
    @ObservedObject var viewModel: QuizViewModel
    @ObservedObject private var settings = SettingsStore.shared
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
                if summary.skipped > 0 {
                    Text("\(summary.skipped) skipped")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.missedQuestions(in: bank).isEmpty {
                    SectionCard(title: "Review missed questions") {
                        VStack(spacing: 10) {
                            ForEach(viewModel.results.filter { !$0.wasCorrect }) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(item.question.questionText)
                                            .font(.subheadline)
                                        if item.wasSkipped {
                                            Text("Skipped")
                                                .font(.caption2.weight(.semibold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .clipShape(Capsule())
                                        }
                                    }
                                    if settings.showDetailedExplanations {
                                        AnswerFeedbackCard(
                                            feedback: AnswerExplainer.feedback(
                                                for: item.question,
                                                userAnswer: item.wasSkipped ? "" : item.userAnswer,
                                                wasCorrect: false,
                                                wasSkipped: item.wasSkipped
                                            ),
                                            showHeadline: false
                                        )
                                    } else {
                                        Text("Correct: \(item.question.correctAnswer)")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.accent)
                                    }
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
