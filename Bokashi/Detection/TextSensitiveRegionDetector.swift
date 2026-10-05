import BokashiCore
import CoreGraphics
import Foundation
import FoundationModels
import PrivMask

/// Runs privmask over the OCR text. The on-device model's findings go
/// through the same `DetectionPipeline` as the deterministic ones so that
/// privmask's precedence rules apply to them — a model "name" that wraps a
/// phone number is dropped there, which a rect-level dedup cannot see.
///
/// The NER model that comes with the privmask CLI finds Japanese names
/// without Apple Intelligence; the language model adds to it when enabled.
///
/// Every candidate is masked regardless of confidence: model-only names are
/// `.low`, and they are the reason the models run at all. The user deletes
/// extras in the editor.
@MainActor
struct TextSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "text"

    let observations: [OCRRunner.TextObservation]
    let customTerms: [String]
    let usesLanguageModel: Bool

    /// The model is tens of megabytes, so it is not bundled: it is the copy
    /// Homebrew installs with the privmask CLI, on Apple silicon or Intel.
    /// Loaded once, off the main actor. nil when the CLI is not installed or
    /// the model fails to load: names are then left to the language model.
    nonisolated private static let ner: NERDetector? = ["/opt/homebrew/bin/privmask", "/usr/local/bin/privmask"]
        .lazy
        .compactMap { NERResources.directory(environment: [:], executable: URL(fileURLWithPath: $0)) }
        .first
        .flatMap { try? NERDetector.load(from: $0) }

    /// Loads the NER model and pages the on-device model in ahead of the first
    /// Detect click.
    static func prewarmIfNeeded() {
        Task.detached(priority: .utility) { _ = ner }
        guard DetectionSettings.shared.aiDetectionEnabled, FoundationModelDetector.isAvailable else { return }
        LanguageModelSession().prewarm()
    }

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        guard !observations.isEmpty else { return [] }
        let joined = JoinedLines(observations.map(\.text))

        // CPU-bound for seconds on a text-heavy screenshot, so off the main actor.
        let text = joined.text
        var modelMatches = await Task.detached(priority: .userInitiated) {
            (try? Self.ner?.detect(in: text)) ?? []
        }.value
        if usesLanguageModel, FoundationModelDetector.isAvailable {
            modelMatches += (try? await FoundationModelDetector().detect(in: joined.text).matches) ?? []
        }

        let candidates = DetectionPipeline(dictionaryTerms: customTerms)
            .detect(in: joined.text, additional: modelMatches)

        return candidates.compactMap { candidate in
            guard
                let located = joined.locate(candidate.range),
                let rect = observations[located.lineIndex].imageRect(forSubrange: located.range)
            else { return nil }
            // AutoMasker reads the label as the debug-overlay source.
            let source: String
            switch Set(candidate.sources) {
            case [.languageModel]: source = "appleIntelligence"
            case [.ner], [.ner, .languageModel]: source = "ner"
            default: source = "ocr"
            }
            return DetectedRegion(rect: rect.insetBy(dx: -2, dy: -2), label: source)
        }
    }
}
