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
        var detectors: [any SensitiveRegionDetector] = [
            OCRSensitiveRegionDetector(observations: observations, customTerms: customTerms)
        ]

        let ollama = OllamaDetectorSettings.shared
        if ollama.isEnabled, !ollama.trimmedModel.isEmpty {
            detectors.append(
                OllamaSensitiveRegionDetector(
                    endpoint: ollama.trimmedEndpoint,
                    model: ollama.trimmedModel
                )
            )
        }

        var detections: [Detection] = []
        for detector in detectors {
            do {
                let regions = try await detector.detect(in: image)
                for region in regions {
                    let annotation = Annotation(
                        kind: .mosaic(rect: region.rect),
                        style: .defaultOutline
                    )
                    detections.append(
                        Detection(annotation: annotation, detectorIdentifier: detector.identifier)
                    )
                }
            } catch {
                continue
            }
        }
        return detections
    }
}
