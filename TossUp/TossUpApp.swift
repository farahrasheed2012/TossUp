import SwiftUI
import SwiftData

@main
struct TossUpApp: App {
    @StateObject private var bank = QuestionBank.shared
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var xp = XPManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(bank)
                .environmentObject(xp)
                .preferredColorScheme(settings.preferDarkMode ? .dark : nil)
                .task { await bank.loadIfNeeded() }
        }
        .modelContainer(for: [QuizSessionRecord.self, QuestionAttemptRecord.self])
        #if os(macOS)
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Quiz Session") {
                    NotificationCenter.default.post(name: .startNewQuiz, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Quiz") {
                Button("Skip Question") {
                    NotificationCenter.default.post(name: .skipQuestion, object: nil)
                }
                .keyboardShortcut(.escape, modifiers: [])
                Button("End Session") {
                    NotificationCenter.default.post(name: .endQuizSession, object: nil)
                }
                .keyboardShortcut(".", modifiers: .command)
            }
            CommandMenu("View") {
                Button("Progress") {
                    NotificationCenter.default.post(name: .showProgress, object: nil)
                }
            }
        }
        #endif
    }
}

extension Notification.Name {
    static let startNewQuiz = Notification.Name("TossUp.startNewQuiz")
    static let showProgress = Notification.Name("TossUp.showProgress")
    static let skipQuestion = Notification.Name("TossUp.skipQuestion")
    static let endQuizSession = Notification.Name("TossUp.endQuizSession")
}
