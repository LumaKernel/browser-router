#!/usr/bin/env swift

import Cocoa

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Background: rounded rect with gradient
    let inset: CGFloat = s * 0.08
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = s * 0.2
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient: deep teal to vibrant blue
    let colors = [
        CGColor(srgbRed: 0.08, green: 0.18, blue: 0.28, alpha: 1.0),
        CGColor(srgbRed: 0.10, green: 0.35, blue: 0.55, alpha: 1.0),
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: s/2, y: s), end: CGPoint(x: s/2, y: 0), options: [])
    ctx.restoreGState()

    // Subtle border
    ctx.setStrokeColor(CGColor(srgbRed: 0.2, green: 0.5, blue: 0.7, alpha: 0.5))
    ctx.setLineWidth(s * 0.015)
    ctx.addPath(bgPath)
    ctx.strokePath()

    // Center circle (hub)
    let hubRadius = s * 0.12
    let cx = s / 2
    let cy = s / 2
    let hubRect = CGRect(x: cx - hubRadius, y: cy - hubRadius, width: hubRadius * 2, height: hubRadius * 2)

    let hubColors = [
        CGColor(srgbRed: 0.3, green: 0.75, blue: 0.95, alpha: 1.0),
        CGColor(srgbRed: 0.15, green: 0.55, blue: 0.8, alpha: 1.0),
    ]
    let hubGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: hubColors as CFArray, locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.addEllipse(in: hubRect)
    ctx.clip()
    ctx.drawRadialGradient(hubGradient, startCenter: CGPoint(x: cx, y: cy + hubRadius * 0.3), startRadius: 0, endCenter: CGPoint(x: cx, y: cy), endRadius: hubRadius, options: .drawsAfterEndLocation)
    ctx.restoreGState()

    // Routing arrows from center to 3 directions (top-left, top-right, bottom)
    let arrowColor = CGColor(srgbRed: 0.5, green: 0.85, blue: 1.0, alpha: 0.9)
    ctx.setStrokeColor(arrowColor)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(s * 0.035)

    struct ArrowTarget {
        let angle: CGFloat // radians from center
        let length: CGFloat
    }

    let targets = [
        ArrowTarget(angle: .pi * 0.75, length: s * 0.28),   // top-left
        ArrowTarget(angle: .pi * 0.25, length: s * 0.28),   // top-right
        ArrowTarget(angle: -.pi * 0.5, length: s * 0.28),   // bottom
    ]

    for target in targets {
        let startDist = hubRadius + s * 0.03
        let sx = cx + cos(target.angle) * startDist
        let sy = cy + sin(target.angle) * startDist
        let ex = cx + cos(target.angle) * target.length
        let ey = cy + sin(target.angle) * target.length

        // Line
        ctx.move(to: CGPoint(x: sx, y: sy))
        ctx.addLine(to: CGPoint(x: ex, y: ey))
        ctx.strokePath()

        // Arrowhead
        let headLen = s * 0.06
        let headAngle: CGFloat = 0.45
        let a1x = ex - cos(target.angle - headAngle) * headLen
        let a1y = ey - sin(target.angle - headAngle) * headLen
        let a2x = ex - cos(target.angle + headAngle) * headLen
        let a2y = ey - sin(target.angle + headAngle) * headLen

        ctx.move(to: CGPoint(x: a1x, y: a1y))
        ctx.addLine(to: CGPoint(x: ex, y: ey))
        ctx.addLine(to: CGPoint(x: a2x, y: a2y))
        ctx.strokePath()
    }

    // Small circles at arrow endpoints (browser nodes)
    let nodeRadius = s * 0.055
    let nodeColors = [
        CGColor(srgbRed: 0.95, green: 0.6, blue: 0.2, alpha: 1.0),  // orange
        CGColor(srgbRed: 0.3, green: 0.8, blue: 0.4, alpha: 1.0),   // green
        CGColor(srgbRed: 0.85, green: 0.3, blue: 0.5, alpha: 1.0),  // pink
    ]

    for (i, target) in targets.enumerated() {
        let nx = cx + cos(target.angle) * (target.length + nodeRadius * 0.5)
        let ny = cy + sin(target.angle) * (target.length + nodeRadius * 0.5)
        let nodeRect = CGRect(x: nx - nodeRadius, y: ny - nodeRadius, width: nodeRadius * 2, height: nodeRadius * 2)

        ctx.setFillColor(nodeColors[i])
        ctx.fillEllipse(in: nodeRect)

        ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.3))
        ctx.setLineWidth(s * 0.01)
        ctx.strokeEllipse(in: nodeRect)
    }

    image.unlockFocus()
    return image
}

// Generate iconset
let iconsetPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "BrowserRouter/AppIcon.iconset"

let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let image = generateIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(name)")
        continue
    }
    let path = "\(iconsetPath)/\(name).png"
    try! png.write(to: URL(fileURLWithPath: path))
    print("Generated: \(path)")
}

print("Done. Run: iconutil -c icns \(iconsetPath)")
