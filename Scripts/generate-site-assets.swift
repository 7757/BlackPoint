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

func writeProductPreview() throws {
    let width: CGFloat = 980
    let height: CGFloat = 720
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    NSGradient(colors: [
        NSColor(calibratedRed: 0.86, green: 0.90, blue: 0.98, alpha: 0.55),
        NSColor(calibratedRed: 0.97, green: 0.98, blue: 1.0, alpha: 0.05)
    ])?.draw(in: NSBezierPath(ovalIn: NSRect(x: 80, y: 86, width: 810, height: 560)), angle: 0)

    let menuRect = NSRect(x: 170, y: 505, width: 640, height: 54)
    drawRoundedRect(menuRect, radius: 27, color: NSColor.white.withAlphaComponent(0.82))
    NSColor(calibratedRed: 0.22, green: 0.28, blue: 0.40, alpha: 0.14).setStroke()
    NSBezierPath(roundedRect: menuRect, xRadius: 27, yRadius: 27).stroke()

    for x in stride(from: menuRect.minX + 25, through: menuRect.maxX - 25, by: 88) {
        drawRoundedRect(NSRect(x: x, y: menuRect.midY - 5, width: 48, height: 10), radius: 5, color: NSColor(calibratedRed: 0.72, green: 0.76, blue: 0.84, alpha: 0.46))
    }

    let panel = NSRect(x: 290, y: 126, width: 400, height: 500)
    drawRoundedRect(panel, radius: 34, color: NSColor(calibratedRed: 0.018, green: 0.020, blue: 0.030, alpha: 0.98))
    NSColor.white.withAlphaComponent(0.12).setStroke()
    let panelPath = NSBezierPath(roundedRect: panel, xRadius: 34, yRadius: 34)
    panelPath.lineWidth = 1.5
    panelPath.stroke()

    drawRoundedRect(NSRect(x: 316, y: 576, width: 34, height: 34), radius: 9, color: NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.10, alpha: 1))
    NSColor(calibratedRed: 0.82, green: 0.88, blue: 1.0, alpha: 0.82).setFill()
    NSBezierPath(ovalIn: NSRect(x: 326, y: 586, width: 14, height: 14)).fill()

    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 20, weight: .semibold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.92)
    ]
    "BlackPoint".draw(at: NSPoint(x: 362, y: 585), withAttributes: titleAttributes)

    let subAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white.withAlphaComponent(0.44)
    ]
    "Quietly stow apps out of the way.".draw(at: NSPoint(x: 362, y: 565), withAttributes: subAttributes)

    let tab = NSRect(x: 336, y: 522, width: 308, height: 34)
    drawRoundedRect(tab, radius: 17, color: NSColor.white.withAlphaComponent(0.038))
    drawRoundedRect(NSRect(x: 340, y: 526, width: 96, height: 26), radius: 13, color: NSColor.white.withAlphaComponent(0.070))

    let tabAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.82)
    ]
    "Stowed".draw(at: NSPoint(x: 365, y: 533), withAttributes: tabAttrs)
    let mutedTabAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white.withAlphaComponent(0.40)
    ]
    "Running".draw(at: NSPoint(x: 471, y: 533), withAttributes: mutedTabAttrs)
    "Settings".draw(at: NSPoint(x: 565, y: 533), withAttributes: mutedTabAttrs)

    let blackHoleCenter = NSPoint(x: panel.midX, y: 374)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.36, green: 0.56, blue: 1.0, alpha: 0.20),
        NSColor(calibratedRed: 0.75, green: 0.36, blue: 1.0, alpha: 0.07),
        .clear
    ])?.draw(in: NSBezierPath(ovalIn: NSRect(x: blackHoleCenter.x - 145, y: blackHoleCenter.y - 90, width: 290, height: 180)), angle: 0)

    for index in 0..<8 {
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: blackHoleCenter.x, yBy: blackHoleCenter.y)
        transform.rotate(byDegrees: -16 + CGFloat(index) * 2)
        transform.translateX(by: -blackHoleCenter.x, yBy: -blackHoleCenter.y)
        transform.concat()
        let ring = NSBezierPath(ovalIn: NSRect(x: blackHoleCenter.x - 130 - CGFloat(index) * 3, y: blackHoleCenter.y - 35 - CGFloat(index) * 1.5, width: 260 + CGFloat(index) * 6, height: 70 + CGFloat(index) * 3))
        ring.lineWidth = 1.2 + CGFloat(index) * 0.18
        NSColor(calibratedRed: 0.62, green: 0.74, blue: 1.0, alpha: max(0.08, 0.34 - CGFloat(index) * 0.03)).setStroke()
        ring.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }

    NSColor.black.setFill()
    NSBezierPath(ovalIn: NSRect(x: blackHoleCenter.x - 44, y: blackHoleCenter.y - 44, width: 88, height: 88)).fill()

    let button = NSRect(x: 406, y: 214, width: 168, height: 36)
    drawRoundedRect(button, radius: 18, color: NSColor.white.withAlphaComponent(0.052))
    NSColor.white.withAlphaComponent(0.08).setStroke()
    NSBezierPath(roundedRect: button, xRadius: 18, yRadius: 18).stroke()
    let buttonAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white.withAlphaComponent(0.68)
    ]
    "Choose a running app".draw(at: NSPoint(x: 432, y: 225), withAttributes: buttonAttrs)

    image.unlockFocus()
    try pngData(from: image).write(to: output.appendingPathComponent("product-preview.png"))
}

try writeAppIcon()
try writeProductPreview()
