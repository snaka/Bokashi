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
/// Every candidate is masked regardless of confidence: model-only names are
/// `.low`, and they are the reason the model runs at all. The user deletes
/// extras in the editor.
@MainActor
struct TextSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "text"

    let observations: [OCRRunner.TextObservation]
    let customTerms: [String]
    let usesLanguageModel: Bool

    /// Pages the on-device model in ahead of the first Detect click.
    static func prewarmIfNeeded() {
        guard DetectionSettings.shared.aiDetectionEnabled, FoundationModelDetector.isAvailable else { return }
        LanguageModelSession().prewarm()
    }

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        guard !observations.isEmpty else { return [] }
        let joined = JoinedLines(observations.map(\.text))

        var modelMatches: [DetectedMatch] = []
        if usesLanguageModel, FoundationModelDetector.isAvailable {
            modelMatches = (try? await FoundationModelDetector().detect(in: joined.text).matches) ?? []
        }

        let candidates = DetectionPipeline(dictionaryTerms: customTerms)
            .detect(in: joined.text, additional: modelMatches)

        return candidates.compactMap { candidate in
            guard
                let located = joined.locate(candidate.range),
                let rect = observations[located.lineIndex].imageRect(forSubrange: located.range)
            else { return nil }
            // AutoMasker reads the label as the debug-overlay source.
            let source = candidate.sources == [.languageModel] ? "appleIntelligence" : "ocr"
            return DetectedRegion(rect: rect.insetBy(dx: -2, dy: -2), label: source)
        }
    }
}
