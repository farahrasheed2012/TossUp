import SwiftUI

struct AnswerFeedbackCard: View {
    let feedback: AnswerFeedback
    var showHeadline = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showHeadline {
                Text(feedback.headline)
                    .font(.title2.bold())
                    .foregroundStyle(headlineColor)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text(feedback.correctAnswerDisplay)
                        .font(.body.weight(.semibold))
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.success)
                }

                if let userDisplay = feedback.userAnswerDisplay {
                    Label {
                        Text(userDisplay)
                            .font(.body)
                    } icon: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.danger)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Explanation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(Array(feedback.explanation.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, paragraph in
                    Text(.init(paragraph))
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !feedback.distractorNotes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why the others don't fit")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(feedback.distractorNotes, id: \.self) { note in
                        Text(note)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var headlineColor: Color {
        if feedback.headline == "Skipped" { return .orange }
        return feedback.wasCorrect ? AppTheme.success : AppTheme.danger
    }
}
