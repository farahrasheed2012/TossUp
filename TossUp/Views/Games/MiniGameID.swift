import Foundation

enum MiniGameID: String, CaseIterable, Identifiable, Hashable {
    case scienceWordle
    case trueOrFalseBlitz
    case elementBlitz
    case moleculeMatch
    case cellBuilder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scienceWordle: return "Science Wordle"
        case .trueOrFalseBlitz: return "True or False Blitz"
        case .elementBlitz: return "Element Blitz"
        case .moleculeMatch: return "Molecule Match"
        case .cellBuilder: return "Cell Builder"
        }
    }

    var subtitle: String {
        switch self {
        case .scienceWordle: return "Guess the 5-letter science term"
        case .trueOrFalseBlitz: return "15 rapid fact checks"
        case .elementBlitz: return "90-second element sprint"
        case .moleculeMatch: return "Flip & match formulas"
        case .cellBuilder: return "Drag organelles into place"
        }
    }

    var icon: String {
        switch self {
        case .scienceWordle: return "square.grid.3x3.fill"
        case .trueOrFalseBlitz: return "hand.thumbsup.fill"
        case .elementBlitz: return "flask.fill"
        case .moleculeMatch: return "rectangle.on.rectangle.angled"
        case .cellBuilder: return "circle.hexagongrid.fill"
        }
    }

    var accentColorName: String { rawValue }
}
