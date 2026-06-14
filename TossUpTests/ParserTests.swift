import XCTest
@testable import TossUp

final class ParserTests: XCTestCase {
    private let parser = PDFParser()

    func testMultipleChoiceExtraction() throws {
        let sample = """
        TOSS-UP
        1) General Science - Multiple Choice Which of the following best describes a scientific law?
        W) A proposed explanation for a narrow set of phenomena
        X) Broad explanations for a wide range of phenomena
        Y) A statement that is verified by observation and describes how phenomena are related
        Z) An opinion based on observations of phenomena
        ANSWER: Y
        """

        let questions = parser.parseQuestions(from: sample, sourcePDF: "test.pdf", round: "Round 1")
        XCTAssertEqual(questions.count, 1)
        let q = try XCTUnwrap(questions.first)
        XCTAssertEqual(q.type, .multipleChoice)
        XCTAssertEqual(q.correctAnswer, "Y")
        XCTAssertEqual(q.choices?.count, 4)
        XCTAssertTrue(q.questionText.contains("scientific law"))
    }

    func testShortAnswerExtraction() throws {
        let sample = """
        BONUS
        2) Life Science - Short Answer What organelle produces most of the ATP in eukaryotic cells?
        ANSWER: MITOCHONDRIA
        """

        let questions = parser.parseQuestions(from: sample, sourcePDF: "test.pdf", round: "Round 2")
        XCTAssertEqual(questions.count, 1)
        let q = try XCTUnwrap(questions.first)
        XCTAssertEqual(q.type, .shortAnswer)
        XCTAssertEqual(q.subject, .biology)
        XCTAssertEqual(q.correctAnswer, "MITOCHONDRIA")
        XCTAssertNil(q.choices)
    }

    func testInlineTossUpHeader() {
        let sample = """
        TOSS-UP 3) Math - Short Answer What is 12 times 8?
        ANSWER: 96
        """

        let questions = parser.parseQuestions(from: sample, sourcePDF: "inline.pdf", round: "Round 3")
        XCTAssertEqual(questions.count, 1)
        XCTAssertEqual(questions.first?.subject, .math)
    }

    func testAnswerNormalization() {
        XCTAssertTrue(AnswerNormalizer.matches(user: "the mitochondria", correct: "MITOCHONDRIA"))
        XCTAssertTrue(AnswerNormalizer.matches(user: "x", correct: "X"))
        XCTAssertFalse(AnswerNormalizer.matches(user: "nucleus", correct: "MITOCHONDRIA"))
        XCTAssertEqual(AnswerNormalizer.debugNormalize("  The  Gas  "), "GAS")
    }

    func testPhysicalScienceChemistryKeyword() {
        let subject = parser.mapSubject("Physical Science", questionText: "What is the molar mass of water?")
        XCTAssertEqual(subject, .chemistry)
    }

    func testBundledSamplePDFIfPresent() async throws {
        let urls = await MainActor.run { QuestionBank.shared.discoverBundledPDFs() }
        guard let first = urls.first else {
            throw XCTSkip("No bundled PDFs — run download_nsb_pdfs.py first")
        }
        let questions = try parser.parsePDF(at: first)
        XCTAssertFalse(questions.isEmpty, "Expected questions in \(first.lastPathComponent)")
    }
}
