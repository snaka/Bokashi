import BokashiCore
import CoreGraphics

@MainActor
struct OCRSensitiveRegionDetector: SensitiveRegionDetector {
    nonisolated let identifier = "ocr"

    let observations: [OCRRunner.TextObservation]
    let customTerms: [String]

    func detect(in image: CGImage) async throws -> [DetectedRegion] {
        var regions: [DetectedRegion] = []
        for observation in observations {
            let matches = SensitiveDetectors.detectAll(
                in: observation.text,
                customTerms: customTerms
            )
            for match in matches {
                guard let rect = observation.imageRect(forSubrange: match.nsRange) else { continue }
                regions.append(
                    DetectedRegion(
                        rect: rect.insetBy(dx: -2, dy: -2),
                        label: Self.label(for: match.kind)
                    )
                )
            }
        }
        return regions
    }

    private static func label(for kind: SensitiveKind) -> String {
        switch kind {
        case .email: return "email"
        case .phoneNumber: return "phoneNumber"
        case .address: return "address"
        case .personalName: return "personalName"
        case .customTerm: return "customTerm"
        }
    }
}
