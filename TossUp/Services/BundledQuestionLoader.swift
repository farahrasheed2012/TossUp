import Foundation

enum BundledQuestionLoader {
    private struct Record: Codable {
        let id: String?
        let subject: Subject
        let round: String
        let type: QuestionType
        let questionText: String
        let choices: [String]?
        let correctAnswer: String
        let sourcePDF: String
        let topicId: String?
    }

    static func loadAll() -> [NSBQuestion] {
        var merged: [NSBQuestion] = []
        var seen = Set<UUID>()

        for url in discoverBundledJSONURLs() {
            for question in load(url: url) where seen.insert(question.id).inserted {
                merged.append(question)
            }
        }

        if merged.isEmpty {
            let hewitt = load(named: "questions", subdirectory: "HewittCh17")
            for question in hewitt where seen.insert(question.id).inserted {
                merged.append(question)
            }
        }

        return merged
    }

    static func loadHewittChapter17() -> [NSBQuestion] {
        loadAll().filter { $0.sourcePDF == "Hewitt-Ch17" }
    }

    private static func discoverBundledJSONURLs() -> [URL] {
        guard let resourceURL = Bundle.main.resourceURL else { return [] }
        let files = (try? FileManager.default.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil
        )) ?? []
        return files
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasSuffix("_questions.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func load(url: URL) -> [NSBQuestion] {
        guard let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([Record].self, from: data) else {
            return []
        }
        return records.map { record in
            NSBQuestion(
                id: stableUUID(from: record.id ?? record.questionText),
                subject: record.subject,
                round: record.round,
                type: record.type,
                questionText: record.questionText,
                choices: record.choices,
                correctAnswer: record.correctAnswer,
                sourcePDF: record.sourcePDF,
                topicId: record.topicId
            )
        }
    }

    private static func load(named name: String, subdirectory: String? = nil) -> [NSBQuestion] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: subdirectory) else {
            return []
        }
        return load(url: url)
    }

    private static func stableUUID(from seed: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        for (index, byte) in seed.utf8.enumerated() {
            bytes[index % 16] ^= byte
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
