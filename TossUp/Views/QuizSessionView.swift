import SwiftUI

struct QuizSessionView: View {
    @ObservedObject var viewModel: QuizViewModel
    @ObservedObject private var settings = SettingsStore.shared
    @FocusState private var answerFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
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
        #if os(macOS)
        .focusable()
        .onKeyPress(.space) {
            handleSpace()
            return .handled
        }
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { _ in
            if viewModel.phase == .feedback {
                viewModel.continueAfterFeedback()
            }
            return .handled
        }
        #endif
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

            Text(question.questionText)
                .font(.title3)
                .fixedSize(horizontal: false, vertical: true)

            if question.type == .multipleChoice, let choices = question.choices {
                VStack(spacing: 10) {
                    ForEach(choices, id: \.self) { choice in
                        let letter = choice.first ?? "?"
                        ChoiceButton(
                            choice: choice,
                            isCorrectHighlight: viewModel.phase == .feedback &&
                                String(letter).uppercased() == question.correctAnswer.uppercased(),
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

                Button("Submit") { viewModel.submitShortAnswer() }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.phase == .feedback)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var feedbackBanner: some View {
        VStack(spacing: 10) {
            Text(viewModel.lastFeedbackCorrect ? "Correct!" : "Not quite")
                .font(.title2.bold())
                .foregroundStyle(viewModel.lastFeedbackCorrect ? AppTheme.success : AppTheme.danger)
            if !viewModel.lastFeedbackCorrect {
                Text("Answer: \(viewModel.lastCorrectAnswer)")
                    .font(.headline)
            }
            Button("Continue") { viewModel.continueAfterFeedback() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .cardStyle()
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
        if let choices = question.choices {
            SpeechManager.shared.speakQuestionWithChoices(question: question.questionText, choices: choices)
        } else {
            SpeechManager.shared.speakQuestion(question.questionText)
        }
    }
}
