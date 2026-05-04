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

    public static let defaultOutline = AnnotationStyle(color: .bokashiRed, lineWidth: 3, filled: false)
    public static let defaultFilled = AnnotationStyle(color: .bokashiRed, lineWidth: 3, filled: true)
}
