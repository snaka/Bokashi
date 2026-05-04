import BokashiCore
import CoreGraphics

enum Tool: CaseIterable, Hashable {
    case arrow
    case box
    case filledBox
    case ellipse
    case filledEllipse
    case line
    case mosaic

    var label: String {
        switch self {
        case .arrow: return "Arrow"
        case .box: return "Box"
        case .filledBox: return "Filled Box"
        case .ellipse: return "Ellipse"
        case .filledEllipse: return "Filled Ellipse"
        case .line: return "Line"
        case .mosaic: return "Mosaic"
        }
    }

    var systemImage: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .box: return "rectangle"
        case .filledBox: return "rectangle.fill"
        case .ellipse: return "circle"
        case .filledEllipse: return "circle.fill"
        case .line: return "line.diagonal"
        case .mosaic: return "square.grid.3x3.fill"
        }
    }

    var isFilled: Bool {
        switch self {
        case .filledBox, .filledEllipse: return true
        default: return false
        }
    }

    var ignoresStyle: Bool {
        self == .mosaic
    }

    func makeAnnotation(from start: CGPoint, to end: CGPoint, style: AnnotationStyle) -> Annotation {
        switch self {
        case .arrow:
            return Annotation(kind: .arrow(start: start, end: end), style: style)
        case .box, .filledBox:
            return Annotation(kind: .box(rect: .between(start, end)), style: style)
        case .ellipse, .filledEllipse:
            return Annotation(kind: .ellipse(rect: .between(start, end)), style: style)
        case .line:
            return Annotation(kind: .line(start: start, end: end), style: style)
        case .mosaic:
            return Annotation(kind: .mosaic(rect: .between(start, end)), style: style)
        }
    }
}
