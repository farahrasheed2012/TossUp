import SwiftUI

struct ScienceWordleGameView: View {
    @ObservedObject private var xp = XPManager.shared

    @State private var answer = ScienceWordleContent.dailyWord()
    @State private var guesses: [String] = []
    @State private var currentGuess = ""
    @State private var isFinished = false
    @State private var didWin = false
    @State private var shakeRow = false
    @State private var flashColor: Color?
    @FocusState private var inputFocused: Bool

    private let rows = ScienceWordleContent.maxGuesses
    private let cols = ScienceWordleContent.wordLength

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                grid
                if isFinished {
                    resultCard
                } else {
                    typedInputRow
                    keyboard
                }
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Science Wordle")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .overlay {
            DrillFlashOverlay(color: flashColor)
        }
        #if os(macOS)
        .onAppear { focusTypingField() }
        .onKeyPress(.escape) { .handled }
        #endif
    }

    private var typedInputRow: some View {
        Group {
            #if os(iOS)
            TextField("Type your guess", text: $currentGuess)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
            #else
            TextField("Type your guess", text: $currentGuess)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
            #endif
        }
        .onChange(of: currentGuess) { _, newValue in
            let filtered = String(newValue.uppercased().filter(\.isLetter).prefix(cols))
            if filtered != newValue { currentGuess = filtered }
        }
        .onSubmit { submitGuess() }
        .disabled(isFinished)
        .gameCard()
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Guess the science term")
                .font(GameFont.headline())
                .foregroundStyle(AppTheme.primaryText)
            Text("5 letters · \(rows) tries")
                .font(GameFont.caption())
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .gameCard(color: GameColors.physics.opacity(0.12))
    }

    private var grid: some View {
        VStack(spacing: 8) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<cols, id: \.self) { col in
                        let letter = letter(at: row, col: col)
                        let state = tileState(row: row, col: col, letter: letter)
                        Text(letter)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .frame(width: 52, height: 52)
                            .background(tileColor(state))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .offset(x: shakeRow && row == guesses.count ? -6 : 0)
                .animation(shakeRow ? .default.repeatCount(3, autoreverses: true) : .default, value: shakeRow)
            }
        }
        .gameCard()
    }

    private var keyboard: some View {
        VStack(spacing: 8) {
            ForEach(keyboardRows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            tapKey(key)
                        } label: {
                            Text(key)
                                .font(GameFont.caption(.semibold))
                                .frame(minWidth: key == "⌫" || key == "↵" ? 44 : 28)
                                .padding(.horizontal, key.count > 1 ? 10 : 6)
                                .padding(.vertical, 10)
                                .background(keyBackground(key))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .disabled(isFinished)
                    }
                }
            }
        }
        .gameCard()
        #if os(macOS)
        .buttonStyle(.borderless)
        #else
        .buttonStyle(.plain)
        #endif
    }

    private var resultCard: some View {
        VStack(spacing: 12) {
            Text(didWin ? "Nice! 🎉" : "Answer: \(answer)")
                .font(GameFont.title2())
                .foregroundStyle(AppTheme.primaryText)
            Button(didWin ? "Play Again →" : "Try Again →") {
                resetGame()
            }
            .font(GameFont.headline())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(GameColors.physics)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            #if os(macOS)
            .buttonStyle(.borderless)
            #else
            .buttonStyle(.plain)
            #endif
        }
        .gameCard()
        .onAppear { awardIfNeeded() }
    }

    private var keyboardRows: [[String]] {
        [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["⌫", "Z", "X", "C", "V", "B", "N", "M", "↵"],
        ]
    }

    private func appendLetter(_ letter: Character) {
        guard !isFinished, currentGuess.count < cols else { return }
        currentGuess.append(letter)
        HapticManager.light()
    }

    private func deleteLetter() {
        guard !isFinished, !currentGuess.isEmpty else { return }
        currentGuess.removeLast()
        HapticManager.light()
    }

    private func letter(at row: Int, col: Int) -> String {
        if row < guesses.count {
            let word = Array(guesses[row])
            return col < word.count ? String(word[col]) : ""
        }
        if row == guesses.count {
            let word = Array(currentGuess)
            return col < word.count ? String(word[col]) : ""
        }
        return ""
    }

    private func tileState(row: Int, col: Int, letter: String) -> WordleLetterState {
        guard !letter.isEmpty else { return .unused }
        if row < guesses.count {
            let feedback = WordleEvaluator.feedback(guess: guesses[row], answer: answer)
            return feedback[col]
        }
        return .unused
    }

    private func tileColor(_ state: WordleLetterState) -> Color {
        switch state {
        case .unused: return GameColors.cardSurface2
        case .absent: return Color(white: 0.35)
        case .wrongSpot: return Color(red: 0.75, green: 0.65, blue: 0.15)
        case .correctSpot: return GameColors.correct
        }
    }

    private func keyBackground(_ key: String) -> Color {
        guard key.count == 1, let ch = key.first else { return GameColors.cardSurface2 }
        let best = bestState(for: ch)
        if best == .unused { return GameColors.cardSurface2 }
        return tileColor(best)
    }

    private func bestState(for letter: Character) -> WordleLetterState {
        var best: WordleLetterState = .unused
        for guess in guesses {
            let feedback = WordleEvaluator.feedback(guess: guess, answer: answer)
            for (i, ch) in guess.enumerated() where ch == letter {
                best = maxState(best, feedback[i])
            }
        }
        return best
    }

    private func maxState(_ a: WordleLetterState, _ b: WordleLetterState) -> WordleLetterState {
        let rank: [WordleLetterState: Int] = [.unused: 0, .absent: 1, .wrongSpot: 2, .correctSpot: 3]
        return (rank[a] ?? 0) >= (rank[b] ?? 0) ? a : b
    }

    private func tapKey(_ key: String) {
        guard !isFinished else { return }
        switch key {
        case "⌫":
            deleteLetter()
        case "↵":
            submitGuess()
        default:
            guard let ch = key.first else { return }
            appendLetter(ch)
        }
    }

    private func submitGuess() {
        guard currentGuess.count == cols else { return }
        guard ScienceWordleContent.isValidGuess(currentGuess) else {
            shakeRow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { shakeRow = false }
            return
        }
        guesses.append(currentGuess.uppercased())
        currentGuess = ""
        if guesses.last == answer {
            finish(won: true)
        } else if guesses.count >= rows {
            finish(won: false)
        }
    }

    private func finish(won: Bool) {
        isFinished = true
        didWin = won
        flashColor = won ? GameColors.correct : GameColors.incorrect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { flashColor = nil }
        HapticManager.light()
    }

    private func awardIfNeeded() {
        if didWin {
            xp.award(.miniGameComplete)
        }
        xp.recordActivity()
    }

    private func resetGame() {
        answer = ScienceWordleContent.wordBank.randomElement() ?? "ATOMS"
        guesses = []
        currentGuess = ""
        isFinished = false
        didWin = false
        #if os(macOS)
        focusTypingField()
        #endif
    }

    #if os(macOS)
    private func focusTypingField() {
        inputFocused = true
        DispatchQueue.main.async {
            inputFocused = true
        }
    }
    #endif
}
