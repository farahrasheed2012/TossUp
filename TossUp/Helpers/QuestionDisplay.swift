import Foundation

extension NSBQuestion {
    static let elementsOfChemistryDeckID = "Hewitt-Ch17"
    static let elementsOfChemistryTopic = "Elements of Chemistry"

    private static let elementsOfChemistrySections: [String: String] = [
        "17.1": "Chemistry Is Known as the Central Science",
        "17.2": "The Submicroscopic World Is Super-Small",
        "17.3": "The Phase of Matter Can Change",
        "17.4": "Matter Has Physical and Chemical Properties",
        "17.5": "Determining Physical and Chemical Changes",
        "17.6": "The Periodic Table",
        "17.7": "Elements Can Combine to Form Compounds",
        "17.8": "There Is a System for Naming Compounds",
    ]

    var bundledTopicTitle: String? {
        switch sourcePDF {
        case Self.elementsOfChemistryDeckID:
            return Self.elementsOfChemistryTopic
        default:
            return nil
        }
    }

    var sectionTopicTitle: String? {
        guard let sectionID = hewittSectionID else { return nil }
        return Self.elementsOfChemistrySections[sectionID]
    }

    /// User-facing topic line for lists and quiz headers.
    var displayTopicLabel: String {
        if let sectionTopicTitle {
            return sectionTopicTitle
        }
        if let bundledTopicTitle {
            return bundledTopicTitle
        }
        return round
    }

    /// Toss-up/bonus plus section topic when available.
    var displayContextLabel: String {
        if let sectionTopicTitle {
            let kind = round.lowercased().hasPrefix("bonus") ? "Bonus" : "Toss-Up"
            return "\(kind) · \(sectionTopicTitle)"
        }
        if let bundledTopicTitle {
            return bundledTopicTitle
        }
        return round
    }

    private var hewittSectionID: String? {
        guard sourcePDF == Self.elementsOfChemistryDeckID else { return nil }
        guard let markerRange = round.range(of: "§") else { return nil }
        let remainder = round[markerRange.upperBound...].trimmingCharacters(in: .whitespaces)
        return remainder.split(separator: " ").first.map(String.init)
    }

    /// Explicit JSON topic or inferred Hewitt section topic.
    var resolvedTopicID: String? {
        if let topicId { return topicId }
        guard sourcePDF == Self.elementsOfChemistryDeckID else { return nil }
        if let section = hewittSectionID {
            return "chem-elements-\(section.replacingOccurrences(of: ".", with: "-"))"
        }
        return "chem-elements-of-chemistry"
    }
}
