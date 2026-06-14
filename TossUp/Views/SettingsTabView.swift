import SwiftUI
import SwiftData

struct SettingsTabView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var bank: QuestionBank
    @State private var showResetConfirm = false

    var body: some View {
        Form {
            Section("Audio") {
                Toggle("Read questions aloud", isOn: $settings.readQuestionsAloud)
                Text("Uses text-to-speech like a real Science Bowl moderator. Tap the speaker icon to replay.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Student") {
                TextField("Name", text: $settings.studentName)
            }

            Section("Quiz defaults") {
                Picker("Timer preset", selection: Binding(
                    get: { settings.timerPreset },
                    set: { settings.timerPreset = $0 }
                )) {
                    ForEach(TimerPreset.allCases) { preset in
                        Text(preset.label).tag(preset)
                    }
                }

                Picker("Default length", selection: Binding(
                    get: { settings.defaultQuizLength },
                    set: { settings.defaultQuizLength = $0 }
                )) {
                    ForEach(QuizLength.allCases) { length in
                        Text(length.label).tag(length)
                    }
                }

                Slider(value: $settings.autoAdvanceDelay, in: 0.5...3, step: 0.5) {
                    Text("Auto-advance delay")
                }
                Text("\(settings.autoAdvanceDelay, specifier: "%.1f") seconds after each answer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Subjects in rotation") {
                ForEach(Subject.allCases) { subject in
                    Toggle(subject.displayName, isOn: Binding(
                        get: { settings.isSubjectEnabled(subject) },
                        set: { _ in settings.toggleSubject(subject) }
                    ))
                }
            }

            Section("Question bank") {
                LabeledContent("Source PDFs", value: "\(bank.sourcePDFCount)")
                LabeledContent("Loaded questions", value: "\(bank.questions.count)")
                if let parsed = bank.lastParsedAt {
                    LabeledContent("Last parsed", value: parsed.formatted())
                }
                Button("Re-parse PDFs") {
                    Task { await bank.reload() }
                }
            }

            Section {
                Button("Reset progress", role: .destructive) {
                    showResetConfirm = true
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .contentColumn()
        .background(AppTheme.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Reset all quiz progress?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                settings.resetProgress(modelContext: modelContext)
            }
        }
    }
}
