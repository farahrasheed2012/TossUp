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
        case .quiz: return "Quiz"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .study: return "books.vertical"
        case .quiz: return "timer"
        case .progress: return "chart.bar.fill"
        case .settings: return "gearshape"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var bank: QuestionBank
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
            .background(AppTheme.pageBackground)
        }
        .navigationSplitViewStyle(.balanced)
        .onReceive(NotificationCenter.default.publisher(for: .startNewQuiz)) { _ in
            selection = .quiz
        }
        .onReceive(NotificationCenter.default.publisher(for: .showProgress)) { _ in
            selection = .progress
        }
        #else
        TabView(selection: $selection) {
            NavigationStack { StudyView() }
                .tabItem { Label("Study", systemImage: "books.vertical") }
                .tag(0)
            NavigationStack { QuizTabView() }
                .tabItem { Label("Quiz", systemImage: "timer") }
                .tag(1)
            NavigationStack { ProgressTabView() }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
                .tag(2)
            NavigationStack { SettingsTabView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(3)
        }
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
