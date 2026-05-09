import BokashiCore
import CoreGraphics

enum AutoMasker {
    static func detect(
        in observations: [OCRRunner.TextObservation],
        customTerms: [String] = []
    ) -> [Annotation] {
        var annotations: [Annotation] = []
        for observation in observations {
            let matches = SensitiveDetectors.detectAll(
                in: observation.text,
                customTerms: customTerms
            )
            for match in matches {
                guard let rect = observation.imageRect(forSubrange: match.nsRange) else { continue }
                let padded = rect.insetBy(dx: -2, dy: -2)
                annotations.append(
                    Annotation(kind: .mosaic(rect: padded), style: .defaultOutline)
                )
            }
        }
        return annotations
    }
}
