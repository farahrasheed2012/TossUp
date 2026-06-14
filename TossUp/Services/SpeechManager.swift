import AVFoundation

@MainActor
final class SpeechManager: NSObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speak(_ text: String, rate: Float = 0.38) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        stop()
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func speakQuestion(_ text: String) {
        speak(SpeechTextSanitizer.speakable(text))
    }

    func speakQuestionWithChoices(question: String, choices: [String]) {
        var parts = [SpeechTextSanitizer.speakable(question)]
        for choice in choices {
            let cleaned = choice.replacingOccurrences(of: #"\)\s*"#, with: ") ", options: .regularExpression)
            parts.append(SpeechTextSanitizer.speakable(cleaned))
        }
        speak(parts.joined(separator: ". "))
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {}
