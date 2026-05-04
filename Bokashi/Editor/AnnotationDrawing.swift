import BokashiCore
import CoreGraphics
import SwiftUI

@MainActor
enum AnnotationDrawing {
    struct RenderContext {
        let transform: (CGPoint) -> CGPoint
        let displayScale: CGFloat
        let imageDisplayRect: CGRect
        let mosaicImage: CGImage?
    }

    static func draw(
        _ annotation: Annotation,
        in context: inout GraphicsContext,
        with renderContext: RenderContext
    ) {
        let color = Color(annotation.style.color)
        let lineWidth = annotation.style.lineWidth * renderContext.displayScale

        switch annotation.kind {
        case .line(let start, let end):
            var path = Path()
            path.move(to: renderContext.transform(start))
            path.addLine(to: renderContext.transform(end))
            context.stroke(
                path,
                with: .color(color),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )

        case .box(let rect):
            let path = Path(transformRect(rect, with: renderContext.transform))
            if annotation.style.filled {
                context.fill(path, with: .color(color))
            } else {
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }

        case .ellipse(let rect):
            let path = Path(ellipseIn: transformRect(rect, with: renderContext.transform))
            if annotation.style.filled {
                context.fill(path, with: .color(color))
            } else {
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }

        case .arrow(let start, let end):
            drawArrow(
                from: renderContext.transform(start),
                to: renderContext.transform(end),
                in: &context,
                lineWidth: lineWidth,
                color: color
            )

        case .mosaic(let rect):
            guard let mosaicImage = renderContext.mosaicImage else { return }
            let canvasRect = transformRect(rect, with: renderContext.transform)
            var clipped = context
            clipped.clip(to: Path(canvasRect))
            clipped.draw(
                Image(decorative: mosaicImage, scale: 1),
                in: renderContext.imageDisplayRect
            )
        }
    }

    private static func transformRect(
        _ rect: CGRect,
        with transform: (CGPoint) -> CGPoint
    ) -> CGRect {
        CGRect.between(
            transform(rect.origin),
            transform(CGPoint(x: rect.maxX, y: rect.maxY))
        )
    }

    private static func drawArrow(
        from start: CGPoint,
        to end: CGPoint,
        in ctx: inout GraphicsContext,
        lineWidth: CGFloat,
        color: Color
    ) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = (dx * dx + dy * dy).squareRoot()
        guard length > 0.5 else { return }

        let arrowLength = max(lineWidth * 4, 12)
        let arrowWidth = max(lineWidth * 3, 9)

        let dirX = dx / length
        let dirY = dy / length
        let perpX = -dirY
        let perpY = dirX

        let shaftEnd = CGPoint(
            x: end.x - dirX * arrowLength * 0.7,
            y: end.y - dirY * arrowLength * 0.7
        )

        var shaft = Path()
        shaft.move(to: start)
        shaft.addLine(to: shaftEnd)
        ctx.stroke(
            shaft,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )

        let leftBase = CGPoint(
            x: end.x - dirX * arrowLength + perpX * arrowWidth / 2,
            y: end.y - dirY * arrowLength + perpY * arrowWidth / 2
        )
        let rightBase = CGPoint(
            x: end.x - dirX * arrowLength - perpX * arrowWidth / 2,
            y: end.y - dirY * arrowLength - perpY * arrowWidth / 2
        )
        var head = Path()
        head.move(to: end)
        head.addLine(to: leftBase)
        head.addLine(to: rightBase)
        head.closeSubpath()
        ctx.fill(head, with: .color(color))
    }
}

extension Color {
    init(_ rgba: RGBA) {
        self.init(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
    }
}
