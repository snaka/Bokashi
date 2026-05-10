import BokashiCore
import CoreGraphics

@MainActor
enum AutoMasker {
    static func detect(
        in image: CGImage,
        observations: [OCRRunner.TextObservation],
        customTerms: [String]
    ) async -> [Annotation] {
        let detectors: [any SensitiveRegionDetector] = [
            OCRSensitiveRegionDetector(observations: observations, customTerms: customTerms)
        ]

        var annotations: [Annotation] = []
        for detector in detectors {
            do {
                let regions = try await detector.detect(in: image)
                for region in regions {
                    annotations.append(
                        Annotation(kind: .mosaic(rect: region.rect), style: .defaultOutline)
                    )
                }
            } catch {
                continue
            }
        }
        return annotations
    }
}
