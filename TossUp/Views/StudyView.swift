import SwiftUI

struct StudyView: View {
    @EnvironmentObject private var bank: QuestionBank
    @State private var selectedTopicIDs: Set<String> = []
    @State private var selectedSimpleSubjects: Set<Subject> = []
    @State private var searchText = ""
    @State private var showTopicFilter = false

    private var filteredQuestions: [NSBQuestion] {
        let topicPool = bank.questions(
            matchingTopicIDs: selectedTopicIDs,
            otherSubjects: selectedSimpleSubjects
        )
        guard !searchText.isEmpty else { return topicPool }
        return topicPool.filter { question in
            question.questionText.localizedCaseInsensitiveContains(searchText) ||
                question.displayTopicLabel.localizedCaseInsensitiveContains(searchText) ||
                question.displayContextLabel.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if bank.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading questions from PDFs…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = bank.loadError {
                ContentUnavailableView(
                    "Could not parse PDFs",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if bank.questions.isEmpty {
                ContentUnavailableView(
                    "No questions yet",
                    systemImage: "doc.text",
                    description: Text("Run download_nsb_pdfs.py and add PDFs to the app bundle.")
                )
            } else {
                VStack(spacing: 0) {
                    List {
                        Section {
                            ForEach(filteredQuestions.prefix(500)) { question in
                                NavigationLink {
                                    QuestionDetailView(question: question)
                                } label: {
                                    QuestionRow(question: question)
                                }
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(filteredQuestions.count) questions")
                                Text(TopicCatalog.compactSummary(
                                    topicIDs: selectedTopicIDs,
                                    simpleSubjects: selectedSimpleSubjects
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .textCase(nil)
                            .padding(.bottom, 4)
                        }
                    }
                    #if os(macOS)
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                    #endif
                }
            }
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Study")
        .searchable(text: $searchText, prompt: "Search questions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showTopicFilter = true
                } label: {
                    Label("Topics", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showTopicFilter) {
            TopicPickerView(
                selectedTopicIDs: $selectedTopicIDs,
                selectedSimpleSubjects: $selectedSimpleSubjects,
                bank: bank,
                showsFilterChrome: true,
                onDismiss: { showTopicFilter = false }
            )
        }
    }
}

private struct QuestionRow: View {
    let question: NSBQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(question.subject.emoji)
                Text(question.subject.displayName)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(question.type.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(question.questionText)
                .font(.body)
                .lineLimit(3)
            Text(question.displayContextLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct QuestionDetailView: View {
    let question: NSBQuestion
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(question.subject.emoji)
                    Text(question.subject.displayName)
                        .font(.headline)
                    Spacer()
                    Button {
                        readQuestion()
                    } label: {
                        Label("Read aloud", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                }

                Text(question.displayContextLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(question.questionText)
                    .font(.title3)
                    .fixedSize(horizontal: false, vertical: true)

                if let choices = question.choices {
                    ForEach(choices, id: \.self) { choice in
                        Text(choice)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle()
                    }
                }

                Text("Answer: \(AnswerExplainer.displayCorrectAnswer(for: question))")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)

                if settings.showDetailedExplanations {
                    AnswerFeedbackCard(
                        feedback: AnswerExplainer.feedback(
                            for: question,
                            userAnswer: question.correctAnswer,
                            wasCorrect: true
                        ),
                        showHeadline: false
                    )
                }

                if let topic = question.resolvedTopicID.flatMap({ TopicCatalog.topic(id: $0)?.name }) {
                    Text("Topic: \(topic)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Source: \(question.sourcePDF)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .contentColumn()
        }
        .background(AppTheme.pageBackground)
        .navigationTitle("Question")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if settings.readQuestionsAloud {
                readQuestion()
            }
        }
    }

    private func readQuestion() {
        if let choices = question.choices {
            SpeechManager.shared.speakQuestionWithChoices(question: question.questionText, choices: choices)
        } else {
            SpeechManager.shared.speakQuestion(question.questionText)
        }
    }
}
