import SwiftUI

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case study
    case quiz
    case progress
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: return "Study"
        case .quiz: return "Drill"
        case .progress: return "Journey"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .study: return "books.vertical"
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
    #else
    @State private var selection = 1
    #endif

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("TossUp")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            NavigationStack {
                detail(for: selection)
            }
            .gamePageBackground()
        }
        .navigationSplitViewStyle(.balanced)
        .onReceive(NotificationCenter.default.publisher(for: .startNewQuiz)) { _ in
            selection = .quiz
        }
        .onReceive(NotificationCenter.default.publisher(for: .showProgress)) { _ in
            selection = .progress
        }
        #else
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                NavigationStack { StudyView() }
                    .tag(0)
                NavigationStack { QuizTabView() }
                    .tag(1)
                NavigationStack { ProgressTabView() }
                    .tag(2)
                NavigationStack { SettingsTabView() }
                    .tag(3)
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
