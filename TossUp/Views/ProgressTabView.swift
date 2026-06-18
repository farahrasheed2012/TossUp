import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProgressViewModel()
    @ObservedObject private var xp = XPManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your NSB Journey 🚀")
                        .font(GameFont.largeTitle())
                        .foregroundStyle(AppTheme.primaryText)
                    HStack(spacing: 16) {
                        Label("\(xp.totalXP) XP", systemImage: "star.fill")
                            .foregroundStyle(GameColors.xpGold)
                        Label("\(max(xp.currentStreak, viewModel.currentStreak))-day streak", systemImage: "flame.fill")
                            .foregroundStyle(GameColors.streakFlame)
                    }
                    .font(GameFont.headline())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .gameCard()

                AccuracyRingView(progress: viewModel.overallAccuracy, label: "Overall")

                if viewModel.currentStreak > 0 {
                    Label("\(viewModel.currentStreak)-day streak", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }

                if let weakest = viewModel.weakestSubject {
                    Text("Focus on: \(weakest.displayName) \(weakest.emoji)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                }

                SectionCard(title: "By subject") {
                    VStack(spacing: 14) {
                        ForEach(Subject.allCases) { subject in
                            let value = viewModel.subjectAccuracy[subject] ?? 0
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(subject.emoji) \(subject.displayName)")
                                    Spacer()
                                    Text("\(Int(value * 100))%")
                                        .monospacedDigit()
                                }
                                ProgressView(value: value)
                                    .tint(subject.gameColor)
                            }
                        }
                    }
                }

                if !viewModel.sessions.isEmpty {
                    SectionCard(title: "Recent sessions") {
                        VStack(spacing: 10) {
                            ForEach(viewModel.sessions.prefix(10)) { session in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                        Text(session.subjects.map(\.displayName).joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(session.correctCount)/\(session.totalQuestions)")
                                        .font(.headline)
                                }
                            }
                        }
                    }
                } else {
                    Text("No drills yet — hit Drill and start a session!")
                        .font(GameFont.body())
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .gameCard()
                }
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Your Journey")
        .onAppear { viewModel.refresh(context: modelContext) }
    }
}
