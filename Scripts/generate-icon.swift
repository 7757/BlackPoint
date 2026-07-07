#!/usr/bin/env swift

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: generate-icon.swift <output.icns>\n".utf8))
    exit(64)
}

let outputURL = URL(fileURLWithPath: arguments[1])
let iconsetURL = outputURL
    .deletingPathExtension()
    .appendingPathExtension("iconset")

try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

struct IconVariant {
    let fileName: String
    let pixels: Int
}

let variants = [
    IconVariant(fileName: "icon_16x16.png", pixels: 16),
    IconVariant(fileName: "icon_16x16@2x.png", pixels: 32),
    IconVariant(fileName: "icon_32x32.png", pixels: 32),
    IconVariant(fileName: "icon_32x32@2x.png", pixels: 64),
    IconVariant(fileName: "icon_128x128.png", pixels: 128),
    IconVariant(fileName: "icon_128x128@2x.png", pixels: 256),
    IconVariant(fileName: "icon_256x256.png", pixels: 256),
    IconVariant(fileName: "icon_256x256@2x.png", pixels: 512),
    IconVariant(fileName: "icon_512x512.png", pixels: 512),
    IconVariant(fileName: "icon_512x512@2x.png", pixels: 1024)
]

func writePNG(size: Int, to url: URL) throws {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    rect.fill()

    let iconSize = CGFloat(size)
    let inset = iconSize * 0.055
    let radius = iconSize * 0.23
    let background = NSBezierPath(
        roundedRect: rect.insetBy(dx: inset, dy: inset),
        xRadius: radius,
        yRadius: radius
    )

    NSGraphicsContext.saveGraphicsState()
    background.addClip()

    NSGradient(colors: [
        NSColor(calibratedRed: 0.006, green: 0.008, blue: 0.018, alpha: 1),
        NSColor(calibratedRed: 0.030, green: 0.034, blue: 0.058, alpha: 1),
        NSColor(calibratedRed: 0.010, green: 0.012, blue: 0.024, alpha: 1)
    ])?.draw(in: background, angle: -35)

    let center = NSPoint(x: iconSize * 0.50, y: iconSize * 0.52)

    func ovalPath(width: CGFloat, height: CGFloat) -> NSBezierPath {
        NSBezierPath(ovalIn: NSRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        ))
    }

    func withRotation(_ degrees: CGFloat, draw: () -> Void) {
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byDegrees: degrees)
        transform.translateX(by: -center.x, yBy: -center.y)
        transform.concat()
        draw()
        NSGraphicsContext.restoreGraphicsState()
    }

    for index in 0..<32 {
        let seed = CGFloat((index * 37) % 97) / 97
        let starSize = max(1, iconSize * (0.004 + seed * 0.006))
        let x = iconSize * (0.15 + CGFloat((index * 19) % 71) / 100)
        let y = iconSize * (0.16 + CGFloat((index * 31) % 69) / 100)
        let distance = hypot(x - center.x, y - center.y)

        if distance > iconSize * 0.18 {
            NSColor(calibratedRed: 0.78, green: 0.86, blue: 1.0, alpha: 0.10 + seed * 0.16).setFill()
            NSBezierPath(ovalIn: NSRect(
                x: x - starSize / 2,
                y: y - starSize / 2,
                width: starSize,
                height: starSize
            )).fill()
        }
    }

    NSGradient(colors: [
        NSColor(calibratedRed: 0.32, green: 0.54, blue: 1.0, alpha: 0.28),
        NSColor(calibratedRed: 0.72, green: 0.30, blue: 1.0, alpha: 0.10),
        NSColor.clear
    ])?.draw(
        in: NSBezierPath(ovalIn: NSRect(
            x: center.x - iconSize * 0.44,
            y: center.y - iconSize * 0.34,
            width: iconSize * 0.88,
            height: iconSize * 0.68
        )),
        relativeCenterPosition: NSPoint(x: -0.12, y: 0.10)
    )

    for index in 0..<5 {
        let t = CGFloat(index)
        let path = ovalPath(width: iconSize * (0.62 + t * 0.035), height: iconSize * (0.22 + t * 0.020))
        path.lineWidth = max(1, iconSize * (0.010 + t * 0.002))
        path.lineCapStyle = .round

        let color: NSColor
        switch index {
        case 0:
            color = NSColor(calibratedRed: 0.98, green: 0.74, blue: 0.44, alpha: 0.70)
        case 1:
            color = NSColor(calibratedRed: 0.64, green: 0.82, blue: 1.0, alpha: 0.48)
        case 2:
            color = NSColor(calibratedRed: 0.80, green: 0.50, blue: 1.0, alpha: 0.34)
        default:
            color = NSColor(calibratedRed: 0.86, green: 0.92, blue: 1.0, alpha: 0.20)
        }

        withRotation(-18 + t * 3) {
            color.setStroke()
            path.stroke()
        }
    }

    NSGradient(colors: [
        NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.48, alpha: 0.40),
        NSColor(calibratedRed: 0.40, green: 0.68, blue: 1.0, alpha: 0.18),
        NSColor.clear
    ])?.draw(
        in: NSBezierPath(ovalIn: NSRect(
            x: center.x - iconSize * 0.25,
            y: center.y - iconSize * 0.13,
            width: iconSize * 0.50,
            height: iconSize * 0.26
        )),
        relativeCenterPosition: NSPoint(x: 0.2, y: 0.0)
    )

    let coreRect = NSRect(
        x: center.x - iconSize * 0.145,
        y: center.y - iconSize * 0.145,
        width: iconSize * 0.29,
        height: iconSize * 0.29
    )

    NSGradient(colors: [
        NSColor(calibratedRed: 0.58, green: 0.72, blue: 1.0, alpha: 0.34),
        NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.24, alpha: 0.16),
        NSColor.clear
    ])?.draw(
        in: NSBezierPath(ovalIn: coreRect.insetBy(dx: -iconSize * 0.09, dy: -iconSize * 0.09)),
        relativeCenterPosition: NSPoint(x: -0.08, y: 0.1)
    )

    NSColor(calibratedWhite: 0.0, alpha: 0.96).setFill()
    NSBezierPath(ovalIn: coreRect).fill()

    let highlightSize = max(1.2, iconSize * 0.020)
    NSColor(calibratedRed: 0.82, green: 0.92, blue: 1.0, alpha: 0.72).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: center.x + iconSize * 0.155,
        y: center.y + iconSize * 0.055,
        width: highlightSize,
        height: highlightSize
    )).fill()

    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.10).setStroke()
    background.lineWidth = max(1, CGFloat(size) * 0.015)
    background.stroke()

    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "BlackPointIcon", code: 1)
    }

    try pngData.write(to: url)
}

for variant in variants {
    try writePNG(size: variant.pixels, to: iconsetURL.appendingPathComponent(variant.fileName))
}

try? FileManager.default.removeItem(at: outputURL)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try process.run()
process.waitUntilExit()

try? FileManager.default.removeItem(at: iconsetURL)
exit(process.terminationStatus)
