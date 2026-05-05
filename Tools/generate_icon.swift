#!/usr/bin/env swift

// Regenerates the placeholder app + menubar icon assets under
// Bokashi/Assets.xcassets/. Run from the repo root:
//
//   swift Tools/generate_icon.swift
//
// The app icon is a stylised bust-up portrait — skin / black-hair /
// navy-suit / white-shirt / red-tie — with the left half pixelated,
// on a cool-slate rounded square. The menubar icon is a simplified
// solid-black silhouette of the same figure on a transparent
// background, marked as a template so AppKit can tint it for
// light/dark mode.

import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

let assetsDir = "Bokashi/Assets.xcassets"

// AppIcon palette
let backgroundColor = NSColor(red: 0.45, green: 0.50, blue: 0.55, alpha: 1.0)
let skinColor       = NSColor(red: 0.96, green: 0.83, blue: 0.69, alpha: 1.0)
let hairColor       = NSColor(red: 0.13, green: 0.10, blue: 0.10, alpha: 1.0)
let suitColor       = NSColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1.0)
let shirtColor      = NSColor.white
let tieColor        = NSColor(red: 0.78, green: 0.20, blue: 0.22, alpha: 1.0)

// MARK: - Bitmap helpers

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

func roundedSquare(_ canvas: CGFloat, color: NSColor) {
    let path = NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: canvas, height: canvas),
        xRadius: canvas * 0.224,
        yRadius: canvas * 0.224
    )
    color.setFill()
    path.fill()
}

func pixellate(_ image: CGImage, scale: Float) -> CGImage? {
    let ci = CIImage(cgImage: image)
    let filter = CIFilter.pixellate()
    filter.inputImage = ci
    filter.scale = scale
    filter.center = CGPoint(x: ci.extent.midX, y: ci.extent.midY)
    guard let output = filter.outputImage else { return nil }
    let context = CIContext()
    return context.createCGImage(output, from: ci.extent)
}

// MARK: - App icon: detailed portrait

func renderColorPerson(in canvas: CGFloat) {
    let centerX = canvas / 2
    let suitTopY: CGFloat = canvas * 0.42
    let shoulderHalfWidth: CGFloat = canvas * 0.16
    let baseHalfWidth: CGFloat = canvas * 0.42

    // Suit / torso (trapezoid)
    let suit = NSBezierPath()
    suit.move(to: NSPoint(x: centerX - baseHalfWidth, y: 0))
    suit.line(to: NSPoint(x: centerX + baseHalfWidth, y: 0))
    suit.line(to: NSPoint(x: centerX + shoulderHalfWidth, y: suitTopY))
    suit.line(to: NSPoint(x: centerX - shoulderHalfWidth, y: suitTopY))
    suit.close()
    suitColor.setFill()
    suit.fill()

    // Shirt V
    let shirt = NSBezierPath()
    shirt.move(to: NSPoint(x: centerX - canvas * 0.07, y: suitTopY))
    shirt.line(to: NSPoint(x: centerX, y: suitTopY - canvas * 0.12))
    shirt.line(to: NSPoint(x: centerX + canvas * 0.07, y: suitTopY))
    shirt.close()
    shirtColor.setFill()
    shirt.fill()

    // Tie
    let tie = NSBezierPath()
    tie.move(to: NSPoint(x: centerX - canvas * 0.025, y: suitTopY - canvas * 0.10))
    tie.line(to: NSPoint(x: centerX + canvas * 0.025, y: suitTopY - canvas * 0.10))
    tie.line(to: NSPoint(x: centerX + canvas * 0.040, y: suitTopY - canvas * 0.22))
    tie.line(to: NSPoint(x: centerX,                  y: suitTopY - canvas * 0.27))
    tie.line(to: NSPoint(x: centerX - canvas * 0.040, y: suitTopY - canvas * 0.22))
    tie.close()
    tieColor.setFill()
    tie.fill()

    // Head
    let headWidth: CGFloat = canvas * 0.30
    let headHeight: CGFloat = canvas * 0.34
    let headBottomY = suitTopY - canvas * 0.02
    let headRect = NSRect(
        x: centerX - headWidth / 2,
        y: headBottomY,
        width: headWidth,
        height: headHeight
    )
    skinColor.setFill()
    NSBezierPath(ovalIn: headRect).fill()

    // Hair cap
    let hairWidth = headWidth * 1.06
    let hairHeight = headHeight * 0.62
    let hairY = headBottomY + headHeight * 0.50
    let hairRect = NSRect(
        x: centerX - hairWidth / 2,
        y: hairY,
        width: hairWidth,
        height: hairHeight
    )
    hairColor.setFill()
    NSBezierPath(ovalIn: hairRect).fill()
}

