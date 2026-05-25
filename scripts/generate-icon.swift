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

    // SVG viewBox 1024x1024 -> s. CG Y is bottom-up, SVG top-down.
    let scale = s / 1024.0
    func sx(_ v: CGFloat) -> CGFloat { v * scale }
    func sy(_ v: CGFloat) -> CGFloat { s - v * scale }
    func sw(_ v: CGFloat) -> CGFloat { v * scale }
    func sh(_ v: CGFloat) -> CGFloat { v * scale }

    // === Background: rounded superellipse with rose gradient ===
    let inset = s * 0.04
    let bgRect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    let bgColors = [
        CGColor(srgbRed: 0.984, green: 0.443, blue: 0.522, alpha: 1.0),
        CGColor(srgbRed: 0.882, green: 0.114, blue: 0.282, alpha: 1.0),
        CGColor(srgbRed: 0.533, green: 0.075, blue: 0.216, alpha: 1.0),
    ]
    let bgGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: bgColors as CFArray,
        locations: [0.0, 0.55, 1.0]
    )!

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(
        bgGradient,
        start: CGPoint(x: s * 0.2, y: s * 0.85),
        end: CGPoint(x: s * 0.8, y: s * 0.15),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    ctx.restoreGState()

    // === URL Bar (white rounded rect at top) ===
    let barRect = CGRect(x: sx(120), y: sy(210 + 170), width: sw(784), height: sh(170))
    let barPath = CGPath(roundedRect: barRect, cornerWidth: sh(85), cornerHeight: sh(85), transform: nil)
    ctx.setFillColor(.white)
    ctx.addPath(barPath)
    ctx.fillPath()

    // Red dot in URL bar
    let dotR = sw(29.75)
    ctx.setFillColor(CGColor(srgbRed: 0.882, green: 0.114, blue: 0.282, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(x: sx(205) - dotR, y: sy(295) - dotR, width: dotR * 2, height: dotR * 2))

    // Pink bars in URL bar
    ctx.setFillColor(CGColor(srgbRed: 0.992, green: 0.643, blue: 0.686, alpha: 1.0))
    let b1 = CGRect(x: sx(264.5), y: sy(264.4 + 23.8), width: sw(125.44), height: sh(23.8))
    ctx.addPath(CGPath(roundedRect: b1, cornerWidth: sh(11.9), cornerHeight: sh(11.9), transform: nil))
    ctx.fillPath()

    ctx.setFillColor(CGColor(srgbRed: 0.996, green: 0.804, blue: 0.827, alpha: 1.0))
    let b2 = CGRect(x: sx(405.62), y: sy(264.4 + 23.8), width: sw(329.28), height: sh(23.8))
    ctx.addPath(CGPath(roundedRect: b2, cornerWidth: sh(11.9), cornerHeight: sh(11.9), transform: nil))
    ctx.fillPath()

    ctx.setFillColor(CGColor(srgbRed: 1.0, green: 0.945, blue: 0.949, alpha: 1.0))
    let b3 = CGRect(x: sx(264.5), y: sy(308.6 + 23.8), width: sw(470.4), height: sh(23.8))
    ctx.addPath(CGPath(roundedRect: b3, cornerWidth: sh(11.9), cornerHeight: sh(11.9), transform: nil))
    ctx.fillPath()

    // === Branching white curves ===
    ctx.setStrokeColor(.white)
    ctx.setLineWidth(sw(22))
    ctx.setLineCap(.round)

    // Left curve
    ctx.move(to: CGPoint(x: sx(512), y: sy(380)))
    ctx.addCurve(to: CGPoint(x: sx(260), y: sy(660)),
                 control1: CGPoint(x: sx(512), y: sy(540)),
                 control2: CGPoint(x: sx(280), y: sy(560)))
    ctx.strokePath()

    // Center line
    ctx.move(to: CGPoint(x: sx(512), y: sy(380)))
    ctx.addLine(to: CGPoint(x: sx(512), y: sy(660)))
    ctx.strokePath()

    // Right curve
    ctx.move(to: CGPoint(x: sx(512), y: sy(380)))
    ctx.addCurve(to: CGPoint(x: sx(764), y: sy(660)),
                 control1: CGPoint(x: sx(512), y: sy(540)),
                 control2: CGPoint(x: sx(744), y: sy(560)))
    ctx.strokePath()

    // === Browser cards (3 at bottom) ===
    let cardXs: [CGFloat] = [156, 412, 668]
    let cardW: CGFloat = 208
    let cardTopSvg: CGFloat = 660
    let cardBotSvg: CGFloat = 880
    let cr: CGFloat = 20

    for cardX in cardXs {
        let path = CGMutablePath()
        // Bottom-left
        path.move(to: CGPoint(x: sx(cardX), y: sy(cardBotSvg)))
        // Left edge up to curve start
        path.addLine(to: CGPoint(x: sx(cardX), y: sy(cardTopSvg + cr)))
        // Top-left corner
        path.addQuadCurve(to: CGPoint(x: sx(cardX + cr), y: sy(cardTopSvg)),
                          control: CGPoint(x: sx(cardX), y: sy(cardTopSvg)))
        // Top edge
        path.addLine(to: CGPoint(x: sx(cardX + cardW - cr), y: sy(cardTopSvg)))
        // Top-right corner
        path.addQuadCurve(to: CGPoint(x: sx(cardX + cardW), y: sy(cardTopSvg + cr)),
                          control: CGPoint(x: sx(cardX + cardW), y: sy(cardTopSvg)))
        // Right edge down
        path.addLine(to: CGPoint(x: sx(cardX + cardW), y: sy(cardBotSvg)))
        path.closeSubpath()

        ctx.setFillColor(.white)
        ctx.addPath(path)
        ctx.fillPath()

        // Red circle in card
        let ccx = cardX + cardW / 2
        let ccr = sw(28.6)
        ctx.setFillColor(CGColor(srgbRed: 0.882, green: 0.114, blue: 0.282, alpha: 1.0))
        ctx.fillEllipse(in: CGRect(x: sx(ccx) - ccr, y: sy(743.6) - ccr, width: ccr * 2, height: ccr * 2))

        // Pink bar in card
        let pbW = sw(104), pbH = sh(19.8)
        let pbRect = CGRect(x: sx(ccx) - pbW / 2, y: sy(796.4 + 19.8), width: pbW, height: pbH)
        ctx.setFillColor(CGColor(srgbRed: 0.882, green: 0.114, blue: 0.282, alpha: 0.4))
        ctx.addPath(CGPath(roundedRect: pbRect, cornerWidth: sh(9.9), cornerHeight: sh(9.9), transform: nil))
        ctx.fillPath()
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
