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
            case .inProgress, .summary:
                QuizSessionView(viewModel: viewModel) {
                    viewModel.restartSetup()
                }
            }
        }
        .onChange(of: viewModel.phase) { _, phase in
            if phase == .summary {
                persistSession()
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Drill")
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
        guard summary.total > 0 else { return }
        let xp = XPManager.shared
        if summary.correct == summary.total {
            xp.award(.perfectSession)
        } else {
            xp.award(.sessionComplete)
        }
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
    @ObservedObject private var xp = XPManager.shared
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
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(CoachCopy.timeGreeting(name: SettingsStore.shared.studentName))
                            .font(GameFont.title2())
                            .foregroundStyle(AppTheme.primaryText)
                        Text("Beat the clock. Nail the answer.")
                            .font(GameFont.body())
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    Spacer()
                    XPStreakBar(streak: xp.currentStreak, xp: xp.totalXP)
                }
                .gameCard()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        QuickDrillChip(title: "⚡ 5 Bio", color: GameColors.biology) {
                            quickStart(subject: .biology, count: 5)
                        }
                        QuickDrillChip(title: "⚡ 5 Chem", color: GameColors.chemistry) {
                            quickStart(subject: .chemistry, count: 5)
                        }
                        QuickDrillChip(title: "⚡ 5 Phys", color: GameColors.physics) {
                            quickStart(subject: .physics, count: 5)
                        }
                        QuickDrillChip(title: "🎲 Random 10", color: GameColors.tabAccent) {
                            viewModel.quizLength = .ten
                            onStart()
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Label("Buzzer Drill", systemImage: "bolt.fill")
                        .font(GameFont.title2())
                        .foregroundStyle(GameColors.tabAccent)
                    Text("4 choices · timed toss-ups")
                        .font(GameFont.body())
                        .foregroundStyle(AppTheme.secondaryText)

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
                                    .font(GameFont.caption())
                                Picker("Questions", selection: $viewModel.quizLength) {
                                    ForEach(QuizLength.allCases) { length in
                                        Text(length.label).tag(length)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Timer")
                                    .font(GameFont.caption())
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
                                .font(GameFont.caption())
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    Button(action: onStart) {
                        Text("Let's go →")
                            .font(GameFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GameColors.chemistry)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(availableCount == 0)
                }
                .gameCard()
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
    }

    private func quickStart(subject: Subject, count: Int) {
        viewModel.selectedTopicIDs = [TopicCatalog.allTopicID(for: subject)]
        viewModel.selectedSimpleSubjects = []
        viewModel.quizLength = QuizLength(rawValue: count) ?? .five
        onStart()
    }
}

struct QuizSummaryView: View {
    @ObservedObject var viewModel: QuizViewModel
    @ObservedObject private var settings = SettingsStore.shared
    let bank: QuestionBank
    let onDone: () -> Void

    var body: some View {
        let summary = viewModel.scoreSummary
        ScrollView {
            VStack(spacing: 20) {
                Text(CoachCopy.drillHeadline(correct: summary.correct, total: summary.total))
                    .font(GameFont.largeTitle())
                    .foregroundStyle(AppTheme.primaryText)

                AccuracyRingView(progress: summary.percent, label: "Accuracy")

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

                Button("Drill Again →", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
    }
}
