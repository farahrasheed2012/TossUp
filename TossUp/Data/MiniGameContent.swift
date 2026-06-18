import Foundation

// MARK: - Science Wordle

enum ScienceWordleContent {
  static let wordLength = 5
  static let maxGuesses = 6

  /// Curated 5-letter NSB vocabulary (uppercase, letters only).
  static let wordBank: [String] = [
    "ATOMS", "ACIDS", "CELLS", "GENES", "LIGHT", "FORCE", "WAVES", "SOLAR",
    "LUNAR", "PLANT", "ROOTS", "SEEDS", "BONES", "BRAIN", "HEART", "BLOOD",
    "VIRUS", "FUNGI", "ALGAE", "ROCKS", "METAL", "GLASS", "WATER", "STEAM",
    "SALTS", "OXIDE", "RADII", "SPEED", "POWER", "VOLTS", "LASER", "PRISM",
    "FOCUS", "SOUND", "PITCH", "TEMPO", "EARTH", "MOONS", "COMET", "ORBIT",
    "SPACE", "STARS", "QUARK", "NEUTR", "IONIC", "COVAL", "BONDS", "MOLES",
    "GRAMS", "LITRE", "DENSE", "PHASE", "SOLID", "GASES", "DELTA", "SIGMA",
    "THETA", "ALPHA", "GAMMA", "PHAGE", "ENZYM", "AMINO", "LIPID", "SUGAR",
    "FIBER", "NERVE", "ORGAN", "MITOS", "MEIOS", "CHROM", "HELIX", "CODON",
    "YEAST", "SPORE", "PETRI", "SLIDE", "MICRO", "MACRO", "UNITS", "METRE",
    "JOULE", "WATTS", "AMPER", "OHMIC", "TORQU", "INERT", "MOMEN", "TORSO",
    "FLUID", "FRICT", "GRAVY", "PHOTO", "ELECT", "PROTE", "BEAMS", "CILIA",
  ].filter { $0.count == wordLength && $0.allSatisfy(\.isLetter) }

  static func dailyWord(on date: Date = Date()) -> String {
    let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
    let bank = wordBank.isEmpty ? ["ATOMS"] : wordBank
    return bank[day % bank.count]
  }

  static func isValidGuess(_ word: String) -> Bool {
    let upper = word.uppercased()
    guard upper.count == wordLength, upper.allSatisfy(\.isLetter) else { return false }
    return wordBank.contains(upper)
  }
}

enum WordleLetterState: Equatable {
  case unused, absent, wrongSpot, correctSpot

  var colorName: String {
    switch self {
    case .unused: return "unused"
    case .absent: return "absent"
    case .wrongSpot: return "wrongSpot"
    case .correctSpot: return "correctSpot"
    }
  }
}

struct WordleEvaluator {
  static func feedback(guess: String, answer: String) -> [WordleLetterState] {
    let g = Array(guess.uppercased())
    let a = Array(answer.uppercased())
    var result = Array(repeating: WordleLetterState.absent, count: wordLength)
    var remaining = [Character: Int]()

    for ch in a {
      remaining[ch, default: 0] += 1
    }

    for i in 0..<wordLength where g[i] == a[i] {
      result[i] = .correctSpot
      remaining[g[i], default: 0] -= 1
    }

    for i in 0..<wordLength where result[i] != .correctSpot {
      if remaining[g[i], default: 0] > 0 {
        result[i] = .wrongSpot
        remaining[g[i], default: 0] -= 1
      }
    }

    return result
  }

  private static var wordLength: Int { ScienceWordleContent.wordLength }
}

// MARK: - True or False Blitz

struct TrueFalseStatement: Identifiable, Hashable {
  let id = UUID()
  let text: String
  let isTrue: Bool
  let subject: Subject
}

enum TrueFalseBlitzContent {
  static let sessionLength = 15

