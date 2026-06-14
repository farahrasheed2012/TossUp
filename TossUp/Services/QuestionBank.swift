import Foundation

@MainActor
final class QuestionBank: ObservableObject {
    static let shared = QuestionBank()

    @Published private(set) var questions: [NSBQuestion] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?
    @Published private(set) var lastParsedAt: Date?
    @Published private(set) var sourcePDFCount = 0

    private let parser = PDFParser()
    private let fileManager = FileManager.default

    private var cacheURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("TossUp", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("questions_cache.json")
    }

    private var logURL: URL {
        cacheURL.deletingLastPathComponent().appendingPathComponent("parse_errors.log")
    }

    func loadIfNeeded() async {
        guard questions.isEmpty else { return }
        await reload()
    }

    func reload() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let pdfURLs = discoverBundledPDFs()
        sourcePDFCount = pdfURLs.count
        let fingerprints = fingerprintPDFs(pdfURLs)

        if let cached = loadCache(), cached.pdfFingerprints == fingerprints, !cached.questions.isEmpty {
            questions = cached.questions
            lastParsedAt = cached.parsedAt
            sourcePDFCount = cached.sourcePDFCount
            return
        }

        do {
            let parsed = try parser.parseAllPDFs(in: pdfURLs, logURL: logURL)
            questions = parsed
            lastParsedAt = Date()
            saveCache(
                QuestionBankManifest(
                    parsedAt: lastParsedAt ?? Date(),
                    sourcePDFCount: pdfURLs.count,
                    questionCount: parsed.count,
                    pdfFingerprints: fingerprints,
                    questions: parsed
                )
            )
        } catch {
            loadError = error.localizedDescription
            if let cached = loadCache() {
                questions = cached.questions
                lastParsedAt = cached.parsedAt
            }
        }
    }

    func questions(subjects: Set<Subject>, rounds: Set<String> = []) -> [NSBQuestion] {
        questions.filter { question in
            subjects.contains(question.subject) && (rounds.isEmpty || rounds.contains(question.round))
        }
    }

    func question(withID id: UUID) -> NSBQuestion? {
        questions.first { $0.id == id }
    }

    // MARK: - Bundle discovery

    func discoverBundledPDFs() -> [URL] {
        var urls: [URL] = []
        let subdirs = ["NSB_PDFs/_By_Set", "NSB_PDFs", ""]

        for subdir in subdirs {
            if let base = Bundle.main.resourceURL?.appendingPathComponent(subdir, isDirectory: true),
               fileManager.fileExists(atPath: base.path) {
                if let enumerator = fileManager.enumerator(at: base, includingPropertiesForKeys: nil) {
                    for case let file as URL in enumerator where file.pathExtension.lowercased() == "pdf" {
                        urls.append(file)
                    }
                }
            }
        }

        // Developer fallback when running from Xcode without copied PDFs in bundle.
        if urls.isEmpty {
            let devRoot = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("NSB_PDFs/_By_Set", isDirectory: true)
            if fileManager.fileExists(atPath: devRoot.path),
               let enumerator = fileManager.enumerator(at: devRoot, includingPropertiesForKeys: nil) {
                for case let file as URL in enumerator where file.pathExtension.lowercased() == "pdf" {
                    urls.append(file)
                }
            }
        }

        return Array(Set(urls))
    }

    // MARK: - Cache

    private func fingerprintPDFs(_ urls: [URL]) -> [String: String] {
        var result: [String: String] = [:]
        for url in urls {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let size = values?.fileSize ?? 0
            let modified = values?.contentModificationDate?.timeIntervalSince1970 ?? 0
            result[url.lastPathComponent] = "\(size)-\(modified)"
        }
        return result
    }

    private func loadCache() -> QuestionBankManifest? {
        guard fileManager.fileExists(atPath: cacheURL.path),
              let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode(QuestionBankManifest.self, from: data)
    }

    private func saveCache(_ manifest: QuestionBankManifest) {
        guard let data = try? JSONEncoder().encode(manifest) else { return }
        try? data.write(to: cacheURL, options: .atomic)
    }
}
