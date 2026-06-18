import SwiftUI

// MARK: - Colors (shared DNA with Science Bowl Coach)

enum GameColors {
    static let biology = Color(red: 0.18, green: 0.75, blue: 0.47)
    static let chemistry = Color(red: 0.40, green: 0.52, blue: 0.98)
    static let physics = Color(red: 1.00, green: 0.58, blue: 0.18)
    static let math = Color(red: 0.55, green: 0.45, blue: 0.95)
    static let earthSpace = Color(red: 0.30, green: 0.78, blue: 0.85)

    static let appBackground = Color(red: 0.07, green: 0.07, blue: 0.10)
    static let cardSurface = Color(red: 0.13, green: 0.13, blue: 0.18)
    static let cardSurface2 = Color(red: 0.18, green: 0.18, blue: 0.24)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.60)
    static let textTertiary = Color.white.opacity(0.35)

    static let correct = biology
    static let incorrect = Color(red: 0.85, green: 0.25, blue: 0.25)
    static let xpGold = Color.yellow
    static let streakFlame = Color.orange
    static let tabAccent = Color.yellow
}

extension Subject {
    var gameColor: Color {
        switch self {
        case .biology: return GameColors.biology
        case .chemistry: return GameColors.chemistry
        case .physics: return GameColors.physics
        case .math: return GameColors.math
        case .earthSpace: return GameColors.earthSpace
        }
    }

    var gameIcon: String {
        switch self {
        case .biology: return "leaf.fill"
        case .chemistry: return "flask.fill"
        case .physics: return "bolt.fill"
        case .math: return "function"
        case .earthSpace: return "globe.americas.fill"
        }
    }
}

enum GameFont {
    static func largeTitle(_ weight: Font.Weight = .bold) -> Font {
        .system(.largeTitle, design: .rounded, weight: weight)
    }

    static func title2(_ weight: Font.Weight = .semibold) -> Font {
        .system(.title2, design: .rounded, weight: weight)
    }

    static func headline(_ weight: Font.Weight = .semibold) -> Font {
        .system(.headline, design: .rounded, weight: weight)
    }

    static func body(_ weight: Font.Weight = .regular) -> Font {
        .system(.body, design: .rounded, weight: weight)
    }

    static func caption(_ weight: Font.Weight = .medium) -> Font {
        .system(.caption, design: .rounded, weight: weight)
    }

    static func title3(_ weight: Font.Weight = .semibold) -> Font {
        .system(.title3, design: .rounded, weight: weight)
    }
}

struct GameCard: ViewModifier {
    var color: Color = GameColors.cardSurface
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func gameCard(color: Color = GameColors.cardSurface, padding: CGFloat = 16) -> some View {
        modifier(GameCard(color: color, padding: padding))
    }

    func subjectBleed(_ subject: Subject?) -> some View {
        background {
            if let subject {
                LinearGradient(
                    colors: [subject.gameColor.opacity(0.15), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
            }
        }
    }

    func gamePageBackground() -> some View {
        background(GameColors.appBackground.ignoresSafeArea())
    }
}

struct XPStreakBar: View {
    let streak: Int
    let xp: Int

    var body: some View {
        HStack(spacing: 16) {
            Spacer()
            Label("\(streak)", systemImage: "flame.fill")
                .font(GameFont.caption(.semibold))
                .foregroundStyle(GameColors.streakFlame)
            Label("\(xp) XP", systemImage: "star.fill")
                .font(GameFont.caption(.semibold))
                .foregroundStyle(GameColors.xpGold)
        }
    }
}

struct SubjectBadge: View {
    let subject: Subject
    var suffix: String = ""

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: subject.gameIcon)
            Text(subject.displayName + (suffix.isEmpty ? "" : " · \(suffix)"))
        }
        .font(GameFont.caption())
        .foregroundStyle(subject.gameColor)
    }
}

struct BuzzButton: View {
    let subjectColor: Color
    let progress: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(subjectColor.opacity(0.15), lineWidth: 4)
                .frame(width: 232, height: 232)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress < 0.3 ? GameColors.incorrect : subjectColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 232, height: 232)

            Button(action: action) {
                Text("BUZZ ⚡")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 72)
                    .background(subjectColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: subjectColor.opacity(0.5), radius: 16, y: 6)
            }
            .buttonStyle(.plain)
            .scaleEffect(isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
    }
}

enum CoachCopy {
    static func timeGreeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation: String
        switch hour {
        case 5..<12: salutation = "Good morning"
        case 12..<17: salutation = "Good afternoon"
        default: salutation = "Good evening"
        }
        return "\(salutation), \(name)! 👋"
    }

    static func drillHeadline(correct: Int, total: Int) -> String {
        let ratio = total > 0 ? Double(correct) / Double(total) : 0
        switch ratio {
        case 1.0: return "Perfect Round! 🏆"
        case 0.8...: return "Great Round! 🎉"
        case 0.6...: return "Solid Work! 💪"
        case 0.4...: return "Getting There! 📈"
        default: return "Let's Keep Drilling 🔄"
        }
    }
}

// MARK: - Floating tab bar (iOS)

struct FloatingGameTabBar: View {
    @Binding var selection: Int
    let items: [(title: String, icon: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    withAnimation(.spring(response: 0.3)) { selection = index }
                    HapticManager.light()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 22, weight: selection == index ? .semibold : .regular))
                            .scaleEffect(selection == index ? 1.08 : 1.0)
                        if selection == index {
                            Text(item.title)
                                .font(GameFont.caption(.semibold))
                        }
                    }
                    .foregroundStyle(selection == index ? GameColors.tabAccent : GameColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .background(GameColors.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        .padding(.horizontal, 16)
    }
}

struct QuickDrillChip: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GameFont.caption(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(color.opacity(0.2))
                .foregroundStyle(color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
