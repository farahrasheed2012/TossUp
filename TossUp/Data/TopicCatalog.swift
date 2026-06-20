import Foundation

/// Drill-down quiz topics for Chemistry, Biology, Math, and Physics.
/// Use each topic `id` when generating bundled JSON (`topicId` field) for Claude.
struct QuizTopic: Identifiable, Hashable {
    let id: String
    let subject: Subject
    let name: String
    /// Match `NSBQuestion.sourcePDF` when set.
    let sourceDeck: String?
    /// Hewitt-style section ids (e.g. `17.1`) when narrowing a deck.
    let sectionIDs: [String]?
    /// Parent topic id for nested UI (nil = top-level under subject).
    let parentID: String?

    var isAllTopic: Bool { id.hasSuffix("-all") }

    func matches(_ question: NSBQuestion) -> Bool {
        if isAllTopic {
            return question.subject == subject
        }
        if question.topicId == id {
            return true
        }
        if id == "chem-elements-of-chemistry" {
            return question.sourcePDF == NSBQuestion.elementsOfChemistryDeckID
        }
        if let resolved = question.resolvedTopicID, resolved == id {
            return true
        }
        return false
    }
}

enum TopicCatalog {
    static let drillDownSubjects: [Subject] = [.chemistry, .biology, .math, .physics]
    static let simpleSubjects: [Subject] = [.earthSpace]

    static func normalizedTopicIDs(_ ids: Set<String>) -> Set<String> {
        var result = ids
        if result.remove("chemistry-all") != nil { result.insert("chem-all") }
        if result.remove("biology-all") != nil { result.insert("bio-all") }
        if result.remove("physics-all") != nil { result.insert("phys-all") }
        return result
    }

    static func allTopicID(for subject: Subject) -> String {
        switch subject {
        case .chemistry: return "chem-all"
        case .biology: return "bio-all"
        case .math: return "math-all"
        case .physics: return "phys-all"
        default: return "\(subject.rawValue)-all"
        }
    }

    static func topics(for subject: Subject) -> [QuizTopic] {
        switch subject {
        case .chemistry: return chemistry
        case .biology: return biology
        case .math: return math
        case .physics: return physics
        default: return []
        }
    }

    static func topic(id: String) -> QuizTopic? {
        topicIndex[id]
    }

    static func topLevelTopics(for subject: Subject) -> [QuizTopic] {
        topics(for: subject).filter { $0.parentID == nil && !$0.isAllTopic }
    }

    static func childTopics(of parentID: String) -> [QuizTopic] {
        topics.values.filter { $0.parentID == parentID }.sorted { $0.name < $1.name }
    }

    static func isSubjectActive(
        _ subject: Subject,
        topicIDs: Set<String>,
        simpleSubjects: Set<Subject>
    ) -> Bool {
        if simpleSubjects.contains(subject) { return true }
        return topics(for: subject).contains { topicIDs.contains($0.id) }
    }

    static func selectionLabel(topicIDs: Set<String>, for subject: Subject) -> String {
        let allID = allTopicID(for: subject)
        if topicIDs.contains(allID) { return "All" }
        let names = topics(for: subject)
            .filter { topicIDs.contains($0.id) && !$0.isAllTopic }
            .map(\.name)
        if names.isEmpty { return "Off" }
        if names.count == 1 { return shortName(names[0]) }
        return "\(names.count) topics"
    }

    static func compactSummary(topicIDs: Set<String>, simpleSubjects: Set<Subject>) -> String {
        var parts: [String] = []
        for subject in drillDownSubjects where isSubjectActive(subject, topicIDs: topicIDs, simpleSubjects: simpleSubjects) {
            parts.append("\(subject.emoji) \(selectionLabel(topicIDs: topicIDs, for: subject))")
        }
        for subject in simpleSubjects.sorted(by: { $0.rawValue < $1.rawValue }) {
            parts.append("\(subject.emoji) \(subject.displayName)")
        }
        return parts.isEmpty ? "Tap a subject to begin" : parts.joined(separator: " · ")
    }

    private static func shortName(_ name: String) -> String {
        if name.count <= 28 { return name }
        return String(name.prefix(25)) + "…"
    }

    static var allSelectableSubjects: [Subject] {
        drillDownSubjects + simpleSubjects
    }

    static var allTopics: [QuizTopic] {
        Array(topics.values).sorted { lhs, rhs in
            if lhs.subject != rhs.subject { return lhs.subject.rawValue < rhs.subject.rawValue }
            return lhs.name < rhs.name
        }
    }

    // MARK: - Chemistry

