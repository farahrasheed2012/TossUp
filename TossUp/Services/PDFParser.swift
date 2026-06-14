import Foundation
import PDFKit

final class PDFParser {
    struct ParseError: Error, CustomStringConvertible {
        let message: String
        var description: String { message }
    }

    private let fileManager = FileManager.default

    func parseAllPDFs(in resourceURLs: [URL], logURL: URL?) throws -> [NSBQuestion] {
        var allQuestions: [NSBQuestion] = []
        var logLines: [String] = []

        for url in resourceURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard url.pathExtension.lowercased() == "pdf" else { continue }
            do {
                let parsed = try parsePDF(at: url)
                allQuestions.append(contentsOf: parsed)
            } catch {
                logLines.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if let logURL, !logLines.isEmpty {
            let body = logLines.joined(separator: "\n") + "\n"
            if fileManager.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    handle.seekToEndOfFile()
                    handle.write(body.data(using: .utf8) ?? Data())
                    try? handle.close()
                }
            } else {
                try? body.write(to: logURL, atomically: true, encoding: .utf8)
            }
        }

        return allQuestions
    }

    func parsePDF(at url: URL) throws -> [NSBQuestion] {
        guard let document = PDFDocument(url: url) else {
            throw ParseError(message: "Could not open PDF")
        }

        let fullText = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")

        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ParseError(message: "Empty PDF text")
        }

        let roundName = inferRoundName(from: fullText, filename: url.lastPathComponent)
        return parseQuestions(from: fullText, sourcePDF: url.lastPathComponent, round: roundName)
    }

    // MARK: - Public helpers for tests

    func parseQuestions(from text: String, sourcePDF: String, round: String) -> [NSBQuestion] {
        let normalized = normalizeText(text)
        let segments = splitIntoQuestionSegments(normalized)
        var questions: [NSBQuestion] = []

        for segment in segments {
            if let question = parseSegment(segment, sourcePDF: sourcePDF, round: round) {
                questions.append(question)
            }
        }
        return questions
    }

    // MARK: - Parsing internals

    private func normalizeText(_ text: String) -> String {
        var value = text.replacingOccurrences(of: "\u{00A0}", with: " ")
        value = value.replacingOccurrences(of: "\r", with: "\n")
        value = value.replacingOccurrences(of: #"[–—−]"#, with: "-", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\n{2,}"#, with: "\n", options: .regularExpression)
        return value
    }

    private func splitIntoQuestionSegments(_ text: String) -> [String] {
        let pattern = #"(?i)(TOSS-UP|BONUS)\s*(\d+)?\)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return [] }

        var segments: [String] = []
        for (index, match) in matches.enumerated() {
            let start = match.range.location
            let end = index + 1 < matches.count ? matches[index + 1].range.location : nsText.length
            let chunk = nsText.substring(with: NSRange(location: start, length: end - start))
            segments.append(chunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return segments
    }

    private func parseSegment(_ segment: String, sourcePDF: String, round: String) -> NSBQuestion? {
        var text = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let kindRegex = try? NSRegularExpression(pattern: #"(?i)^(TOSS-UP|BONUS)"#),
              let kindMatch = kindRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let kindRange = Range(kindMatch.range(at: 1), in: text) else {
            return nil
        }

        let kind = String(text[kindRange]).uppercased()
        text = String(text[kindRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)

        let metaPattern = #"(?is)^(\d+)\)\s*([^-\n]+?)\s*-\s*(Multiple Choice|Short Answer)\s*(.*)$"#
        guard let metaRegex = try? NSRegularExpression(pattern: metaPattern),
              let metaMatch = metaRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let subjectRange = Range(metaMatch.range(at: 2), in: text),
              let typeRange = Range(metaMatch.range(at: 3), in: text),
              let textRange = Range(metaMatch.range(at: 4), in: text) else {
            return nil
        }

        let subjectLabel = String(text[subjectRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let typeLabel = String(text[typeRange])
        let remainder = String(text[textRange])

        let answerPattern = #"(?is)ANSWER\s*:\s*(.+)$"#
        guard let answerRegex = try? NSRegularExpression(pattern: answerPattern),
              let answerMatch = answerRegex.firstMatch(in: remainder, range: NSRange(remainder.startIndex..., in: remainder)),
              let answerRange = Range(answerMatch.range(at: 1), in: remainder) else {
            return nil
        }

        let answer = String(remainder[answerRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let answerStart = Range(answerMatch.range(at: 0), in: remainder)?.lowerBound ?? remainder.startIndex
        let beforeAnswer = String(remainder[..<answerStart]).trimmingCharacters(in: .whitespacesAndNewlines)

        let type: QuestionType = typeLabel.lowercased().contains("multiple") ? .multipleChoice : .shortAnswer
        let (questionText, choices) = extractQuestionAndChoices(from: beforeAnswer, type: type)
        guard !questionText.isEmpty else { return nil }

        let subject = mapSubject(subjectLabel, questionText: questionText)
        let roundLabel = kind == "BONUS" ? "Bonus \(round)" : "Toss-Up \(round)"

        return NSBQuestion(
            subject: subject,
            round: roundLabel,
            type: type,
            questionText: questionText,
            choices: choices,
            correctAnswer: cleanAnswer(answer, type: type),
            sourcePDF: sourcePDF
        )
    }

    private func extractQuestionAndChoices(from text: String, type: QuestionType) -> (String, [String]?) {
        guard type == .multipleChoice else {
            return (collapseWhitespace(text), nil)
        }

        let choicePattern = #"(?m)^\s*([WXYZ])\)\s*(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: choicePattern) else {
            return (collapseWhitespace(text), nil)
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else {
            return (collapseWhitespace(text), nil)
        }

        let firstChoiceLocation = matches[0].range.location
        let questionPart = nsText.substring(to: firstChoiceLocation)
        let choices = matches.compactMap { match -> String? in
            guard let letterRange = Range(match.range(at: 1), in: text),
                  let bodyRange = Range(match.range(at: 2), in: text) else { return nil }
            return "\(text[letterRange])) \(text[bodyRange].trimmingCharacters(in: .whitespacesAndNewlines))"
        }

        return (collapseWhitespace(questionPart), choices)
    }

    private func cleanAnswer(_ answer: String, type: QuestionType) -> String {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        if type == .multipleChoice {
            if let letter = trimmed.first, "WXYZ".contains(letter), trimmed.count <= 3 {
                return String(letter)
            }
        }
        return trimmed
    }

    private func collapseWhitespace(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func inferRoundName(from text: String, filename: String) -> String {
        if let match = text.range(of: #"(?i)ROUND\s+[\w\-]+"#, options: .regularExpression) {
            return String(text[match]).replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        }
        let base = (filename as NSString).deletingPathExtension
        return base.replacingOccurrences(of: "_", with: " ")
    }

    func mapSubject(_ label: String, questionText: String) -> Subject {
        let lower = label.lowercased()
        if lower.contains("life") { return .biology }
        if lower.contains("earth") || lower.contains("space") { return .earthSpace }
        if lower.contains("math") { return .math }
        if lower.contains("energy") { return .physics }

        if lower.contains("physical") || lower.contains("general") {
            return looksLikeChemistry(questionText) ? .chemistry : .physics
        }

        if lower.contains("chem") { return .chemistry }
        if lower.contains("bio") { return .biology }
        if lower.contains("phys") { return .physics }
        return .physics
    }

    private func looksLikeChemistry(_ text: String) -> Bool {
        let lower = text.lowercased()
        let keywords = [
            "mole", "molar", "acid", "base", "ion", "molecule", "periodic", "electron",
            "bond", "oxidation", "ph", "formula", "compound", "catalyst",
            "solvent", "solute", "valence", "isotope", "neutron", "proton",
        ]
        return keywords.contains { lower.contains($0) }
    }
}
