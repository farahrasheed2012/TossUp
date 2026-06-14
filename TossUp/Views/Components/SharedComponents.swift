import SwiftUI

enum AppTheme {
    static let accent = Color.accentColor
    static let success = Color.green
    static let danger = Color.red
    static var pageBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }
    static var cardBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }
    static var cardBorder: Color {
        Color.primary.opacity(0.08)
    }
}

struct EncouragingHeader: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("You've got this, \(name)!")
                .font(.title2.bold())
            Text("Official DOE sample questions — practice makes perfect.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SubjectFilterBar: View {
    @Binding var selectedSubject: Subject?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", emoji: nil, isSelected: selectedSubject == nil) {
                    selectedSubject = nil
                }
                ForEach(Subject.allCases) { subject in
                    FilterChip(
                        title: subject.displayName,
                        emoji: subject.emoji,
                        isSelected: selectedSubject == subject
                    ) {
                        selectedSubject = selectedSubject == subject ? nil : subject
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let emoji: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji { Text(emoji) }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.accent.opacity(0.18) : AppTheme.cardBackground)
            .overlay(
                Capsule().stroke(isSelected ? AppTheme.accent : AppTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ChoiceButton: View {
    let choice: String
    let isCorrectHighlight: Bool
    let isDisabled: Bool
    let action: () -> Void

    private var letter: String {
        String(choice.prefix(1)).uppercased()
    }

    private var bodyText: String {
        if let idx = choice.firstIndex(of: ")") {
            return String(choice[choice.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        }
        return choice
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(letter)
                    .font(.headline.monospaced())
                    .frame(width: 28, height: 28)
                    .background(isCorrectHighlight ? AppTheme.success.opacity(0.25) : AppTheme.accent.opacity(0.15))
                    .clipShape(Circle())
                Text(bodyText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(isCorrectHighlight ? AppTheme.success.opacity(0.12) : AppTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCorrectHighlight ? AppTheme.success : AppTheme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct AccuracyRingView: View {
    let progress: Double
    let label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.title.bold())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 140, height: 140)
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
