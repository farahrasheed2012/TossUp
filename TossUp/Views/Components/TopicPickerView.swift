import SwiftUI

/// Subject list with optional topic drill-down.
struct TopicPickerView: View {
    @Binding var selectedTopicIDs: Set<String>
    @Binding var selectedSimpleSubjects: Set<Subject>
    let bank: QuestionBank
    var showCounts: Bool = true
    var showsFilterChrome: Bool = false
    var onDismiss: (() -> Void)?

    @State private var refineSubject: Subject?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        Group {
            if showsFilterChrome {
                NavigationStack(path: $navigationPath) {
                    pickerContent
                        .padding(20)
                        .navigationTitle("Filter")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            if let onDismiss {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done", action: onDismiss)
                                }
                            }
                        }
                        .navigationDestination(for: Subject.self) { subject in
                            subjectTopicsList(for: subject)
                        }
                }
                #if os(macOS)
                .frame(minWidth: 400, minHeight: 420)
                #endif
            } else {
                pickerContent
                    .sheet(item: $refineSubject) { subject in
                        NavigationStack {
                            subjectTopicsList(for: subject)
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") { refineSubject = nil }
                                    }
                                }
                        }
                        #if os(macOS)
                        .frame(minWidth: 440, minHeight: 480)
                        #endif
                    }
            }
        }
    }

    private var pickerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(TopicCatalog.allSelectableSubjects) { subject in
                SubjectRow(
                    subject: subject,
                    isOn: TopicCatalog.isSubjectActive(
                        subject,
                        topicIDs: selectedTopicIDs,
                        simpleSubjects: selectedSimpleSubjects
                    ),
                    detail: rowDetail(for: subject),
                    count: rowCount(for: subject),
                    isDrillDown: TopicCatalog.drillDownSubjects.contains(subject),
                    onToggle: { toggleSubject(subject) },
                    onRefine: { openRefine(for: subject) }
                )
            }

            Text(TopicCatalog.compactSummary(
                topicIDs: selectedTopicIDs,
                simpleSubjects: selectedSimpleSubjects
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func openRefine(for subject: Subject) {
        if showsFilterChrome {
            navigationPath.append(subject)
        } else {
            refineSubject = subject
        }
    }

    private func subjectTopicsList(for subject: Subject) -> some View {
        SubjectTopicsListView(
            subject: subject,
            selectedTopicIDs: $selectedTopicIDs,
            bank: bank,
            showCounts: showCounts
        )
    }

    private func rowDetail(for subject: Subject) -> String {
        guard TopicCatalog.isSubjectActive(
            subject,
            topicIDs: selectedTopicIDs,
            simpleSubjects: selectedSimpleSubjects
        ) else { return "Off" }

        if TopicCatalog.simpleSubjects.contains(subject) {
            return "All"
        }
        return TopicCatalog.selectionLabel(topicIDs: selectedTopicIDs, for: subject)
    }

    private func rowCount(for subject: Subject) -> Int {
        if TopicCatalog.simpleSubjects.contains(subject) {
            return bank.questions(subjects: [subject]).count
        }
        return bank.questions(matchingTopicIDs: topicSelection(for: subject)).count
    }

    private func topicSelection(for subject: Subject) -> Set<String> {
        let ids = Set(TopicCatalog.topics(for: subject).map(\.id))
        let chosen = selectedTopicIDs.intersection(ids)
        if chosen.isEmpty {
            return Set([TopicCatalog.allTopicID(for: subject)])
        }
        return chosen
    }

    private func toggleSubject(_ subject: Subject) {
        if TopicCatalog.simpleSubjects.contains(subject) {
            updateSimpleSubjects { subjects in
                if subjects.contains(subject) {
                    subjects.remove(subject)
                } else {
                    subjects.insert(subject)
                }
            }
            return
        }

        if TopicCatalog.isSubjectActive(subject, topicIDs: selectedTopicIDs, simpleSubjects: selectedSimpleSubjects) {
            updateTopicIDs { ids in
                clearSubject(subject, from: &ids)
            }
        } else {
            updateTopicIDs { ids in
                clearSubject(subject, from: &ids)
                ids.insert(TopicCatalog.allTopicID(for: subject))
            }
        }
    }

    private func updateTopicIDs(_ transform: (inout Set<String>) -> Void) {
        var next = selectedTopicIDs
        transform(&next)
        selectedTopicIDs = next
    }

    private func updateSimpleSubjects(_ transform: (inout Set<Subject>) -> Void) {
        var next = selectedSimpleSubjects
        transform(&next)
        selectedSimpleSubjects = next
    }

    private func clearSubject(_ subject: Subject, from ids: inout Set<String>) {
        for topic in TopicCatalog.topics(for: subject) {
            ids.remove(topic.id)
        }
    }
}

private struct SubjectRow: View {
    let subject: Subject
    let isOn: Bool
    let detail: String
    let count: Int
    let isDrillDown: Bool
    let onToggle: () -> Void
    let onRefine: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Text(subject.emoji)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(subject.displayName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        if isOn {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(count > 0 ? Color.secondary : Color.orange)
                        .monospacedDigit()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isDrillDown && isOn {
                Button(action: onRefine) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Choose topics")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isOn ? AppTheme.accent.opacity(0.1) : Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isOn ? AppTheme.accent.opacity(0.25) : Color.clear, lineWidth: 1)
        }
    }
}

private struct SubjectTopicsListView: View {
    let subject: Subject
    @Binding var selectedTopicIDs: Set<String>
    let bank: QuestionBank
    let showCounts: Bool

    @State private var expandedTopicIDs: Set<String> = []

    private var allTopicID: String { TopicCatalog.allTopicID(for: subject) }

    var body: some View {
        List {
            if let allTopic = TopicCatalog.topic(id: allTopicID) {
                topicRow(allTopic)
            }

            ForEach(TopicCatalog.topLevelTopics(for: subject)) { topic in
                let children = TopicCatalog.childTopics(of: topic.id)
                if children.isEmpty {
                    topicRow(topic)
                } else {
                    expandableTopicGroup(topic: topic, children: children)
                }
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #endif
        .navigationTitle("\(subject.emoji) \(subject.displayName)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Select all") { selectAll() }
            }
        }
    }

    @ViewBuilder
    private func expandableTopicGroup(topic: QuizTopic, children: [QuizTopic]) -> some View {
        let isExpanded = expandedTopicIDs.contains(topic.id)

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedTopicIDs.remove(topic.id)
                        } else {
                            expandedTopicIDs.insert(topic.id)
                        }
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Collapse sections" : "Expand sections")

                Button {
                    toggle(topic)
                } label: {
                    topicLabel(topic)
                }
                #if os(macOS)
                .buttonStyle(.borderless)
                #else
                .buttonStyle(.plain)
                #endif
            }

            if isExpanded {
                ForEach(children) { child in
                    topicRow(child, indented: true)
                }
            }
        }
    }

    @ViewBuilder
    private func topicRow(_ topic: QuizTopic, indented: Bool = false) -> some View {
        Button {
            toggle(topic)
        } label: {
            HStack {
                if indented {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                topicLabel(topic)
            }
            .contentShape(Rectangle())
        }
        #if os(macOS)
        .buttonStyle(.borderless)
        #else
        .buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    private func topicLabel(_ topic: QuizTopic) -> some View {
        let count = bank.count(for: topic.id)
        let isSelected = selectedTopicIDs.contains(topic.id)

        HStack {
            Text(topic.name)
                .foregroundStyle(.primary)
            Spacer()
            if showCounts {
                Text(count == 0 ? "—" : "\(count)")
                    .font(.caption)
                    .foregroundStyle(count == 0 ? .tertiary : .secondary)
            }
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? AppTheme.accent : Color.secondary.opacity(0.4))
        }
    }

    private func selectAll() {
        updateTopicIDs { ids in
            clearSubject(from: &ids)
            ids.insert(allTopicID)
        }
    }

    private func toggle(_ topic: QuizTopic) {
        updateTopicIDs { ids in
            if topic.isAllTopic {
                if ids.contains(topic.id) {
                    ids.remove(topic.id)
                } else {
                    clearSubject(from: &ids)
                    ids.insert(topic.id)
                }
                return
            }

            if ids.contains(topic.id) {
                ids.remove(topic.id)
            } else {
                ids.remove(allTopicID)
                ids.insert(topic.id)
            }
        }
    }

    private func updateTopicIDs(_ transform: (inout Set<String>) -> Void) {
        var next = selectedTopicIDs
        transform(&next)
        selectedTopicIDs = next
    }

    private func clearSubject(from ids: inout Set<String>) {
        for topic in TopicCatalog.topics(for: subject) {
            ids.remove(topic.id)
        }
    }
}
