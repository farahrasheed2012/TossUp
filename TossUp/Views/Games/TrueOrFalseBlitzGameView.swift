import SwiftUI

struct TrueOrFalseBlitzGameView: View {
    @ObservedObject private var xp = XPManager.shared
    @EnvironmentObject private var bank: QuestionBank

    @State private var statements: [TrueFalseStatement] = []
    @State private var index = 0
    @State private var correct = 0
    @State private var missed = 0
    @State private var isFinished = false
    @State private var flashColor: Color?
    @State private var showFeedback = false
    @State private var lastWasCorrect = false

    var body: some View {
        Group {
            if isFinished {
                endScreen
            } else if let statement = currentStatement {
                activeScreen(statement)
            } else {
                ProgressView("Loading…")
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("True or False Blitz")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { startSession() }
        .overlay { DrillFlashOverlay(color: flashColor) }
    }

    private var currentStatement: TrueFalseStatement? {
        guard index < statements.count else { return nil }
        return statements[index]
    }

    private func activeScreen(_ statement: TrueFalseStatement) -> some View {
        VStack(spacing: 20) {
            HStack {
                DrillScorePill(correct: correct, missed: missed)
                Spacer()
                Text("\(index + 1) / \(statements.count)")
                    .font(GameFont.caption())
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            DrillThinProgressBar(
                progress: Double(index) / Double(max(statements.count, 1)),
                color: GameColors.tabAccent
            )
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 16) {
                SubjectBadge(subject: statement.subject)
                Text(statement.text)
                    .font(GameFont.title3())
                    .foregroundStyle(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .gameCard()
            .padding(.horizontal, 24)

            if showFeedback {
                Text(lastWasCorrect ? "Correct! ✓" : "Not quite ✗")
                    .font(GameFont.headline())
                    .foregroundStyle(lastWasCorrect ? GameColors.correct : GameColors.incorrect)
            }

            Spacer()

            HStack(spacing: 14) {
                tfButton(title: "FALSE", icon: "xmark", color: GameColors.incorrect) {
                    answer(false, statement: statement)
                }
                tfButton(title: "TRUE", icon: "checkmark", color: GameColors.correct) {
                    answer(true, statement: statement)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .disabled(showFeedback)
        }
        .contentColumn()
    }

    private func tfButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(GameFont.headline())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(color.opacity(0.22))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.45), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var endScreen: some View {
        DrillRoundEndView(
            correct: correct,
            missed: missed,
            total: statements.count,
            xpEarned: xpEarned,
            streak: xp.currentStreak,
            subjectRows: [],
            primaryActionTitle: "Play Again →",
            onPrimary: { startSession() }
        )
    }

    private var xpEarned: Int {
        correct >= statements.count / 2 ? XPManager.Award.miniGameComplete.points : XPManager.Award.sessionComplete.points
    }

    private func startSession() {
        var pool = TrueFalseBlitzContent.curated
        if !bank.questions.isEmpty {
            pool.append(contentsOf: TrueFalseBlitzContent.statements(from: bank.questions).prefix(10))
        }
        statements = Array(pool.shuffled().prefix(TrueFalseBlitzContent.sessionLength))
        index = 0
        correct = 0
        missed = 0
        isFinished = false
        showFeedback = false
    }

    private func answer(_ value: Bool, statement: TrueFalseStatement) {
        let isRight = value == statement.isTrue
        lastWasCorrect = isRight
        if isRight { correct += 1 } else { missed += 1 }
        flashColor = isRight ? GameColors.correct : GameColors.incorrect
        showFeedback = true
        HapticManager.light()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            flashColor = nil
            showFeedback = false
            if index + 1 >= statements.count {
                xp.award(correct >= statements.count / 2 ? .miniGameComplete : .sessionComplete)
                xp.recordActivity()
                isFinished = true
            } else {
                index += 1
            }
        }
    }
}
