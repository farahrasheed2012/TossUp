import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DrillScreenState: Equatable {
    case countdown
    case questionLive
    case buzzed
    case revealed
    case transitioning
}

@MainActor
final class ArcCountdownTimer {
    private var task: Task<Void, Never>?

    func start(duration: TimeInterval, onProgress: @escaping (CGFloat) -> Void, onExpired: @escaping () -> Void) {
        cancel()
        guard duration > 0 else {
            onProgress(1)
            return
        }
        task = Task {
            let start = Date()
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(start)
                let remaining = max(0, 1.0 - elapsed / duration)
                onProgress(CGFloat(remaining))
                if remaining <= 0 {
                    onExpired()
                    return
                }
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

struct DrillScorePill: View {
    let correct: Int
    let missed: Int

    var body: some View {
        HStack(spacing: 12) {
            Label("\(correct)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(GameColors.correct)
            Label("\(missed)", systemImage: "xmark.circle.fill")
                .foregroundStyle(GameColors.incorrect)
        }
        .font(GameFont.caption(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(GameColors.cardSurface2)
        .clipShape(Capsule())
    }
}

struct DrillThinProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.2))
                Capsule().fill(color)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 4)
    }
}

struct DrillDotRow: View {
    let total: Int
    let current: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func dotColor(for index: Int) -> Color {
        if index < current { return color }
        if index == current { return GameColors.textPrimary }
        return GameColors.textTertiary
    }
}

struct DrillOutcomeButtons: View {
    let onCorrect: () -> Void
    let onMissed: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCorrect) {
                Text("✓ Got it!")
                    .font(GameFont.headline())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(GameColors.correct)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onMissed) {
                Text("✗ Missed it")
                    .font(GameFont.headline())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(GameColors.incorrect)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

struct DrillCountdownOverlay: View {
    let text: String
    let subjectColor: Color

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            Text(text)
                .font(.system(size: text == "Go!" ? 72 : 96, weight: .bold, design: .rounded))
                .foregroundStyle(text == "Go!" ? subjectColor : GameColors.textPrimary)
                .scaleEffect(text == "Go!" ? 1.2 : 1.0)
                .animation(.spring(response: 0.35), value: text)
        }
    }
}

struct DrillSubjectBarRow: View {
    let name: String
    let correct: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(GameFont.caption())
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Text("\(correct) / \(total)")
                    .font(GameFont.caption())
                    .foregroundStyle(AppTheme.secondaryText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: total > 0 ? geo.size.width * CGFloat(correct) / CGFloat(total) : 0)
                }
            }
            .frame(height: 8)
        }
    }
}

struct DrillRoundEndView: View {
    let correct: Int
    let missed: Int
    let total: Int
    let xpEarned: Int
    let streak: Int
    let subjectRows: [(name: String, correct: Int, total: Int, color: Color)]
    var primaryActionTitle: String = "Drill Again →"
    let onPrimary: () -> Void
    var onSecondary: (() -> Void)?

    @State private var appeared = false

    private var showConfetti: Bool {
        total > 0 && Double(correct) / Double(total) >= 0.8
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(CoachCopy.drillHeadline(correct: correct, total: total))
                        .font(GameFont.largeTitle())
                        .foregroundStyle(AppTheme.primaryText)
                    Text("You got \(correct) out of \(total) right")
                        .font(GameFont.body())
                        .foregroundStyle(AppTheme.secondaryText)

                    HStack(spacing: 24) {
                        Label("\(correct) correct", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(GameColors.correct)
                        Label("\(missed) missed", systemImage: "xmark.circle.fill")
                            .foregroundStyle(GameColors.incorrect)
                    }
                    .font(GameFont.headline())
                    .gameCard()

                    VStack(spacing: 12) {
                        ForEach(Array(subjectRows.enumerated()), id: \.offset) { index, row in
                            DrillSubjectBarRow(
                                name: row.name,
                                correct: row.correct,
                                total: row.total,
                                color: row.color
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.spring(response: 0.6).delay(Double(index) * 0.12), value: appeared)
                        }
                    }
                    .gameCard()

                    VStack(spacing: 6) {
                        Label("+\(xpEarned) XP earned", systemImage: "star.fill")
                            .foregroundStyle(GameColors.xpGold)
                        if streak > 0 {
                            Label("\(streak)-day streak — still alive!", systemImage: "flame.fill")
                                .foregroundStyle(GameColors.streakFlame)
                        }
                    }
                    .font(GameFont.headline())

                    Button(action: onPrimary) {
                        Text(primaryActionTitle)
                            .font(GameFont.headline())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GameColors.chemistry)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if let onSecondary {
                        Button("Review missed →", action: onSecondary)
                            .font(GameFont.body())
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
                .padding(24)
                .contentColumn()
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear { appeared = true }
    }
}

#if canImport(UIKit)
struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)
        emitter.beginTime = CACurrentMediaTime()
        emitter.emitterCells = (0..<6).map { _ in makeCell() }
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            emitter.birthRate = 0
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private func makeCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 14
        cell.lifetime = 3
        cell.velocity = 180
        cell.velocityRange = 80
        cell.emissionLongitude = .pi
        cell.spin = 3
        cell.spinRange = 4
        cell.scale = 0.06
        cell.scaleRange = 0.04
        let colors: [UIColor] = [
            UIColor(GameColors.biology),
            UIColor(GameColors.chemistry),
            UIColor(GameColors.physics),
            .systemYellow,
            .white,
        ]
        cell.color = colors.randomElement()?.cgColor
        cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal).cgImage
        return cell
    }
}
#else
struct ConfettiView: View {
    var body: some View { EmptyView() }
}
#endif

struct DrillFlashOverlay: View {
    let color: Color?
    var body: some View {
        if let color {
            color.opacity(0.18)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .transition(.opacity)
        }
    }
}
