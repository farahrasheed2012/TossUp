import Foundation

enum Subject: String, Codable, CaseIterable, Identifiable {
    case biology
    case chemistry
    case earthSpace
    case math
    case physics

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .biology: return "Biology"
        case .chemistry: return "Chemistry"
        case .earthSpace: return "Earth & Space"
        case .math: return "Math"
        case .physics: return "Physics"
        }
    }

    var emoji: String {
        switch self {
        case .biology: return "🧬"
        case .chemistry: return "⚗️"
        case .earthSpace: return "🌍"
        case .math: return "📐"
        case .physics: return "⚡"
        }
    }
}

enum QuestionType: String, Codable {
    case multipleChoice
    case shortAnswer

    var displayName: String {
        switch self {
        case .multipleChoice: return "Multiple Choice"
        case .shortAnswer: return "Short Answer"
        }
    }
}

struct NSBQuestion: Identifiable, Codable, Hashable {
    let id: UUID
    let subject: Subject
    let round: String
    let type: QuestionType
    let questionText: String
    let choices: [String]?
    let correctAnswer: String
    let sourcePDF: String
    /// Bundled JSON topic id — matches `QuizTopic.id` in TopicCatalog.
    let topicId: String?

    init(
        id: UUID = UUID(),
        subject: Subject,
        round: String,
        type: QuestionType,
        questionText: String,
        choices: [String]?,
        correctAnswer: String,
        sourcePDF: String,
        topicId: String? = nil
    ) {
        self.id = id
        self.subject = subject
        self.round = round
        self.type = type
        self.questionText = questionText
        self.choices = choices
        self.correctAnswer = correctAnswer
        self.sourcePDF = sourcePDF
        self.topicId = topicId
    }
}

struct QuestionBankManifest: Codable {
    let parsedAt: Date
    let sourcePDFCount: Int
    let questionCount: Int
    let pdfFingerprints: [String: String]
    let questions: [NSBQuestion]
}

enum TimerPreset: Int, CaseIterable, Identifiable {
    case officialMC = 5
    case officialSA = 20
    case eight = 8
    case fifteen = 15
    case thirty = 30
    case unlimited = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .officialMC: return "5s (NSB MC)"
        case .officialSA: return "20s (NSB SA)"
        case .eight: return "8 seconds"
        case .fifteen: return "15 seconds"
        case .thirty: return "30 seconds"
        case .unlimited: return "Unlimited"
        }
    }

    func seconds(for type: QuestionType) -> Int? {
        switch self {
        case .officialMC:
            return type == .multipleChoice ? 5 : 20
        case .officialSA:
            return type == .shortAnswer ? 20 : 5
        case .unlimited:
            return nil
        default:
            return rawValue
        }
    }
}

enum QuizLength: Int, CaseIterable, Identifiable {
    case ten = 10
    case twentyFive = 25
    case fifty = 50
    case all = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .ten: return "10 questions"
        case .twentyFive: return "25 questions"
        case .fifty: return "50 questions"
        case .all: return "All available"
        }
    }
}
