import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins

enum MosaicRenderer {
    static let defaultBlockSize: CGFloat = 16

    private static let context = CIContext()

    static func apply(to image: CGImage, blockSize: CGFloat = defaultBlockSize) -> CGImage? {
        let input = CIImage(cgImage: image)
        let filter = CIFilter.pixellate()
        filter.inputImage = input
        filter.scale = Float(blockSize)
        filter.center = CGPoint(x: input.extent.midX, y: input.extent.midY)
        guard let output = filter.outputImage else { return nil }
        return context.createCGImage(output, from: input.extent)
    }
}