    private static let chemistry: [QuizTopic] = {
        let all = QuizTopic(
            id: "chem-all",
            subject: .chemistry,
            name: "All Chemistry",
            sourceDeck: nil,
            sectionIDs: nil,
            parentID: nil
        )
        let elements = QuizTopic(
            id: "chem-elements-of-chemistry",
            subject: .chemistry,
            name: "Elements of Chemistry (Hewitt Ch 17)",
            sourceDeck: NSBQuestion.elementsOfChemistryDeckID,
            sectionIDs: nil,
            parentID: nil
        )
        let sections: [QuizTopic] = [
            ("17.1", "Chemistry Is Known as the Central Science"),
            ("17.2", "The Submicroscopic World Is Super-Small"),
            ("17.3", "The Phase of Matter Can Change"),
            ("17.4", "Matter Has Physical and Chemical Properties"),
            ("17.5", "Determining Physical and Chemical Changes"),
            ("17.6", "The Periodic Table"),
            ("17.7", "Elements Can Combine to Form Compounds"),
            ("17.8", "There Is a System for Naming Compounds"),
        ].map { section, title in
            QuizTopic(
                id: "chem-elements-\(section.replacingOccurrences(of: ".", with: "-"))",
                subject: .chemistry,
                name: title,
                sourceDeck: NSBQuestion.elementsOfChemistryDeckID,
                sectionIDs: [section],
                parentID: elements.id
            )
        }
        let nsb: [QuizTopic] = [
            ("chem-atoms-periodic-table", "Atoms & Periodic Table"),
            ("chem-bonding", "Chemical Bonding"),
            ("chem-reactions", "Chemical Reactions"),
            ("chem-solutions-acids", "Solutions & Acids/Bases"),
            ("chem-stoichiometry", "Stoichiometry & Moles"),
            ("chem-states-of-matter", "States of Matter"),
            ("chem-lab-measurement", "Lab & Measurement"),
        ].map { id, name in
            QuizTopic(id: id, subject: .chemistry, name: name, sourceDeck: nil, sectionIDs: nil, parentID: nil)
        }
        return [all, elements] + sections + nsb
    }()

    // MARK: - Biology

    private static let biology: [QuizTopic] = [
        QuizTopic(id: "bio-all", subject: .biology, name: "All Biology", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-cells", subject: .biology, name: "Cell Structure & Organelles", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-energy", subject: .biology, name: "Photosynthesis & Cellular Respiration", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-genetics", subject: .biology, name: "DNA, Genes & Chromosomes", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-inheritance", subject: .biology, name: "Punnett Squares & Inheritance", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-evolution", subject: .biology, name: "Evolution & Classification", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-ecology", subject: .biology, name: "Ecology & Ecosystems", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-body-systems", subject: .biology, name: "Human Body Systems", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "bio-microbes", subject: .biology, name: "Bacteria, Viruses & Disease", sourceDeck: nil, sectionIDs: nil, parentID: nil),
    ]

    // MARK: - Math

    private static let math: [QuizTopic] = [
        QuizTopic(id: "math-all", subject: .math, name: "All Math", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-number-sense", subject: .math, name: "Number Sense & PEMDAS", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-fractions-percent", subject: .math, name: "Fractions, Decimals & Percent", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-ratios-proportions", subject: .math, name: "Ratios & Proportions", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-exponents-sci-notation", subject: .math, name: "Exponents & Scientific Notation", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-linear-equations", subject: .math, name: "Linear Equations & Word Problems", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-graphs-slope", subject: .math, name: "Graphs, Slope & Functions", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-probability-stats", subject: .math, name: "Probability & Statistics", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "math-radicals", subject: .math, name: "Square Roots & Radicals", sourceDeck: nil, sectionIDs: nil, parentID: nil),
    ]

    // MARK: - Physics

    private static let physics: [QuizTopic] = [
        QuizTopic(id: "phys-all", subject: .physics, name: "All Physics", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "phys-forces", subject: .physics, name: "Forces & Newton's Laws", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "phys-motion", subject: .physics, name: "Motion & Kinematics", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "phys-energy", subject: .physics, name: "Work, Energy & Conservation", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "phys-waves", subject: .physics, name: "Waves, Sound & Light", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "phys-electricity", subject: .physics, name: "Circuits & Electricity", sourceDeck: nil, sectionIDs: nil, parentID: nil),
        QuizTopic(id: "phys-magnetism", subject: .physics, name: "Magnetism", sourceDeck: nil, sectionIDs: nil, parentID: nil),
    ]

    private static let topics: [String: QuizTopic] = {
        Dictionary(uniqueKeysWithValues: (chemistry + biology + math + physics).map { ($0.id, $0) })
    }()

    private static let topicIndex = topics
}
