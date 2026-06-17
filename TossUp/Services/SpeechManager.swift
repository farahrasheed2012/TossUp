import AVFoundation

@MainActor
final class SpeechManager: NSObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override private init() {
        super.init()
        synthesizer.delegate = self
    }

    var isSpeaking: Bool { synthesizer.isSpeaking }

    func stop() {
        onFinish = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    func speak(_ text: String, rate: Float = 0.38, onFinish: (() -> Void)? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onFinish?()
            return
        }
        stop()
        self.onFinish = onFinish
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = rate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func speakQuestion(_ text: String, onFinish: (() -> Void)? = nil) {
        speak(SpeechTextSanitizer.speakable(text), onFinish: onFinish)
    }

    func speakQuestionWithChoices(question: String, choices: [String], onFinish: (() -> Void)? = nil) {
        var parts = [SpeechTextSanitizer.speakable(question)]
        for choice in choices {
            let cleaned = choice.replacingOccurrences(of: #"\)\s*"#, with: ") ", options: .regularExpression)
            parts.append(SpeechTextSanitizer.speakable(cleaned))
        }
        speak(parts.joined(separator: ". "), onFinish: onFinish)
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let handler = onFinish
        onFinish = nil
        handler?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish = nil
    }
}
