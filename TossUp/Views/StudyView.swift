import SwiftUI

struct StudyView: View {
    @EnvironmentObject private var bank: QuestionBank
    @State private var selectedSubject: Subject?
    @State private var searchText = ""

    private var filteredQuestions: [NSBQuestion] {
        bank.questions.filter { question in
            let subjectOK = selectedSubject.map { question.subject == $0 } ?? true
            let searchOK = searchText.isEmpty ||
                question.questionText.localizedCaseInsensitiveContains(searchText) ||
                question.round.localizedCaseInsensitiveContains(searchText)
            return subjectOK && searchOK
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
                    VStack(alignment: .leading, spacing: 12) {
                        EncouragingHeader(name: SettingsStore.shared.studentName)
                        SubjectFilterBar(selectedSubject: $selectedSubject)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)

                    List {
                        Section("\(filteredQuestions.count) questions") {
                            ForEach(filteredQuestions.prefix(500)) { question in
                                NavigationLink {
                                    QuestionDetailView(question: question)
                                } label: {
                                    QuestionRow(question: question)
                                }
                            }
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
            Text(question.round)
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

                Text(question.round)
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

                Text("Answer: \(question.correctAnswer)")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accent)

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
