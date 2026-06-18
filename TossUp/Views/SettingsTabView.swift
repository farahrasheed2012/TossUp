import SwiftUI
import SwiftData

struct SettingsTabView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var bank: QuestionBank
    @State private var showResetConfirm = false
    @State private var showResetXPConfirm = false

    var body: some View {
        #if os(iOS)
        iosBody
        #else
        macBody
        #endif
    }

    private var iosBody: some View {
        ScrollView {
            VStack(spacing: 14) {
                settingsCard {
                    Toggle(isOn: $settings.preferDarkMode) {
                        Label("Dark mode (game look)", systemImage: "moon.fill")
                    }
                }
                settingsCard {
                    Toggle("Read questions aloud", isOn: $settings.readQuestionsAloud)
                    Text("TTS like a real Science Bowl moderator.")
                        .font(GameFont.caption())
                        .foregroundStyle(AppTheme.secondaryText)
                }
                settingsCard {
                    TextField("Student name", text: $settings.studentName)
                    Toggle("Detailed answer explanations", isOn: $settings.showDetailedExplanations)
                }
                settingsCard {
                    quizDefaults
                }
                settingsCard {
                    subjectToggles
                }
                settingsCard {
                    bankInfo
                }
                settingsCard {
                    Button("Reset XP and streak", role: .destructive) {
                        showResetXPConfirm = true
                    }
                    Button("Reset drill progress", role: .destructive) {
                        showResetConfirm = true
                    }
                }
                Text("\"The buzzer waits for no one.\" 🎯\nTossUp · Soha's Edition")
                    .font(GameFont.caption())
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(20)
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Settings ⚙")
        .confirmationDialog("Reset all quiz progress?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                settings.resetProgress(modelContext: modelContext)
            }
        }
        .confirmationDialog("Reset XP and streak?", isPresented: $showResetXPConfirm) {
            Button("Reset", role: .destructive) {
                settings.resetXPAndStreak()
            }
        }
    }

    private var macBody: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark mode (game look)", isOn: $settings.preferDarkMode)
            }
            Section("Audio") {
                Toggle("Read questions aloud", isOn: $settings.readQuestionsAloud)
            }
            Section("Student") {
                TextField("Name", text: $settings.studentName)
            }
            Section("Learning") {
                Toggle("Detailed answer explanations", isOn: $settings.showDetailedExplanations)
            }
            Section("Quiz defaults") { quizDefaults }
            Section("Subjects in rotation") { subjectToggles }
            Section("Question bank") { bankInfo }
            Section {
                Button("Reset XP and streak", role: .destructive) { showResetXPConfirm = true }
                Button("Reset progress", role: .destructive) { showResetConfirm = true }
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
        .confirmationDialog("Reset XP and streak?", isPresented: $showResetXPConfirm) {
            Button("Reset", role: .destructive) {
                settings.resetXPAndStreak()
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .gameCard()
    }

    @ViewBuilder
    private var quizDefaults: some View {
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
            .font(GameFont.caption())
            .foregroundStyle(AppTheme.secondaryText)
    }

    @ViewBuilder
    private var subjectToggles: some View {
        ForEach(Subject.allCases) { subject in
            Toggle(subject.displayName, isOn: Binding(
                get: { settings.isSubjectEnabled(subject) },
                set: { _ in settings.toggleSubject(subject) }
            ))
        }
    }

    @ViewBuilder
    private var bankInfo: some View {
        LabeledContent("Source PDFs", value: "\(bank.sourcePDFCount)")
        LabeledContent("Loaded questions", value: "\(bank.questions.count)")
        if let parsed = bank.lastParsedAt {
            LabeledContent("Last parsed", value: parsed.formatted())
        }
        Button("Re-parse PDFs") {
            Task { await bank.reload() }
        }
    }
}
