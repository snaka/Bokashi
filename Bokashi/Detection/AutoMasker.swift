import BokashiCore
import CoreGraphics

@MainActor
enum AutoMasker {
    struct Detection {
        let annotation: Annotation
        let detectorIdentifier: String
    }

    static func detect(
        in image: CGImage,
        observations: [OCRRunner.TextObservation],
        customTerms: [String]
    ) async -> [Detection] {
        // Order is dedup priority: text findings first so their precise
        // glyph rects win over overlapping face rects.
        let settings = DetectionSettings.shared
        var detectors: [any SensitiveRegionDetector] = [
            TextSensitiveRegionDetector(
                observations: observations,
                customTerms: customTerms,
                usesLanguageModel: settings.aiDetectionEnabled
            )
        ]
        if settings.faceMaskingEnabled {
            detectors.append(FaceSensitiveRegionDetector())
        }

        var regions: [DetectedRegion] = []
        for detector in detectors {
            do {
                regions += try await detector.detect(in: image)
            } catch {
                continue
            }
        }

        let kept = RegionDeduplicator.keptIndices(of: regions)
        return kept.map { index in
            Detection(
                annotation: Annotation(
                    kind: .mosaic(rect: regions[index].rect),
                    style: .defaultOutline
                ),
                detectorIdentifier: regions[index].label
            )
        }
    }
}
