import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case study
    case games
    case quiz
    case progress
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: return "Study"
        case .games: return "Games"
        case .quiz: return "Drill"
        case .progress: return "Journey"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .study: return "books.vertical"
        case .games: return "gamecontroller.fill"
        case .quiz: return "bolt.fill"
        case .progress: return "chart.bar.fill"
        case .settings: return "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var bank: QuestionBank
    @EnvironmentObject private var xp: XPManager
    #if os(macOS)
    @State private var selection: AppSection = .quiz
    @State private var miniGameCapturesKeyboard = false
    #else
    @State private var selection = 2
    #endif

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .focusable(!miniGameCapturesKeyboard)
            .navigationTitle("TossUp")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            NavigationStack {
                detail(for: selection)
                    .miniGameNavigationDestinations()
            }
            .gamePageBackground()
        }
        .navigationSplitViewStyle(.balanced)
        .onPreferenceChange(MiniGameKeyboardCaptureKey.self) { miniGameCapturesKeyboard = $0 }
        .onReceive(NotificationCenter.default.publisher(for: .startNewQuiz)) { _ in
            selection = .quiz
        }
        .onReceive(NotificationCenter.default.publisher(for: .showProgress)) { _ in
            selection = .progress
        }
        #else
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                NavigationStack {
                    StudyView()
                        .miniGameNavigationDestinations()
                }
                .tag(0)
                NavigationStack {
                    GamesTabView()
                        .miniGameNavigationDestinations()
                }
                .tag(1)
                NavigationStack {
                    QuizTabView()
                        .miniGameNavigationDestinations()
                }
                .tag(2)
                NavigationStack { ProgressTabView() }
                    .tag(3)
                NavigationStack { SettingsTabView() }
                    .tag(4)
            }
            .toolbar(.hidden, for: .tabBar)

            FloatingGameTabBar(
                selection: $selection,
                items: AppSection.allCases.map { ($0.title, $0.systemImage) }
            )
            .padding(.bottom, 8)
        }
        .gamePageBackground()
        #endif
    }

    #if os(macOS)
    @ViewBuilder
    private func detail(for section: AppSection) -> some View {
        switch section {
        case .study:
            StudyView()
        case .games:
            GamesTabView()
        case .quiz:
            QuizTabView()
        case .progress:
            ProgressTabView()
        case .settings:
            SettingsTabView()
        }
    }
    #endif
}
