import CoreGraphics
import ScreenCaptureKit

@MainActor
final class CaptureService {
    enum CaptureError: Error, LocalizedError {
        case noDisplay
        case underlying(Error)

        var errorDescription: String? {
            switch self {
            case .noDisplay:
                return "No display is available to capture."
            case .underlying(let error):
                return error.localizedDescription
            }
        }
    }

    func captureMainDisplay() async throws -> CGImage {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.current
        } catch {
            throw CaptureError.underlying(error)
        }
        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        let mode = CGDisplayCopyDisplayMode(display.displayID)
        configuration.width = mode?.pixelWidth ?? display.width
        configuration.height = mode?.pixelHeight ?? display.height
        configuration.showsCursor = false

        do {
            return try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
        } catch {
            throw CaptureError.underlying(error)
        }
    }

    func captureWindow(_ window: SCWindow) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        let pixelScale = Double(filter.pointPixelScale)
        configuration.width = Int(filter.contentRect.width * pixelScale)
        configuration.height = Int(filter.contentRect.height * pixelScale)
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true

        do {
            return try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
        } catch {
            throw CaptureError.underlying(error)
        }
    }
}
