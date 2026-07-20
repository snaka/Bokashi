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
        // Order is dedup priority: deterministic detectors first so their
        // precise rects win over near-duplicate AI findings.
        var detectors: [any SensitiveRegionDetector] = [
            OCRSensitiveRegionDetector(observations: observations, customTerms: customTerms)
        ]
        let settings = DetectionSettings.shared
        if settings.faceMaskingEnabled {
            detectors.append(FaceSensitiveRegionDetector())
        }
        if settings.aiDetectionEnabled, AppleIntelligenceSensitiveRegionDetector.isModelAvailable {
            detectors.append(AppleIntelligenceSensitiveRegionDetector(observations: observations))
        }

        var labeled: [(region: DetectedRegion, detectorIdentifier: String)] = []
        for detector in detectors {
            do {
                let regions = try await detector.detect(in: image)
                labeled.append(contentsOf: regions.map { ($0, detector.identifier) })
            } catch {
                continue
            }
        }

        let kept = RegionDeduplicator.keptIndices(of: labeled.map(\.region))
        return kept.map { index in
            Detection(
                annotation: Annotation(
                    kind: .mosaic(rect: labeled[index].region.rect),
                    style: .defaultOutline
                ),
                detectorIdentifier: labeled[index].detectorIdentifier
            )
        }
    }
}
