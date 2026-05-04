import BokashiCore
import CoreGraphics
import SwiftUI

@MainActor
enum AnnotationFlattener {
    static func flatten(image: CGImage, annotations: [Annotation]) -> CGImage {
        guard !annotations.isEmpty else { return image }
        let renderer = ImageRenderer(
            content: AnnotatedImageView(image: image, annotations: annotations)
        )
        renderer.scale = 1
        return renderer.cgImage ?? image
    }
}

private struct AnnotatedImageView: View {
    let image: CGImage
    let annotations: [Annotation]

    var body: some View {
        Canvas { context, size in
            context.draw(
                Image(image, scale: 1, label: Text("Captured screenshot")),
                in: CGRect(origin: .zero, size: size)
            )
            let identity: (CGPoint) -> CGPoint = { $0 }
            for annotation in annotations {
                var ctx = context
                AnnotationDrawing.draw(annotation, in: &ctx, transform: identity, displayScale: 1)
            }
        }
        .frame(width: CGFloat(image.width), height: CGFloat(image.height))
    }
}
