import SwiftUI

struct MoleculeMatchGameView: View {
    @ObservedObject private var xp = XPManager.shared

    @State private var cards: [MemoryCard] = []
    @State private var flipped: Set<UUID> = []
    @State private var matched: Set<UUID> = []
    @State private var firstPick: UUID?
    @State private var moves = 0
    @State private var isFinished = false
    @State private var lockInput = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        Group {
            if isFinished {
                endScreen
            } else {
                activeScreen
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Molecule Match")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear { startGame() }
    }

    private var activeScreen: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Label("\(moves) moves", systemImage: "arrow.triangle.swap")
                        .font(GameFont.caption(.semibold))
                    Spacer()
                    Label("\(matched.count / 2) / \(cards.count / 2) pairs", systemImage: "checkmark.circle")
                        .font(GameFont.caption(.semibold))
                        .foregroundStyle(GameColors.biology)
                }
                .foregroundStyle(AppTheme.secondaryText)
                .gameCard()

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cards) { card in
                        cardView(card)
                    }
                }
                .gameCard()
            }
            .padding(24)
            .contentColumn()
        }
    }

    private func cardView(_ card: MemoryCard) -> some View {
        let isFaceUp = flipped.contains(card.id) || matched.contains(card.pairID)
        return Button {
            tap(card)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isFaceUp ? GameColors.biology.opacity(0.22) : GameColors.cardSurface2)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(matched.contains(card.pairID) ? GameColors.correct : GameColors.biology.opacity(0.35), lineWidth: 2)

                if isFaceUp {
                    Text(card.face)
                        .font(GameFont.caption(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .minimumScaleFactor(0.7)
                } else {
                    Image(systemName: "flask.fill")
                        .font(.title2)
                        .foregroundStyle(GameColors.chemistry.opacity(0.5))
                }
            }
            .frame(height: 88)
            .rotation3DEffect(.degrees(isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .animation(.spring(response: 0.35), value: isFaceUp)
        }
        .buttonStyle(.plain)
        .disabled(lockInput || matched.contains(card.pairID) || flipped.contains(card.id))
    }

    private var endScreen: some View {
        DrillRoundEndView(
            correct: cards.count / 2,
            missed: 0,
            total: cards.count / 2,
            xpEarned: XPManager.Award.miniGameComplete.points,
            streak: xp.currentStreak,
            subjectRows: [(name: "Chemistry", correct: cards.count / 2, total: cards.count / 2, color: GameColors.chemistry)],
            primaryActionTitle: "Play Again →",
            onPrimary: { startGame() }
        )
    }

    private func startGame() {
        cards = MoleculeMatchContent.randomDeck(pairCount: 6)
        flipped = []
        matched = []
        firstPick = nil
        moves = 0
        isFinished = false
        lockInput = false
    }

    private func tap(_ card: MemoryCard) {
        guard !lockInput, !matched.contains(card.pairID) else { return }
        flipped.insert(card.id)
        HapticManager.light()

        guard let first = firstPick else {
            firstPick = card.id
            return
        }

        guard first != card.id else { return }

        moves += 1
        lockInput = true
        let firstCard = cards.first { $0.id == first }
        let isMatch = firstCard?.pairID == card.pairID

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if isMatch, let pairID = firstCard?.pairID {
                matched.insert(pairID)
                flipped.remove(first)
                flipped.remove(card.id)
                firstPick = nil
                lockInput = false
                if matched.count == Set(cards.map(\.pairID)).count {
                    xp.award(.miniGameComplete)
                    xp.recordActivity()
                    isFinished = true
                }
            } else {
                flipped.remove(first)
                flipped.remove(card.id)
                firstPick = nil
                lockInput = false
            }
        }
    }
}
