#if os(iOS)
import UIKit

enum HapticManager {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
#else
enum HapticManager {
    static func success() {}
    static func error() {}
    static func rigid() {}
    static func medium() {}
    static func light() {}
}
#endif
