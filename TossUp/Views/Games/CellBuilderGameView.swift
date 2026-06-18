import SwiftUI

struct CellBuilderGameView: View {
    @ObservedObject private var xp = XPManager.shared

    @State private var cellType: CellType = .animal
    @State private var pieces: [OrganellePiece] = []
    @State private var placed: [String: OrganellePiece] = [:]
    @State private var isFinished = false
    @State private var flashColor: Color?
    @State private var wrongShake = false

    var body: some View {
        Group {
            if isFinished {
                endScreen
            } else {
                activeScreen
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Cell Builder")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .overlay { DrillFlashOverlay(color: flashColor) }
        .onAppear { reset(for: cellType) }
    }

    private var activeScreen: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Cell type", selection: $cellType) {
                    ForEach(CellType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: cellType) { _, newType in
                    reset(for: newType)
                }

                Text("Drag organelles onto the labeled zones")
                    .font(GameFont.caption())
                    .foregroundStyle(AppTheme.secondaryText)

                cellDiagram
                    .frame(height: 340)
                    .gameCard(color: GameColors.biology.opacity(0.08))

                organelleTray
            }
            .padding(24)
            .contentColumn()
        }
    }

    private var cellDiagram: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                cellOutline(in: size)

                ForEach(CellBuilderContent.zones(for: cellType)) { zone in
                    zoneView(zone, size: size)
                }
            }
            .offset(x: wrongShake ? -8 : 0)
            .animation(wrongShake ? .default.repeatCount(3, autoreverses: true) : .default, value: wrongShake)
        }
    }

    private func zoneView(_ zone: CellDropZone, size: CGSize) -> some View {
        let center = CGPoint(x: zone.center.x * size.width, y: zone.center.y * size.height)
        let diameter = zone.radius * min(size.width, size.height) * 2

        return ZStack {
            Circle()
                .stroke(
                    placed[zone.id] != nil ? GameColors.correct : GameColors.biology.opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, dash: placed[zone.id] == nil ? [6, 4] : [])
                )
                .frame(width: diameter, height: diameter)

            if let piece = placed[zone.id] {
                VStack(spacing: 2) {
                    Image(systemName: piece.icon)
                    Text(piece.label)
                        .font(.system(size: 9, weight: .semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(GameColors.correct)
            } else {
                Text(zone.label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(4)
            }
        }
        .frame(width: diameter, height: diameter)
        .position(center)
        .dropDestination(for: String.self) { items, _ in
            guard placed[zone.id] == nil, let id = items.first,
                  let piece = pieces.first(where: { $0.id == id }),
                  !placed.values.contains(where: { $0.id == piece.id }) else {
                return false
            }
            return place(piece, in: zone)
        }
    }

    private func cellOutline(in size: CGSize) -> some View {
        RoundedRectangle(cornerRadius: size.width * 0.42, style: .continuous)
            .stroke(GameColors.biology.opacity(0.55), lineWidth: 3)
            .frame(width: size.width * 0.88, height: size.height * 0.82)
            .position(x: size.width / 2, y: size.height / 2)
            .overlay {
                if cellType == .plant {
                    RoundedRectangle(cornerRadius: size.width * 0.46, style: .continuous)
                        .stroke(GameColors.biology.opacity(0.3), lineWidth: 6)
                        .frame(width: size.width * 0.96, height: size.height * 0.9)
                        .position(x: size.width / 2, y: size.height / 2)
                }
            }
    }

    private var organelleTray: some View {
        let remaining = pieces.filter { piece in
            !placed.values.contains(where: { $0.id == piece.id })
        }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Organelles")
                .font(GameFont.caption())
                .foregroundStyle(AppTheme.secondaryText)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(remaining) { piece in
                    organelleChip(piece)
                        .draggable(piece.id)
                }
            }
        }
        .gameCard()
    }

    private func organelleChip(_ piece: OrganellePiece) -> some View {
        VStack(spacing: 4) {
            Image(systemName: piece.icon)
                .font(.title3)
            Text(piece.label)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(AppTheme.primaryText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(GameColors.cardSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @discardableResult
    private func place(_ piece: OrganellePiece, in zone: CellDropZone) -> Bool {
        if zone.id == piece.correctZone {
            placed[zone.id] = piece
            flashColor = GameColors.correct
            HapticManager.light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { flashColor = nil }
            if placed.count == pieces.count {
                xp.award(.miniGameComplete)
                xp.recordActivity()
                isFinished = true
            }
            return true
        }
        wrongDrop()
        return false
    }

    private func wrongDrop() {
        flashColor = GameColors.incorrect
        wrongShake = true
        HapticManager.light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            flashColor = nil
            wrongShake = false
        }
    }

    private var endScreen: some View {
        DrillRoundEndView(
            correct: pieces.count,
            missed: 0,
            total: pieces.count,
            xpEarned: XPManager.Award.miniGameComplete.points,
            streak: xp.currentStreak,
            subjectRows: [(name: "Biology", correct: pieces.count, total: pieces.count, color: GameColors.biology)],
            primaryActionTitle: "Build Again →",
            onPrimary: { reset(for: cellType) }
        )
    }

    private func reset(for type: CellType) {
        cellType = type
        pieces = CellBuilderContent.pieces(for: type)
        placed = [:]
        isFinished = false
    }
}
