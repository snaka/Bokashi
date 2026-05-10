import BokashiCore
import CoreGraphics
import SwiftUI

struct AnnotationCanvas: View {
    let image: CGImage
    let mosaicImage: CGImage?
    let state: EditorState

    @State private var dev = DeveloperSettings.shared

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let displayRect = displayedImageRect(in: size)
                context.draw(
                    Image(image, scale: 1, label: Text("Captured screenshot")),
                    in: displayRect
                )
                let scale = displayRect.width / CGFloat(image.width)
                let transform: (CGPoint) -> CGPoint = { point in
                    CGPoint(
                        x: displayRect.origin.x + point.x * scale,
                        y: displayRect.origin.y + point.y * scale
                    )
                }
                let renderContext = AnnotationDrawing.RenderContext(
                    transform: transform,
                    displayScale: scale,
                    imageDisplayRect: displayRect,
                    mosaicImage: mosaicImage
                )
                for annotation in state.annotations {
                    var ctx = context
                    AnnotationDrawing.draw(annotation, in: &ctx, with: renderContext)
                }
                if dev.highlightMaskSource {
                    drawDebugSourceOverlay(
                        context: context,
                        scale: scale,
                        transform: transform
                    )
                }
                if let draft = state.draft {
                    var ctx = context
                    AnnotationDrawing.draw(draft, in: &ctx, with: renderContext)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let canvasSize = geometry.size
                        let imageStart = canvasToImage(value.startLocation, canvasSize: canvasSize)
                        let imageEnd = canvasToImage(value.location, canvasSize: canvasSize)
                        state.updateDraft(start: imageStart, current: imageEnd)
                    }
                    .onEnded { _ in
                        state.commitDraft()
                    }
            )
        }
        .background(Color.black.opacity(0.7))
    }

    private func displayedImageRect(in size: CGSize) -> CGRect {
        let imageW = CGFloat(image.width)
        let imageH = CGFloat(image.height)
        guard imageW > 0, imageH > 0, size.width > 0, size.height > 0 else {
            return CGRect(origin: .zero, size: size)
        }
        let imageAspect = imageW / imageH
        let canvasAspect = size.width / size.height
        if imageAspect > canvasAspect {
            let w = size.width
            let h = w / imageAspect
            return CGRect(x: 0, y: (size.height - h) / 2, width: w, height: h)
        } else {
            let h = size.height
            let w = h * imageAspect
            return CGRect(x: (size.width - w) / 2, y: 0, width: w, height: h)
        }
    }

    private func drawDebugSourceOverlay(
        context: GraphicsContext,
        scale: CGFloat,
        transform: (CGPoint) -> CGPoint
    ) {
        for annotation in state.annotations {
            guard case .mosaic(let rect) = annotation.kind,
                  let source = state.detectorSource(for: annotation.id)
            else { continue }
            let topLeft = transform(rect.origin)
            let displayRect = CGRect(
                x: topLeft.x,
                y: topLeft.y,
                width: rect.width * scale,
                height: rect.height * scale
            )
            var ctx = context
            ctx.stroke(
                Path(displayRect),
                with: .color(Self.debugColor(for: source)),
                style: StrokeStyle(lineWidth: 3, lineJoin: .round, dash: [6, 4])
            )
        }
    }

    private static func debugColor(for source: String) -> Color {
        switch source {
        case "ocr": return .blue
        case "ollama": return .orange
        default: return .gray
        }
    }

    private func canvasToImage(_ point: CGPoint, canvasSize: CGSize) -> CGPoint {
        let displayRect = displayedImageRect(in: canvasSize)
        guard displayRect.width > 0, image.width > 0 else { return .zero }
        let scale = displayRect.width / CGFloat(image.width)
        return CGPoint(
            x: (point.x - displayRect.origin.x) / scale,
            y: (point.y - displayRect.origin.y) / scale
        )
    }
}
