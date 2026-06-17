import Foundation

/// Generates tutor-style, multi-paragraph explanations offline from question content.
enum AIStyleExplainer {

    static func longExplanation(
        for question: NSBQuestion,
        userAnswer: String,
        wasCorrect: Bool,
        wasSkipped: Bool = false
    ) -> String {
        if let bundled = ExplanationLibrary.shared.lookup(for: question) {
            return bundled
        }

        var paragraphs: [String] = []

        let topics = detectTopics(in: question.questionText, subject: question.subject)
        paragraphs.append(openingContext(for: question, topics: topics))

        switch question.type {
        case .multipleChoice:
            paragraphs.append(contentsOf: multipleChoiceBody(
                for: question,
                userAnswer: userAnswer,
                wasCorrect: wasCorrect,
                wasSkipped: wasSkipped
            ))
        case .shortAnswer:
            paragraphs.append(contentsOf: shortAnswerBody(
                for: question,
                userAnswer: userAnswer,
                wasCorrect: wasCorrect,
                wasSkipped: wasSkipped
            ))
        }

        paragraphs.append(closingStudyNote(for: question, wasCorrect: wasCorrect))

        return paragraphs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    static func allDistractorNotes(for question: NSBQuestion, correctLetter: String) -> [String] {
        guard question.type == .multipleChoice, let choices = question.choices else { return [] }
        return ["W", "X", "Y", "Z"].compactMap { letter in
            guard letter != correctLetter.uppercased() else { return nil }
            let body = choiceBody(for: letter, in: choices)
            guard !body.isEmpty else { return nil }
            return "**\(letter))** \(body) — \(whyNotChoice(body: body, letter: letter, question: question, correctLetter: correctLetter))"
        }
    }

    // MARK: - Multiple choice

    private static func multipleChoiceBody(
        for question: NSBQuestion,
        userAnswer: String,
        wasCorrect: Bool,
        wasSkipped: Bool
    ) -> [String] {
        let choices = question.choices ?? []
        let correctLetter = question.correctAnswer.uppercased()
        let correctText = choiceBody(for: correctLetter, in: choices)
        let userLetter = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let userText = choiceBody(for: userLetter, in: choices)

        var parts: [String] = []

        parts.append("""
        **The correct answer is \(correctLetter)) \(correctText).** \
        \(expandCorrectChoice(correctText, question: question))
        """)

        if wasCorrect {
            parts.append("""
            You identified the best match. In Science Bowl multiple choice, read the stem twice and \
            look for the option that answers *exactly* what was asked — not just a related fact. \
            \(correctLetter)) is the most precise fit here.
            """)
        } else if wasSkipped {
            parts.append("""
            You chose to **skip** this question. Skipping still shows the answer so you can learn it — \
            use skip when you're completely stuck, then study the explanation before your next session.
            """)
        } else if userLetter.isEmpty {
            parts.append("""
            No answer was submitted before time ran out. On timed toss-ups, trust your first strong \
            instinct if you've eliminated clearly wrong choices — hesitation often costs more than an \
            educated guess in NSB.
            """)
        } else if userLetter != correctLetter, !userText.isEmpty {
            parts.append("""
            You selected **\(userLetter)) \(userText)**. That choice is tempting because \
            \(whyNotChoice(body: userText, letter: userLetter, question: question, correctLetter: correctLetter)) \
            However, the moderator is looking for the answer that directly satisfies the question stem.
            """)
        }

        if choices.count >= 4 {
            parts.append("""
            **Reviewing all four choices:** \
            \(reviewAllChoices(question: question, correctLetter: correctLetter))
            """)
        }

        return parts
    }

    // MARK: - Short answer

    private static func shortAnswerBody(
        for question: NSBQuestion,
        userAnswer: String,
        wasCorrect: Bool,
        wasSkipped: Bool
    ) -> [String] {
        let answer = question.correctAnswer
        let trimmedUser = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts: [String] = []

        parts.append("""
        **The accepted answer is \(answer).** \
        \(expandShortAnswer(answer, question: question))
        """)

        if let math = detailedMathWalkthrough(for: question) {
            parts.append(math)
        }

        if wasCorrect {
            parts.append("""
            Your response matches what moderators expect. Short-answer scoring in NSB allows minor \
            wording differences, but the core scientific term or value must be correct. Well done.
            """)
        } else if wasSkipped {
            parts.append("""
            You **skipped** this question. Read the explanation below, then try buzzing in on similar \
            toss-ups during your next practice round.
            """)
        } else if trimmedUser.isEmpty {
            parts.append("""
            Buzzing in without an answer ready is a common timing mistake. For short answer, \
            practice saying the answer out loud as soon as you recognize the question type.
            """)
        } else {
            parts.append("""
            You said **\(trimmedUser)**. Moderators compare your response to the official answer \
            **\(answer)**. \(contrastShortAnswers(user: trimmedUser, correct: answer))
            """)
        }

        return parts
    }

    // MARK: - Opening & closing

    private static func openingContext(for question: NSBQuestion, topics: [ScienceTopic]) -> String {
        let subjectName = question.subject.displayName
        if let primary = topics.first {
            return """
            This \(subjectName) question tests your understanding of **\(primary.label)**. \
            \(primary.contextSentence) \
            Questions like this appear often in official DOE middle-school sample rounds.
            """
        }
        return """
        This \(subjectName) question asks you to apply core concepts from the middle-school \
        Science Bowl curriculum. Read the stem carefully — NSB questions often include a clue \
        word that points directly to the right answer.
        """
    }

    private static func closingStudyNote(for question: NSBQuestion, wasCorrect: Bool) -> String {
        let hook = memoryHook(for: question)
        if wasCorrect {
            return "**Keep practicing:** \(hook)"
        }
        return "**For next time:** \(hook) \(subjectDeepTip(for: question.subject))"
    }

    // MARK: - Topic detection

    private enum ScienceTopic: Equatable {
        case mitochondria, photosynthesis, cellStructure, genetics, ecology, humanBody
        case atoms, periodicTable, bonding, reactions, acidsBases
        case forces, energy, waves, electricity, motion
        case geology, astronomy, weather, waterCycle
        case arithmetic, algebra, geometry

        var label: String {
            switch self {
            case .mitochondria: return "cellular respiration and mitochondria"
            case .photosynthesis: return "photosynthesis"
            case .cellStructure: return "cell structure and organelles"
            case .genetics: return "genetics and heredity"
            case .ecology: return "ecology and ecosystems"
            case .humanBody: return "human body systems"
            case .atoms: return "atomic structure"
            case .periodicTable: return "the periodic table"
            case .bonding: return "chemical bonding"
            case .reactions: return "chemical reactions"
            case .acidsBases: return "acids, bases, and pH"
            case .forces: return "forces and Newton's laws"
            case .energy: return "energy and work"
            case .waves: return "waves and sound/light"
            case .electricity: return "electricity and circuits"
            case .motion: return "motion and kinematics"
            case .geology: return "geology and Earth processes"
            case .astronomy: return "astronomy and the solar system"
            case .weather: return "weather and atmosphere"
            case .waterCycle: return "the water cycle"
            case .arithmetic: return "arithmetic computation"
            case .algebra: return "algebraic reasoning"
            case .geometry: return "geometry and measurement"
            }
        }

        var contextSentence: String {
            switch self {
            case .mitochondria:
                return "Mitochondria convert food energy into ATP — the molecule cells use for work."
            case .photosynthesis:
                return "Plants and some bacteria capture light energy to build glucose from CO₂ and water."
            case .cellStructure:
                return "Knowing which organelle does which job is foundational for Life Science rounds."
            case .genetics:
                return "DNA, genes, alleles, and inheritance patterns are high-frequency NSB topics."
            case .ecology:
                return "Food webs, populations, and biomes connect organisms to their environment."
            case .humanBody:
                return "Organ systems and how they cooperate appear in both toss-ups and bonuses."
            case .atoms:
                return "Protons, neutrons, electrons, and isotopes underpin most Physical Science questions."
            case .periodicTable:
                return "Groups and periods predict how elements behave in reactions."
            case .bonding:
                return "Ionic vs covalent bonding explains how compounds form and why they have certain properties."
            case .reactions:
                return "Balancing equations and recognizing reaction types is essential for Chemistry rounds."
            case .acidsBases:
                return "pH scale, H⁺/OH⁻ concentration, and neutralization come up repeatedly."
            case .forces:
                return "Newton's laws connect force, mass, and acceleration — always watch your units."
            case .energy:
                return "Kinetic vs potential energy and conservation laws are classic buzzer topics."
            case .waves:
                return "Frequency, wavelength, and amplitude describe how energy travels through media."
            case .electricity:
                return "Current, voltage, resistance, and Ohm's law appear in many Energy questions."
            case .motion:
                return "Speed, velocity, acceleration, and graphs of motion are fair game at middle-school level."
            case .geology:
                return "Plate tectonics, rock types, and Earth's layers explain our planet's surface."
            case .astronomy:
                return "Planets, moons, phases, and orbital mechanics define Earth & Space Science."
            case .weather:
                return "Fronts, pressure systems, and humidity drive day-to-day weather patterns."
            case .waterCycle:
                return "Evaporation, condensation, precipitation, and collection move water through Earth systems."
            case .arithmetic:
                return "Speed and accuracy under a 5-second clock separate strong math players."
            case .algebra:
                return "Setting up equations from word problems is as important as solving them."
            case .geometry:
                return "Area, volume, angles, and the Pythagorean theorem appear in many rounds."
            }
        }
    }

    private static func detectTopics(in text: String, subject: Subject) -> [ScienceTopic] {
        let lower = text.lowercased()
        var found: [ScienceTopic] = []

        func add(_ topic: ScienceTopic, if condition: Bool) {
            if condition, !found.contains(topic) { found.append(topic) }
        }

        add(.mitochondria, if: lower.contains("mitochond") || lower.contains("atp") || lower.contains("cellular respiration"))
        add(.photosynthesis, if: lower.contains("photosynth") || lower.contains("chloroplast"))
        add(.cellStructure, if: lower.contains("organelle") || lower.contains("nucleus") || lower.contains("ribosome"))
        add(.genetics, if: lower.contains("dna") || lower.contains("gene") || lower.contains("chromosome") || lower.contains("allele"))
        add(.ecology, if: lower.contains("ecosystem") || lower.contains("food web") || lower.contains("population"))
        add(.humanBody, if: lower.contains("heart") || lower.contains("lung") || lower.contains("blood") || lower.contains("digest"))
        add(.atoms, if: lower.contains("proton") || lower.contains("neutron") || lower.contains("electron") || lower.contains("isotope"))
        add(.periodicTable, if: lower.contains("periodic") || lower.contains("element"))
        add(.bonding, if: lower.contains("bond") || lower.contains("ionic") || lower.contains("covalent"))
        add(.reactions, if: lower.contains("reaction") || lower.contains("balance") || lower.contains("equation"))
        add(.acidsBases, if: lower.contains("acid") || lower.contains("base") || lower.contains("ph"))
        add(.forces, if: lower.contains("force") || lower.contains("newton") || lower.contains("friction"))
        add(.energy, if: lower.contains("energy") || lower.contains("joule") || lower.contains("kinetic") || lower.contains("potential"))
        add(.waves, if: lower.contains("wave") || lower.contains("frequency") || lower.contains("wavelength"))
        add(.electricity, if: lower.contains("circuit") || lower.contains("current") || lower.contains("voltage") || lower.contains("ohm"))
        add(.motion, if: lower.contains("velocity") || lower.contains("acceleration") || lower.contains("speed"))
        add(.geology, if: lower.contains("plate") || lower.contains("earthquake") || lower.contains("volcano") || lower.contains("rock"))
        add(.astronomy, if: lower.contains("planet") || lower.contains("moon") || lower.contains("solar") || lower.contains("orbit"))
        add(.weather, if: lower.contains("weather") || lower.contains("hurricane") || lower.contains("front") || lower.contains("cloud"))
        add(.waterCycle, if: lower.contains("evapor") || lower.contains("condens") || lower.contains("precipitation"))
        add(.arithmetic, if: lower.contains("times") || lower.contains("multiply") || lower.contains("divide") || lower.contains("sum"))
        add(.algebra, if: lower.contains("solve for") || lower.contains("variable"))
        add(.geometry, if: lower.contains("area") || lower.contains("volume") || lower.contains("triangle") || lower.contains("circle"))

        if found.isEmpty {
            switch subject {
            case .biology: found.append(.cellStructure)
            case .chemistry: found.append(.atoms)
            case .physics: found.append(.forces)
            case .earthSpace: found.append(.astronomy)
            case .math: found.append(.arithmetic)
            }
        }

        return found
    }

    // MARK: - Expansion helpers

    private static func expandCorrectChoice(_ text: String, question: NSBQuestion) -> String {
        let lower = text.lowercased()
        if lower.contains("law") && question.questionText.lowercased().contains("scientific law") {
            return "A scientific law describes *how* nature behaves under specific conditions — a consistent pattern supported by repeated observation. It is different from a hypothesis (a testable proposal) or a theory (a broad, well-supported explanation)."
        }
        if lower.contains("theory") {
            return "In science, a 'theory' is not a guess — it is a comprehensive explanation supported by extensive evidence from many experiments."
        }
        if lower.contains("mitochond") {
            return "Mitochondria have a double membrane and their own ribosomes. The inner membrane's cristae provide surface area for ATP synthase during oxidative phosphorylation."
        }
        return "This option states the fact or definition the question is targeting. Compare it word-by-word against the stem — the best NSB answer usually mirrors the question's language."
    }

    private static func expandShortAnswer(_ answer: String, question: NSBQuestion) -> String {
        let text = question.questionText.lowercased()
        let ans = answer.lowercased()

        if ans.contains("mitochond") {
            return "Mitochondria are found in nearly all eukaryotic cells and are especially abundant in muscle tissue where energy demand is high."
        }
        if text.contains("organelle") && ans.contains("mitochond") {
            return "While the nucleus stores DNA and ribosomes make protein, mitochondria specialize in ATP production through aerobic respiration."
        }
        if text.contains("photosynth") || ans.contains("chloroplast") {
            return "Chloroplasts contain chlorophyll and carry out the light-dependent and Calvin cycle reactions of photosynthesis."
        }
        return topicExpansion(for: question, answer: answer)
    }

    private static func topicExpansion(for question: NSBQuestion, answer: String) -> String {
        let topics = detectTopics(in: question.questionText, subject: question.subject)
        if let topic = topics.first {
            return "Understanding \(topic.label) helps you connect this answer to related bonus questions in the same round."
        }
        return "Memorize this fact together with one related detail — NSB often follows a toss-up with a bonus on the same topic."
    }

    private static func reviewAllChoices(question: NSBQuestion, correctLetter: String) -> String {
        guard let choices = question.choices else { return "" }
        return ["W", "X", "Y", "Z"].compactMap { letter -> String? in
            let body = choiceBody(for: letter, in: choices)
            guard !body.isEmpty else { return nil }
            if letter == correctLetter.uppercased() {
                return "\(letter)) ✓ \(body)"
            }
            let why = whyNotChoice(body: body, letter: letter, question: question, correctLetter: correctLetter)
            return "\(letter)) ✗ \(why)"
        }.joined(separator: " ")
    }

    private static func whyNotChoice(body: String, letter: String, question: NSBQuestion, correctLetter: String) -> String {
        let lower = body.lowercased()
        let qLower = question.questionText.lowercased()

        if lower.contains("hypothesis") || lower.contains("proposed explanation") {
            return "a hypothesis is a proposed explanation, not a verified descriptive law"
        }
        if lower.contains("theory") && qLower.contains("law") {
            return "theories explain *why* phenomena occur; laws describe consistent relationships"
        }
        if lower.contains("opinion") {
            return "science relies on evidence, not opinion"
        }
        if lower.contains("nucleus") && (qLower.contains("atp") || qLower.contains("energy")) {
            return "the nucleus stores genetic material but does not produce most ATP"
        }
        if lower.contains("ribosome") && qLower.contains("atp") {
            return "ribosomes synthesize proteins; they are not the main site of ATP production"
        }
        return "related but less precise than \(correctLetter))"
    }

    private static func contrastShortAnswers(user: String, correct: String) -> String {
        if AnswerNormalizer.matches(user: user, correct: correct) {
            return "Your wording would likely be accepted."
        }
        return "The key term moderators want is **\(correct)**. Review the related concept so you can buzz faster next time."
    }

    private static func detailedMathWalkthrough(for question: NSBQuestion) -> String? {
        let text = question.questionText.lowercased()
        let answer = question.correctAnswer.replacingOccurrences(of: " ", with: "")

        guard let numbers = extractNumbers(from: question.questionText), numbers.count >= 2,
              let result = Double(answer) else { return nil }

        if text.contains("times") || text.contains("multiply") || text.contains("product") {
            return """
            **Step-by-step:** \(formatNumber(numbers[0])) × \(formatNumber(numbers[1])) = \(formatNumber(result)). \
            Under NSB timing, practice mental math for single-digit multiplication and common two-digit products.
            """
        }
        if text.contains("plus") || text.contains("sum") || text.contains("add") {
            return "**Step-by-step:** \(formatNumber(numbers[0])) + \(formatNumber(numbers[1])) = \(formatNumber(result))."
        }
        if text.contains("minus") || text.contains("subtract") || text.contains("difference") {
            return "**Step-by-step:** \(formatNumber(numbers[0])) − \(formatNumber(numbers[1])) = \(formatNumber(result))."
        }
        if text.contains("divide") || text.contains("quotient") {
            return "**Step-by-step:** \(formatNumber(numbers[0])) ÷ \(formatNumber(numbers[1])) = \(formatNumber(result))."
        }
        return nil
    }

    private static func memoryHook(for question: NSBQuestion) -> String {
        let text = question.questionText.lowercased()
        if text.contains("mitochond") || text.contains("atp") {
            return "Remember: 'Mighty mitochondria make ATP' — power the cell."
        }
        if text.contains("photosynth") {
            return "Photosynthesis: light → chemical energy (glucose); happens in chloroplasts."
        }
        if text.contains("periodic") {
            return "Period = rows (energy levels); Group = columns (valence electrons)."
        }
        if text.contains("planet") {
            return "My Very Educated Mother Just Served Us Nachos — Mercury through Neptune."
        }
        if text.contains("force") || text.contains("newton") {
            return "F = ma. Write units on every physics calculation."
        }
        return "Build a flash card for this question and review it 24 hours later for long-term retention."
    }

    private static func subjectDeepTip(for subject: Subject) -> String {
        switch subject {
        case .biology:
            return "Draw a quick cell diagram when organelle questions appear."
        case .chemistry:
            return "Keep a mental list of common polyatomic ions (CO₃²⁻, SO₄²⁻, NO₃⁻, OH⁻)."
        case .earthSpace:
            return "Link processes to their causes (e.g., subduction → volcanoes)."
        case .math:
            return "Estimate before calculating — catch order-of-magnitude errors early."
        case .physics:
            return "List givens, unknown, and formula before doing arithmetic."
        }
    }

    // MARK: - Shared utilities

    private static func choiceBody(for letter: String, in choices: [String]) -> String {
        guard let match = choices.first(where: { $0.uppercased().hasPrefix("\(letter))") }) else { return "" }
        if let idx = match.firstIndex(of: ")") {
            return String(match[match.index(after: idx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return match
    }

    private static func extractNumbers(from text: String) -> [Double]? {
        let pattern = #"-?\d+(?:\.\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        let values = matches.compactMap { Double(ns.substring(with: $0.range)) }
        return values.isEmpty ? nil : values
    }

    private static func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}

/// Optional bundled long explanations (from generate_explanations.py).
final class ExplanationLibrary {
    static let shared = ExplanationLibrary()

    private var byKey: [String: String] = [:]

    private init() {
        loadBundled()
    }

    func lookup(for question: NSBQuestion) -> String? {
        byKey[cacheKey(for: question)]
    }

    private func cacheKey(for question: NSBQuestion) -> String {
        "\(question.sourcePDF)|\(question.questionText)"
    }

    private func loadBundled() {
        guard let url = Bundle.main.url(forResource: "explanations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(BundledExplanations.self, from: data) else {
            return
        }
        for entry in manifest.explanations {
            byKey[entry.key] = entry.text
        }
    }
}

private struct BundledExplanations: Codable {
    let explanations: [BundledExplanation]
}

private struct BundledExplanation: Codable {
    let key: String
    let text: String
}
