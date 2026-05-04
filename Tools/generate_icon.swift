#!/usr/bin/env swift

// Regenerates the placeholder app + menubar icon assets under
// Bokashi/Assets.xcassets/. Run from the repo root:
//
//   swift Tools/generate_icon.swift
//
// The app icon is a rounded-square in Bokashi red with an SF Symbol
// mosaic glyph in white. The menubar icon is the same glyph rendered
// in solid black on a transparent background, marked as a template
// so AppKit handles light/dark tinting automatically.

import AppKit
import Foundation

let assetsDir = "Bokashi/Assets.xcassets"
let backgroundColor = NSColor(red: 0.95, green: 0.22, blue: 0.18, alpha: 1.0)
let symbolName = "square.grid.3x3.fill"

func makeBitmap(pixels: Int) -> NSBitmapImageRep {
    NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 32
    )!
}

func draw(into bitmap: NSBitmapImageRep, body: () -> Void) {
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    body()
    NSGraphicsContext.restoreGraphicsState()
}

func renderAppIcon(pixelSize: Int) -> Data? {
    let size = CGFloat(pixelSize)
    let bitmap = makeBitmap(pixels: pixelSize)
    draw(into: bitmap) {
        let cornerRadius = size * 0.224
        let path = NSBezierPath(
            roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )
        backgroundColor.setFill()
        path.fill()

        let symbolPointSize = size * 0.55
        let config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return }

        let symbolSize = symbol.size
        let symbolRect = NSRect(
            x: (size - symbolSize.width) / 2,
            y: (size - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        symbol.draw(in: symbolRect)
    }
    return bitmap.representation(using: .png, properties: [:])
}

func renderMenuBarIcon(pixelSize: Int) -> Data? {
    let size = CGFloat(pixelSize)
    let bitmap = makeBitmap(pixels: pixelSize)
    draw(into: bitmap) {
        let symbolPointSize = size * 0.95
        let config = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.black]))
        guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return }

        let symbolSize = symbol.size
        let symbolRect = NSRect(
            x: (size - symbolSize.width) / 2,
            y: (size - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        symbol.draw(in: symbolRect)
    }
    return bitmap.representation(using: .png, properties: [:])
}

func write(_ data: Data, to path: String) throws {
    try data.write(to: URL(fileURLWithPath: path))
    print("Wrote \(path)")
}

func writeText(_ text: String, to path: String) throws {
    try text.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    print("Wrote \(path)")
}

func makeDirectory(_ path: String) throws {
    try FileManager.default.createDirectory(
        at: URL(fileURLWithPath: path),
        withIntermediateDirectories: true
    )
}

// MARK: - Asset Catalog root

try makeDirectory(assetsDir)
try writeText(
    """
    {
      "info" : { "version" : 1, "author" : "xcode" }
    }

    """,
    to: "\(assetsDir)/Contents.json"
)

// MARK: - AppIcon.appiconset

let appIconDir = "\(assetsDir)/AppIcon.appiconset"
try makeDirectory(appIconDir)

let appIconSizes: [(filename: String, pixels: Int)] = [
    ("icon_16.png", 16),
    ("icon_32.png", 32),
    ("icon_64.png", 64),
    ("icon_128.png", 128),
    ("icon_256.png", 256),
    ("icon_512.png", 512),
    ("icon_1024.png", 1024),
]
for (filename, pixels) in appIconSizes {
    guard let data = renderAppIcon(pixelSize: pixels) else {
        FileHandle.standardError.write(Data("Failed to render \(filename)\n".utf8))
        exit(1)
    }
    try write(data, to: "\(appIconDir)/\(filename)")
}

try writeText(
    """
    {
      "images" : [
        { "size" : "16x16",   "idiom" : "mac", "filename" : "icon_16.png",   "scale" : "1x" },
        { "size" : "16x16",   "idiom" : "mac", "filename" : "icon_32.png",   "scale" : "2x" },
        { "size" : "32x32",   "idiom" : "mac", "filename" : "icon_32.png",   "scale" : "1x" },
        { "size" : "32x32",   "idiom" : "mac", "filename" : "icon_64.png",   "scale" : "2x" },
        { "size" : "128x128", "idiom" : "mac", "filename" : "icon_128.png",  "scale" : "1x" },
        { "size" : "128x128", "idiom" : "mac", "filename" : "icon_256.png",  "scale" : "2x" },
        { "size" : "256x256", "idiom" : "mac", "filename" : "icon_256.png",  "scale" : "1x" },
        { "size" : "256x256", "idiom" : "mac", "filename" : "icon_512.png",  "scale" : "2x" },
        { "size" : "512x512", "idiom" : "mac", "filename" : "icon_512.png",  "scale" : "1x" },
        { "size" : "512x512", "idiom" : "mac", "filename" : "icon_1024.png", "scale" : "2x" }
      ],
      "info" : { "version" : 1, "author" : "xcode" }
    }

    """,
    to: "\(appIconDir)/Contents.json"
)

// MARK: - MenuBarIcon.imageset

let menuBarDir = "\(assetsDir)/MenuBarIcon.imageset"
try makeDirectory(menuBarDir)

let menuBarSizes: [(filename: String, pixels: Int)] = [
    ("menubar.png", 18),
    ("menubar@2x.png", 36),
    ("menubar@3x.png", 54),
]
for (filename, pixels) in menuBarSizes {
    guard let data = renderMenuBarIcon(pixelSize: pixels) else {
        FileHandle.standardError.write(Data("Failed to render \(filename)\n".utf8))
        exit(1)
    }
    try write(data, to: "\(menuBarDir)/\(filename)")
}

try writeText(
    """
    {
      "images" : [
        { "filename" : "menubar.png",    "scale" : "1x", "idiom" : "universal" },
        { "filename" : "menubar@2x.png", "scale" : "2x", "idiom" : "universal" },
        { "filename" : "menubar@3x.png", "scale" : "3x", "idiom" : "universal" }
      ],
      "info" : { "version" : 1, "author" : "xcode" },
      "properties" : { "template-rendering-intent" : "template" }
    }

    """,
    to: "\(menuBarDir)/Contents.json"
)