func renderForegroundCGImage(_ canvasSize: CGFloat, drawing: () -> Void) -> CGImage {
    let bitmap = makeBitmap(pixels: Int(canvasSize))
    draw(into: bitmap) { drawing() }
    return bitmap.cgImage!
}

func renderAppIcon(pixelSize: Int) -> Data? {
    let canvas = CGFloat(pixelSize)
    let foreground = renderForegroundCGImage(canvas) {
        renderColorPerson(in: canvas)
    }
    guard let pixelated = pixellate(foreground, scale: max(2, Float(canvas) / 14)) else {
        return nil
    }

    let bitmap = makeBitmap(pixels: pixelSize)
    draw(into: bitmap) {
        roundedSquare(canvas, color: backgroundColor)

        let fullRect = NSRect(x: 0, y: 0, width: canvas, height: canvas)
        let half = canvas / 2

        // Right half: sharp portrait
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: NSRect(x: half, y: 0, width: half, height: canvas)).addClip()
        NSImage(cgImage: foreground, size: fullRect.size).draw(in: fullRect)
        NSGraphicsContext.current?.restoreGraphicsState()

        // Left half: pixelated portrait
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: half, height: canvas)).addClip()
        NSImage(cgImage: pixelated, size: fullRect.size).draw(in: fullRect)
        NSGraphicsContext.current?.restoreGraphicsState()
    }
    return bitmap.representation(using: .png, properties: [:])
}

// MARK: - Menubar icon: simplified single-color silhouette (template)

func renderMenuBarSilhouette(in canvas: CGFloat) {
    let centerX = canvas / 2
    let suitTopY: CGFloat = canvas * 0.45
    let shoulderHalfWidth: CGFloat = canvas * 0.18
    let baseHalfWidth: CGFloat = canvas * 0.46

    NSColor.black.setFill()

    // Full bust silhouette (head + suit)
    let suit = NSBezierPath()
    suit.move(to: NSPoint(x: centerX - baseHalfWidth, y: 0))
    suit.line(to: NSPoint(x: centerX + baseHalfWidth, y: 0))
    suit.line(to: NSPoint(x: centerX + shoulderHalfWidth, y: suitTopY))
    suit.line(to: NSPoint(x: centerX - shoulderHalfWidth, y: suitTopY))
    suit.close()
    suit.fill()

    let headWidth: CGFloat = canvas * 0.40
    let headHeight: CGFloat = canvas * 0.46
    let headBottomY = suitTopY - canvas * 0.04
    let headRect = NSRect(
        x: centerX - headWidth / 2,
        y: headBottomY,
        width: headWidth,
        height: headHeight
    )
    NSBezierPath(ovalIn: headRect).fill()

    // Left half: solid block "censor bar" — covers the left half of the
    // bust so the right half remains a recognisable silhouette while the
    // left becomes a featureless rectangle, mirroring the half-mosaic
    // treatment in the app icon.
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: centerX, height: canvas)).fill()
}

func renderMenuBarIcon(pixelSize: Int) -> Data? {
    let bitmap = makeBitmap(pixels: pixelSize)
    draw(into: bitmap) { renderMenuBarSilhouette(in: CGFloat(pixelSize)) }
    return bitmap.representation(using: .png, properties: [:])
}

// MARK: - File helpers

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

// MARK: - Asset catalog plumbing

try makeDirectory(assetsDir)
try writeText(
    """
    {
      "info" : { "version" : 1, "author" : "xcode" }
    }

    """,
    to: "\(assetsDir)/Contents.json"
)

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
