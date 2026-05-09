import BokashiCore
import Foundation

@MainActor
@Observable
final class CustomTermsManager {
    static let shared = CustomTermsManager()

    private(set) var terms: [String] = []

    private let store: CustomTermsStore

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        let fileURL = appSupport
            .appendingPathComponent("Bokashi", isDirectory: true)
            .appendingPathComponent("custom-terms.json")
        self.store = CustomTermsStore(fileURL: fileURL)
        self.terms = (try? store.load()) ?? []
    }

    func add(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !terms.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else {
            return
        }
        terms.append(trimmed)
        persist()
    }

    func remove(at offsets: IndexSet) {
        terms.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        try? store.save(terms)
    }
}
