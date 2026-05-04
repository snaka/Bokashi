import CoreGraphics
import Foundation

public struct AnnotationStyle: Hashable, Codable, Sendable {
    public var color: RGBA
    public var lineWidth: CGFloat
    public var filled: Bool

    public init(color: RGBA, lineWidth: CGFloat, filled: Bool = false) {
        self.color = color
        self.lineWidth = lineWidth
        self.filled = filled
    }

    public static let defaultOutline = AnnotationStyle(color: .bokashiRed, lineWidth: 4, filled: false)
    public static let defaultFilled = AnnotationStyle(color: .bokashiRed, lineWidth: 4, filled: true)

    public enum WidthPreset: CaseIterable, Hashable, Sendable {
        case thin
        case medium
        case thick

        public var lineWidth: CGFloat {
            switch self {
            case .thin: return 2
            case .medium: return 4
            case .thick: return 8
            }
        }

        public var label: String {
            switch self {
            case .thin: return "Thin"
            case .medium: return "Medium"
            case .thick: return "Thick"
            }
        }
    }
}
