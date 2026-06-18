import SwiftUI

struct QuizSessionView: View {
    @ObservedObject var viewModel: QuizViewModel
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var xp = XPManager.shared
    var onDrillAgain: () -> Void = {}
    @State private var showEndQuizConfirm = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if viewModel.phase == .summary {
                    summaryView
                } else {
                    drillContent
                }
            }
            .gamePageBackground()
            .subjectBleed(viewModel.currentQuestion?.subject)

            DrillFlashOverlay(color: viewModel.flashColor)

            if viewModel.showXPFloater {
                VStack {
                    HStack {
                        Spacer()
                        Text("+10 XP")
                            .font(GameFont.headline(.bold))
                            .foregroundStyle(GameColors.xpGold)
                            .padding(.top, 60)
                            .padding(.trailing, 24)
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if viewModel.drillState == .countdown {
                DrillCountdownOverlay(
                    text: viewModel.countdownText,
                    subjectColor: viewModel.currentQuestion?.subject.gameColor ?? GameColors.chemistry
                )
            }
        }
        .onDisappear { SpeechManager.shared.stop() }
        .onChange(of: viewModel.currentIndex) { _, _ in readCurrentQuestion() }
        .onAppear { readCurrentQuestion() }
        .confirmationDialog("End this drill?", isPresented: $showEndQuizConfirm) {
            Button("End Session", role: .destructive) { viewModel.endSessionEarly() }
            Button("Keep Playing", role: .cancel) {}
        }
        .onReceive(NotificationCenter.default.publisher(for: .skipQuestion)) { _ in
            if viewModel.phase == .inProgress { viewModel.skipQuestion() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .endQuizSession)) { _ in
            if viewModel.phase == .inProgress { showEndQuizConfirm = true }
        }
        #if os(macOS)
        .focusable()
        .onKeyPress(.space) {
            handleSpace()
            return .handled
        }
        .onKeyPress(.escape) {
            if viewModel.phase == .inProgress {
                viewModel.skipQuestion()
                return .handled
            }
            return .ignored
        }
        #endif
    }

    private var drillContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Text(viewModel.progressLabel)
                        .font(GameFont.caption())
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    DrillScorePill(correct: viewModel.liveCorrect, missed: viewModel.liveMissed)
                    if settings.readQuestionsAloud {
                        Button { readCurrentQuestion() } label: {
                            Image(systemName: "speaker.wave.2.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                if !viewModel.sessionQuestions.isEmpty {
                    DrillThinProgressBar(
                        progress: Double(viewModel.currentIndex) / Double(viewModel.sessionQuestions.count),
                        color: viewModel.currentQuestion?.subject.gameColor ?? GameColors.chemistry
                    )
                }

                if let question = viewModel.currentQuestion {
                    questionCard(question)
                }

                footerControls
            }
            .padding(24)
            .contentColumn(maxWidth: AppLayout.quizMaxWidth)
        }
    }

    @ViewBuilder
    private var footerControls: some View {
        switch viewModel.drillState {
        case .questionLive:
            BuzzButton(
                subjectColor: viewModel.currentQuestion?.subject.gameColor ?? GameColors.chemistry,
                progress: viewModel.arcProgress,
                action: { viewModel.buzz() }
            )
            DrillDotRow(
                total: viewModel.sessionQuestions.count,
                current: viewModel.currentIndex,
                color: viewModel.currentQuestion?.subject.gameColor ?? GameColors.chemistry
            )
            Button("Skip →") { viewModel.skipQuestion() }
                .font(GameFont.caption())
                .foregroundStyle(AppTheme.secondaryText)

        case .buzzed:
            VStack(spacing: 12) {
                Text("Think… what's your answer?")
                    .font(GameFont.body())
                    .foregroundStyle(AppTheme.secondaryText)
                Button {
                    viewModel.revealAnswer()
                } label: {
                    Text("Reveal Answer →")
                        .font(GameFont.headline())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.currentQuestion?.subject.gameColor ?? GameColors.chemistry)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

        case .revealed:
            DrillOutcomeButtons(
                onCorrect: { viewModel.logCorrect() },
                onMissed: { viewModel.logMissed() }
            )

        case .transitioning, .countdown:
            EmptyView()
        }

        HStack {
            Spacer()
            Button(role: .destructive) { showEndQuizConfirm = true } label: {
                Label("End", systemImage: "stop.fill")
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func questionCard(_ question: NSBQuestion) -> some View {
        let subjectColor = question.subject.gameColor
        let showAnswer = viewModel.drillState == .revealed || viewModel.drillState == .transitioning
        let correctLetter = question.correctAnswer.uppercased()

        VStack(alignment: .leading, spacing: 16) {
            SubjectBadge(subject: question.subject, suffix: "Toss-Up · \(question.type.displayName)")

            Text(question.questionText)
                .font(GameFont.title3())
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if question.type == .multipleChoice, let choices = question.choices {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(choices, id: \.self) { choice in
                        let letter = String(choice.prefix(1)).uppercased()
                        let isCorrect = showAnswer && letter == correctLetter
                        Text(choice)
                            .font(GameFont.body())
                            .foregroundStyle(isCorrect ? subjectColor : AppTheme.primaryText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isCorrect ? subjectColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else if question.type == .shortAnswer {
                Text("Short Answer")
                    .font(GameFont.caption())
                    .foregroundStyle(AppTheme.secondaryText)
            }

            if showAnswer {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ANSWER")
                        .font(GameFont.caption(.bold))
                        .foregroundStyle(subjectColor)
                    Text(question.correctAnswer)
                        .font(GameFont.title2(.bold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .gameCard(color: subjectColor.opacity(0.06))
    }

    private var summaryView: some View {
        DrillRoundEndView(
            correct: viewModel.scoreSummary.correct,
            missed: viewModel.scoreSummary.total - viewModel.scoreSummary.correct,
            total: viewModel.scoreSummary.total,
            xpEarned: viewModel.sessionXpEarned,
            streak: xp.currentStreak,
            subjectRows: viewModel.subjectBreakdown(),
            onPrimary: onDrillAgain,
            onSecondary: nil
        )
    }

    private func handleSpace() {
        switch viewModel.drillState {
        case .questionLive: viewModel.buzz()
        case .buzzed: viewModel.revealAnswer()
        case .revealed: viewModel.logCorrect()
        default: break
        }
    }

    private func readCurrentQuestion() {
        guard settings.readQuestionsAloud,
              viewModel.phase == .inProgress,
              viewModel.drillState == .questionLive,
              let question = viewModel.currentQuestion else { return }

        let onFinish = { viewModel.startQuestionTimerAfterReadAloud() }
        if let choices = question.choices {
            SpeechManager.shared.speakQuestionWithChoices(
                question: question.questionText,
                choices: choices,
                onFinish: onFinish
            )
        } else {
            SpeechManager.shared.speakQuestion(question.questionText, onFinish: onFinish)
        }
    }
}
