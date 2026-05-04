import CoreGraphics
import Foundation

public struct Annotation: Identifiable, Hashable, Sendable {
    public enum Kind: Hashable, Sendable {
        case arrow(start: CGPoint, end: CGPoint)
        case box(rect: CGRect)
        case ellipse(rect: CGRect)
        case line(start: CGPoint, end: CGPoint)
    }

    public let id: UUID
    public var kind: Kind
    public var style: AnnotationStyle

    public init(id: UUID = UUID(), kind: Kind, style: AnnotationStyle) {
        self.id = id
        self.kind = kind
        self.style = style
    }
}

extension CGRect {
    public static func between(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(a.x - b.x),
            height: abs(a.y - b.y)
        )
    }
}
