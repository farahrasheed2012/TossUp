import SwiftUI

struct QuizSessionView: View {
    @ObservedObject var viewModel: QuizViewModel
    @ObservedObject private var settings = SettingsStore.shared
    @FocusState private var answerFocused: Bool
    @State private var showEndQuizConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                if viewModel.phase == .inProgress {
                    sessionControls
                }
                if let question = viewModel.currentQuestion {
                    questionCard(question)
                }
                if viewModel.phase == .feedback {
                    feedbackBanner
                }
            }
            .padding(24)
            .contentColumn(maxWidth: AppLayout.quizMaxWidth)
        }
        .background(AppTheme.pageBackground)
        .onAppear {
            answerFocused = true
            readCurrentQuestion()
        }
        .onDisappear {
            SpeechManager.shared.stop()
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            readCurrentQuestion()
        }
        .confirmationDialog("End this quiz session?", isPresented: $showEndQuizConfirm) {
            Button("End Session", role: .destructive) {
                viewModel.endSessionEarly()
            }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Your progress so far will be saved in the summary.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .skipQuestion)) { _ in
            if viewModel.phase == .inProgress {
                viewModel.skipQuestion()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .endQuizSession)) { _ in
            if viewModel.phase == .inProgress || viewModel.phase == .feedback {
                showEndQuizConfirm = true
            }
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
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { _ in
            if viewModel.phase == .feedback {
                viewModel.continueAfterFeedback()
            }
            return .handled
        }
        #endif
    }

    private var sessionControls: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.skipQuestion()
            } label: {
                Label("Skip", systemImage: "forward.fill")
            }
            .buttonStyle(.bordered)
            #if os(macOS)
            .keyboardShortcut(.escape, modifiers: [])
            .help("Skip question (Esc)")
            #endif

            Spacer()

            Button(role: .destructive) {
                showEndQuizConfirm = true
            } label: {
                Label("End Quiz", systemImage: "stop.fill")
            }
            .buttonStyle(.bordered)
            #if os(macOS)
            .keyboardShortcut(".", modifiers: .command)
            .help("End session (⌘.)")
            #endif
        }
    }

    private var header: some View {
        HStack {
            Text(viewModel.progressLabel)
                .font(.headline)
            Spacer()
            if settings.readQuestionsAloud {
                Button {
                    readCurrentQuestion()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                }
                .buttonStyle(.borderless)
                .help("Read question again")
            }
            if let seconds = viewModel.remainingSeconds {
                Text("\(seconds)s")
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(seconds <= 3 ? AppTheme.danger : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.cardBackground)
                    .clipShape(Capsule())
            } else if settings.readQuestionsAloud && viewModel.phase == .inProgress {
                Text("Reading…")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.cardBackground)
                    .clipShape(Capsule())
            } else {
                Text("∞")
                    .font(.title2)
            }
        }
    }

    @ViewBuilder
    private func questionCard(_ question: NSBQuestion) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(question.subject.emoji)
                Text("\(question.subject.displayName) · \(question.type.displayName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(question.displayContextLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(question.questionText)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)

            if question.type == .multipleChoice, let choices = question.choices {
                VStack(spacing: 10) {
                    ForEach(choices, id: \.self) { choice in
                        let letter = choice.first ?? "?"
                        let letterString = String(letter).uppercased()
                        ChoiceButton(
                            choice: choice,
                            isCorrectHighlight: viewModel.phase == .feedback &&
                                letterString == question.correctAnswer.uppercased(),
                            isWrongHighlight: viewModel.phase == .feedback &&
                                !viewModel.lastFeedbackCorrect &&
                                letterString == viewModel.lastUserAnswer.uppercased(),
                            isDisabled: viewModel.phase == .feedback
                        ) {
                            viewModel.submitMultipleChoice(letter)
                        }
                    }
                }
            } else {
                TextField("Type your answer", text: $viewModel.shortAnswerText)
                    .textFieldStyle(.roundedBorder)
                    .focused($answerFocused)
                    .onSubmit { viewModel.submitShortAnswer() }
                    .disabled(viewModel.phase == .feedback)

                HStack(spacing: 12) {
                    Button("Submit") { viewModel.submitShortAnswer() }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.phase == .feedback)
                    Button("Skip") { viewModel.skipQuestion() }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.phase == .feedback)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var feedbackBanner: some View {
        VStack(spacing: 14) {
            if let feedback = viewModel.lastFeedback {
                AnswerFeedbackCard(feedback: feedback)
            } else {
                VStack(spacing: 10) {
                    Text(viewModel.lastFeedbackCorrect ? "Correct!" : "Not quite")
                        .font(.title2.bold())
                        .foregroundStyle(viewModel.lastFeedbackCorrect ? AppTheme.success : AppTheme.danger)
                    if !viewModel.lastFeedbackCorrect {
                        Text("Answer: \(viewModel.lastCorrectAnswer)")
                            .font(.headline)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .cardStyle()
            }

            Button(viewModel.phase == .feedback && viewModel.currentIndex + 1 >= viewModel.sessionQuestions.count
                   ? "See Results" : "Next Question") {
                viewModel.continueAfterFeedback()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    private func handleSpace() {
        if viewModel.phase == .feedback {
            viewModel.continueAfterFeedback()
        } else if viewModel.currentQuestion?.type == .shortAnswer {
            viewModel.submitShortAnswer()
        }
    }

    private func readCurrentQuestion() {
        guard settings.readQuestionsAloud,
              viewModel.phase == .inProgress,
              let question = viewModel.currentQuestion else { return }

        let startTimerIfNeeded = viewModel.remainingSeconds == nil
            ? { viewModel.startQuestionTimerAfterReadAloud() }
            : nil

        if let choices = question.choices {
            SpeechManager.shared.speakQuestionWithChoices(
                question: question.questionText,
                choices: choices,
                onFinish: startTimerIfNeeded
            )
        } else {
            SpeechManager.shared.speakQuestion(question.questionText, onFinish: startTimerIfNeeded)
        }
    }
}
