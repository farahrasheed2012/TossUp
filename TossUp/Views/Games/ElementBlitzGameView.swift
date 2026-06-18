import SwiftUI

struct ElementBlitzGameView: View {
    @ObservedObject private var xp = XPManager.shared

  private let duration: TimeInterval = 90

    @State private var timeLeft: TimeInterval = 90
    @State private var timerTask: Task<Void, Never>?
    @State private var streak = 0
    @State private var bestStreak = 0
    @State private var score = 0
    @State private var round = 0
    @State private var isFinished = false
    @State private var flashColor: Color?

    @State private var prompt = ""
    @State private var choices: [String] = []
    @State private var correctAnswer = ""
    @State private var mode: PromptMode = .symbolToName

    enum PromptMode: CaseIterable {
        case symbolToName, nameToSymbol, numberToName
    }

    var body: some View {
        Group {
            if isFinished {
                endScreen
            } else {
                activeScreen
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Element Blitz")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { startGame() }
        .onDisappear { timerTask?.cancel() }
        .overlay { DrillFlashOverlay(color: flashColor) }
    }

    private var activeScreen: some View {
        VStack(spacing: 18) {
            HStack {
                Label("\(Int(timeLeft))s", systemImage: "timer")
                    .font(GameFont.headline())
                    .foregroundStyle(timeLeft < 15 ? GameColors.incorrect : GameColors.chemistry)
                Spacer()
                Label("Streak \(streak)", systemImage: "flame.fill")
                    .font(GameFont.caption(.semibold))
                    .foregroundStyle(GameColors.streakFlame)
                Label("\(score) pts", systemImage: "star.fill")
                    .font(GameFont.caption(.semibold))
                    .foregroundStyle(GameColors.xpGold)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            DrillThinProgressBar(
                progress: timeLeft / duration,
                color: GameColors.chemistry
            )
            .padding(.horizontal, 24)

            Spacer()

            Text(prompt)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(modeLabel)
                .font(GameFont.caption())
                .foregroundStyle(AppTheme.secondaryText)

            VStack(spacing: 10) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        pick(choice)
                    } label: {
                        Text(choice)
                            .font(GameFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GameColors.cardSurface2)
                            .foregroundStyle(AppTheme.primaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .contentColumn()
    }

    private var modeLabel: String {
        switch mode {
        case .symbolToName: return "Pick the element name"
        case .nameToSymbol: return "Pick the symbol"
        case .numberToName: return "Pick the element name"
        }
    }

    private var endScreen: some View {
        DrillRoundEndView(
            correct: score,
            missed: max(round - score, 0),
            total: round,
            xpEarned: XPManager.Award.miniGameComplete.points,
            streak: xp.currentStreak,
            subjectRows: [(name: "Chemistry", correct: score, total: round, color: GameColors.chemistry)],
            primaryActionTitle: "Play Again →",
            onPrimary: { startGame() }
        )
    }

    private func startGame() {
        timerTask?.cancel()
        timeLeft = duration
        streak = 0
        bestStreak = 0
        score = 0
        round = 0
        isFinished = false
        nextRound()
        timerTask = Task {
            while !Task.isCancelled, timeLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    timeLeft -= 1
                    if timeLeft <= 0 {
                        finish()
                    }
                }
            }
        }
    }

    private func finish() {
        timerTask?.cancel()
        isFinished = true
        xp.award(.miniGameComplete)
        xp.recordActivity()
    }

    private func nextRound() {
        let element = ElementCatalog.firstTwenty.randomElement()!
        mode = PromptMode.allCases.randomElement()!
        round += 1

        switch mode {
        case .symbolToName:
            prompt = element.symbol
            correctAnswer = element.name
        case .nameToSymbol:
            prompt = element.name
            correctAnswer = element.symbol
        case .numberToName:
            prompt = "#\(element.atomicNumber)"
            correctAnswer = element.name
        }

        var distractors = ElementCatalog.firstTwenty
            .filter { $0.id != element.id }
            .shuffled()
            .prefix(3)
            .map { distractor(for: $0) }

        choices = ([correctAnswer] + distractors).shuffled()
    }

    private func distractor(for element: ChemicalElement) -> String {
        switch mode {
        case .symbolToName, .numberToName: return element.name
        case .nameToSymbol: return element.symbol
        }
    }

    private func pick(_ choice: String) {
        let isRight = choice == correctAnswer
        flashColor = isRight ? GameColors.correct : GameColors.incorrect
        if isRight {
            score += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
        } else {
            streak = 0
        }
        HapticManager.light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            flashColor = nil
            if !isFinished { nextRound() }
        }
    }
}