  static let curated: [TrueFalseStatement] = [
    TrueFalseStatement(text: "Photosynthesis occurs in the chloroplasts of plant cells.", isTrue: true, subject: .biology),
    TrueFalseStatement(text: "Mitochondria are the site of cellular respiration.", isTrue: true, subject: .biology),
    TrueFalseStatement(text: "Animal cells have a rigid cell wall made of cellulose.", isTrue: false, subject: .biology),
    TrueFalseStatement(text: "DNA carries genetic information in living organisms.", isTrue: true, subject: .biology),
    TrueFalseStatement(text: "Viruses are considered living cells.", isTrue: false, subject: .biology),
    TrueFalseStatement(text: "Water is composed of hydrogen and oxygen atoms.", isTrue: true, subject: .chemistry),
    TrueFalseStatement(text: "A pH of 7 indicates a neutral solution.", isTrue: true, subject: .chemistry),
    TrueFalseStatement(text: "Acids have a pH greater than 7.", isTrue: false, subject: .chemistry),
    TrueFalseStatement(text: "The chemical symbol for gold is Au.", isTrue: true, subject: .chemistry),
    TrueFalseStatement(text: "Noble gases readily form ionic bonds.", isTrue: false, subject: .chemistry),
    TrueFalseStatement(text: "Force equals mass times acceleration (F = ma).", isTrue: true, subject: .physics),
    TrueFalseStatement(text: "Sound travels faster in air than in steel.", isTrue: false, subject: .physics),
    TrueFalseStatement(text: "Light travels faster than sound.", isTrue: true, subject: .physics),
    TrueFalseStatement(text: "Gravity pulls objects toward the center of Earth.", isTrue: true, subject: .physics),
    TrueFalseStatement(text: "Electrons have a positive charge.", isTrue: false, subject: .physics),
    TrueFalseStatement(text: "Earth is the largest planet in our solar system.", isTrue: false, subject: .earthSpace),
    TrueFalseStatement(text: "The Moon orbits Earth.", isTrue: true, subject: .earthSpace),
    TrueFalseStatement(text: "Mars is known as the Red Planet.", isTrue: true, subject: .earthSpace),
    TrueFalseStatement(text: "The Sun is a star.", isTrue: true, subject: .earthSpace),
    TrueFalseStatement(text: "A triangle's angles always sum to 180 degrees.", isTrue: true, subject: .math),
    TrueFalseStatement(text: "π (pi) is exactly equal to 3.", isTrue: false, subject: .math),
    TrueFalseStatement(text: "The square root of 64 is 8.", isTrue: true, subject: .math),
  ]

  static func shuffledSession() -> [TrueFalseStatement] {
    Array(curated.shuffled().prefix(sessionLength))
  }

  /// Build extra statements from MC questions when the bank is loaded.
  static func statements(from questions: [NSBQuestion]) -> [TrueFalseStatement] {
    questions.compactMap { q in
      guard q.type == .multipleChoice, let choices = q.choices, choices.count >= 2 else { return nil }
      let correct = q.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !correct.isEmpty else { return nil }
      let statement = q.questionText.hasSuffix("?")
        ? String(q.questionText.dropLast()) + " is \(correct)."
        : "\(q.questionText) The answer is \(correct)."
      return TrueFalseStatement(text: statement, isTrue: true, subject: q.subject)
    }
  }
}

// MARK: - Molecule Match

struct MoleculePair: Identifiable, Hashable {
  let id = UUID()
  let formula: String
  let name: String
}

enum MoleculeMatchContent {
  static let pairs: [MoleculePair] = [
    MoleculePair(formula: "H₂O", name: "Water"),
    MoleculePair(formula: "CO₂", name: "Carbon dioxide"),
    MoleculePair(formula: "NaCl", name: "Sodium chloride"),
    MoleculePair(formula: "O₂", name: "Oxygen"),
    MoleculePair(formula: "CH₄", name: "Methane"),
    MoleculePair(formula: "NH₃", name: "Ammonia"),
    MoleculePair(formula: "HCl", name: "Hydrochloric acid"),
    MoleculePair(formula: "CaCO₃", name: "Calcium carbonate"),
  ]

  static func randomDeck(pairCount: Int = 6) -> [MemoryCard] {
    let selected = pairs.shuffled().prefix(pairCount)
    var cards: [MemoryCard] = []
    for pair in selected {
      cards.append(MemoryCard(pairID: pair.id, face: pair.formula, kind: .formula))
      cards.append(MemoryCard(pairID: pair.id, face: pair.name, kind: .name))
    }
    return cards.shuffled()
  }
}

struct MemoryCard: Identifiable, Hashable {
  enum Kind: Hashable { case formula, name }

