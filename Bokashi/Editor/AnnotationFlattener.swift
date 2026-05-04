import BokashiCore
import CoreGraphics
import SwiftUI

@MainActor
enum AnnotationFlattener {
    static func flatten(
        image: CGImage,
        mosaicImage: CGImage?,
        annotations: [Annotation]
    ) -> CGImage {
        guard !annotations.isEmpty else { return image }
        let renderer = ImageRenderer(
            content: AnnotatedImageView(
                image: image,
                mosaicImage: mosaicImage,
                annotations: annotations
            )
        )
        renderer.scale = 1
        return renderer.cgImage ?? image
    }
}

private struct AnnotatedImageView: View {
    let image: CGImage
    let mosaicImage: CGImage?
    let annotations: [Annotation]

    var body: some View {
        Canvas { context, size in
            let imageRect = CGRect(origin: .zero, size: size)
            context.draw(
                Image(image, scale: 1, label: Text("Captured screenshot")),
                in: imageRect
            )
            let renderContext = AnnotationDrawing.RenderContext(
                transform: { $0 },
                displayScale: 1,
                imageDisplayRect: imageRect,
                mosaicImage: mosaicImage
            )
            for annotation in annotations {
                var ctx = context
                AnnotationDrawing.draw(annotation, in: &ctx, with: renderContext)
            }
        }
        .frame(width: CGFloat(image.width), height: CGFloat(image.height))
    }
}
