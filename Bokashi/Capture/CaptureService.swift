import AppKit
import BokashiCore
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

    func captureCursorDisplay() async throws -> CGImage {
        guard let screen = Self.screen(containing: NSEvent.mouseLocation) else {
            throw CaptureError.noDisplay
        }
        let display = try await resolveDisplay(matching: screen)
        return try await capture(display: display)
    }

    func captureRegion(in screenRect: CGRect) async throws -> CGImage {
        let mid = CGPoint(x: screenRect.midX, y: screenRect.midY)
        guard let screen = Self.screen(containing: mid) else {
            throw CaptureError.noDisplay
        }
        let display = try await resolveDisplay(matching: screen)
        let fullImage = try await capture(display: display)

        let pixelRect = ScreenRectConverter.pixelRectInDisplay(
            screenRect: screenRect,
            displayFrame: screen.frame,
            backingScaleFactor: screen.backingScaleFactor
        )

        guard let cropped = fullImage.cropping(to: pixelRect) else {
            throw CaptureError.noDisplay
        }
        return cropped
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

    // MARK: - Helpers

    private static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main
    }

    private func resolveDisplay(matching screen: NSScreen) async throws -> SCDisplay {
        guard let displayID = screen.cgDirectDisplayID else {
            throw CaptureError.noDisplay
        }
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.current
        } catch {
            throw CaptureError.underlying(error)
        }
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.noDisplay
        }
        return display
    }

    private func capture(display: SCDisplay) async throws -> CGImage {
        let mode = CGDisplayCopyDisplayMode(display.displayID)
        let configuration = SCStreamConfiguration()
        configuration.width = mode?.pixelWidth ?? display.width
        configuration.height = mode?.pixelHeight ?? display.height
        configuration.showsCursor = false

        let filter = SCContentFilter(display: display, excludingWindows: [])

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

private extension NSScreen {
    var cgDirectDisplayID: CGDirectDisplayID? {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}