  let id = UUID()
  let pairID: UUID
  let face: String
  let kind: Kind
}

// MARK: - Cell Builder

enum CellType: String, CaseIterable, Identifiable {
  case animal
  case plant

  var id: String { rawValue }

  var title: String {
    switch self {
    case .animal: return "Animal Cell"
    case .plant: return "Plant Cell"
    }
  }
}

struct OrganellePiece: Identifiable, Hashable {
  let id: String
  let label: String
  let icon: String
  let correctZone: String
  let cellTypes: Set<CellType>
}

struct CellDropZone: Identifiable, Hashable {
  let id: String
  let label: String
  /// Normalized center (0…1) within the cell diagram.
  let center: CGPoint
  let radius: CGFloat
  let cellTypes: Set<CellType>
}

enum CellBuilderContent {
  static let organelles: [OrganellePiece] = [
    OrganellePiece(id: "nucleus", label: "Nucleus", icon: "circle.fill", correctZone: "nucleus", cellTypes: [.animal, .plant]),
    OrganellePiece(id: "mitochondria", label: "Mitochondria", icon: "capsule.fill", correctZone: "mitochondria", cellTypes: [.animal, .plant]),
    OrganellePiece(id: "ribosome", label: "Ribosome", icon: "circle.grid.2x2.fill", correctZone: "ribosome", cellTypes: [.animal, .plant]),
    OrganellePiece(id: "er", label: "Endoplasmic Reticulum", icon: "waveform.path", correctZone: "er", cellTypes: [.animal, .plant]),
    OrganellePiece(id: "golgi", label: "Golgi Apparatus", icon: "square.stack.3d.up.fill", correctZone: "golgi", cellTypes: [.animal, .plant]),
    OrganellePiece(id: "chloroplast", label: "Chloroplast", icon: "leaf.fill", correctZone: "chloroplast", cellTypes: [.plant]),
    OrganellePiece(id: "vacuole", label: "Central Vacuole", icon: "drop.fill", correctZone: "vacuole", cellTypes: [.plant]),
    OrganellePiece(id: "cell_wall", label: "Cell Wall", icon: "square.dashed", correctZone: "cell_wall", cellTypes: [.plant]),
    OrganellePiece(id: "lysosome", label: "Lysosome", icon: "circle.hexagongrid.fill", correctZone: "lysosome", cellTypes: [.animal]),
  ]

  static let dropZones: [CellDropZone] = [
    CellDropZone(id: "nucleus", label: "Nucleus", center: CGPoint(x: 0.5, y: 0.45), radius: 0.12, cellTypes: [.animal, .plant]),
    CellDropZone(id: "mitochondria", label: "Mitochondria", center: CGPoint(x: 0.32, y: 0.62), radius: 0.09, cellTypes: [.animal, .plant]),
    CellDropZone(id: "ribosome", label: "Ribosome", center: CGPoint(x: 0.68, y: 0.58), radius: 0.08, cellTypes: [.animal, .plant]),
    CellDropZone(id: "er", label: "ER", center: CGPoint(x: 0.38, y: 0.38), radius: 0.1, cellTypes: [.animal, .plant]),
    CellDropZone(id: "golgi", label: "Golgi", center: CGPoint(x: 0.62, y: 0.35), radius: 0.09, cellTypes: [.animal, .plant]),
    CellDropZone(id: "chloroplast", label: "Chloroplast", center: CGPoint(x: 0.25, y: 0.5), radius: 0.09, cellTypes: [.plant]),
    CellDropZone(id: "vacuole", label: "Vacuole", center: CGPoint(x: 0.72, y: 0.48), radius: 0.11, cellTypes: [.plant]),
    CellDropZone(id: "cell_wall", label: "Cell Wall", center: CGPoint(x: 0.5, y: 0.12), radius: 0.1, cellTypes: [.plant]),
    CellDropZone(id: "lysosome", label: "Lysosome", center: CGPoint(x: 0.78, y: 0.68), radius: 0.08, cellTypes: [.animal]),
  ]

  static func pieces(for cellType: CellType) -> [OrganellePiece] {
    organelles.filter { $0.cellTypes.contains(cellType) }
  }

  static func zones(for cellType: CellType) -> [CellDropZone] {
    dropZones.filter { $0.cellTypes.contains(cellType) }
  }
}
