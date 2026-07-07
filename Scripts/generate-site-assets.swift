#!/usr/bin/env swift

import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("docs/assets")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func pngData(from image: NSImage) throws -> Data {
    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let data = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "BlackPointSiteAssets", code: 1)
    }
    return data
}

func drawRoundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func writeAppIcon() throws {
    let size: CGFloat = 512
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let background = NSBezierPath(roundedRect: NSRect(x: 28, y: 28, width: 456, height: 456), xRadius: 118, yRadius: 118)
    NSGraphicsContext.saveGraphicsState()
    background.addClip()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.006, green: 0.008, blue: 0.018, alpha: 1),
        NSColor(calibratedRed: 0.036, green: 0.040, blue: 0.070, alpha: 1)
    ])?.draw(in: background, angle: -35)

    NSGradient(colors: [
        NSColor(calibratedRed: 0.42, green: 0.58, blue: 1.0, alpha: 0.34),
        NSColor(calibratedRed: 0.68, green: 0.30, blue: 1.0, alpha: 0.10),
        .clear
    ])?.draw(in: NSBezierPath(ovalIn: NSRect(x: 74, y: 92, width: 364, height: 326)), relativeCenterPosition: .zero)

    let center = NSPoint(x: 256, y: 260)
    for index in 0..<5 {
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byDegrees: -18 + CGFloat(index) * 3)
        transform.translateX(by: -center.x, yBy: -center.y)
        transform.concat()

        let path = NSBezierPath(ovalIn: NSRect(
            x: center.x - 170 - CGFloat(index) * 9,
            y: center.y - 57 - CGFloat(index) * 3,
            width: 340 + CGFloat(index) * 18,
            height: 114 + CGFloat(index) * 6
        ))
        path.lineWidth = 5 + CGFloat(index)
        path.lineCapStyle = .round
        let alpha = max(0.18, 0.72 - CGFloat(index) * 0.12)
        NSColor(calibratedRed: index == 1 ? 0.50 : 0.95, green: index == 1 ? 0.68 : 0.78, blue: index == 1 ? 1.0 : 0.54, alpha: alpha).setStroke()
        path.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }

    NSGradient(colors: [
        NSColor(calibratedRed: 0.92, green: 0.96, blue: 1.0, alpha: 0.36),
        NSColor(calibratedWhite: 0, alpha: 0.96)
    ])?.draw(in: NSBezierPath(ovalIn: NSRect(x: 176, y: 180, width: 160, height: 160)), relativeCenterPosition: NSPoint(x: -0.18, y: 0.18))
    NSColor.black.setFill()
    NSBezierPath(ovalIn: NSRect(x: 184, y: 188, width: 144, height: 144)).fill()

    NSGraphicsContext.restoreGraphicsState()
    NSColor.white.withAlphaComponent(0.12).setStroke()
    background.lineWidth = 7
    background.stroke()
    image.unlockFocus()

    try pngData(from: image).write(to: output.appendingPathComponent("app-icon.png"))
}

try writeAppIcon()
