import Foundation

@MainActor
final class XPManager: ObservableObject {
    static let shared = XPManager()

    private let xpKey = "totalXP"
    private let streakKey = "currentStreak"
    private let lastActivityKey = "xpLastActivityDate"

    @Published var totalXP: Int {
        didSet { UserDefaults.standard.set(totalXP, forKey: xpKey) }
    }

    @Published var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: streakKey) }
    }

    private init() {
        totalXP = UserDefaults.standard.integer(forKey: xpKey)
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
    }

    enum Award {
        case tossupCorrect
        case sessionComplete
        case perfectSession
        case miniGameComplete

        var points: Int {
            switch self {
            case .tossupCorrect: return 10
            case .sessionComplete: return 25
            case .perfectSession: return 50
            case .miniGameComplete: return 20
            }
        }
    }

    @discardableResult
    func award(_ award: Award) -> Int {
        let points = award.points
        totalXP += points
        recordActivity()
        return points
    }

    func recordActivity(on date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let lastRaw = UserDefaults.standard.object(forKey: lastActivityKey) as? Date {
            let last = calendar.startOfDay(for: lastRaw)
            let delta = calendar.dateComponents([.day], from: last, to: today).day ?? 0
            switch delta {
            case 0: break
            case 1: currentStreak += 1
            default: currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        UserDefaults.standard.set(today, forKey: lastActivityKey)
    }

    func resetProgress() {
        totalXP = 0
        currentStreak = 0
        UserDefaults.standard.removeObject(forKey: lastActivityKey)
    }
}
