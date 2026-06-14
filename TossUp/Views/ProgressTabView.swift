import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                                    .tint(AppTheme.accent)
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
                    Text("Complete a quiz to see your progress here.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .cardStyle()
                }
            }
            .padding(24)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Progress")
        .onAppear { viewModel.refresh(context: modelContext) }
    }
}
