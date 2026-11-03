import AppKit
import CoreGraphics

let size: CGFloat = 1024.0
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Failed to get graphics context")
}

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

// 1. Draw Background macOS Squircle
let squircleRect = CGRect(x: 80, y: 80, width: 864, height: 864)
let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: 200, cornerHeight: 200, transform: nil)

context.saveGState()
context.addPath(squirclePath)
context.clip()

// Background dark gradient (retro CRT dark grey / charcoal)
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bgColors = [
    NSColor(calibratedRed: 0.12, green: 0.13, blue: 0.15, alpha: 1.0).cgColor,
    NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.07, alpha: 1.0).cgColor
] as CFArray
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
    context.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 944), end: CGPoint(x: 512, y: 80), options: [])
}
context.restoreGState()

// Subtle inner border
context.saveGState()
context.addPath(squirclePath)
context.setLineWidth(8.0)
context.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.15).cgColor)
context.strokePath()
context.restoreGState()

// 2. Draw Retro CRT Grid/Scanline in background
context.saveGState()
context.addPath(squirclePath)
context.clip()
context.setStrokeColor(NSColor(calibratedWhite: 1.0, alpha: 0.03).cgColor)
context.setLineWidth(2.0)
for y in stride(from: 80, through: 944, by: 12) {
    context.move(to: CGPoint(x: 80, y: CGFloat(y)))
    context.addLine(to: CGPoint(x: 944, y: CGFloat(y)))
    context.strokePath()
}
context.restoreGState()

// 3. Draw Pixel Monster in Center
// 8x8 pixel grid scaled up
let pixelMatrix: [[Int]] = [
    [0, 1, 0, 0, 0, 0, 1, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 0, 1, 1, 0, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [0, 0, 0, 1, 1, 0, 0, 0]
]

let pixelSize: CGFloat = 64.0
let startX: CGFloat = 512.0 - (4.0 * pixelSize)
let startY: CGFloat = 512.0 - (4.0 * pixelSize)

let monsterColor = NSColor(calibratedRed: 0.18, green: 0.84, blue: 0.45, alpha: 1.0).cgColor // Vibrant retro green
let eyeColor = NSColor(calibratedRed: 0.95, green: 0.20, blue: 0.25, alpha: 1.0).cgColor // Red eyes

for (rIdx, row) in pixelMatrix.enumerated() {
    let y = startY + CGFloat(7 - rIdx) * pixelSize
    for (cIdx, cell) in row.enumerated() {
        let x = startX + CGFloat(cIdx) * pixelSize
        if cell == 1 {
            let rect = CGRect(x: x + 2, y: y + 2, width: pixelSize - 4, height: pixelSize - 4)
            context.setFillColor(monsterColor)
            context.fill(rect)
        } else if rIdx == 3 && (cIdx == 2 || cIdx == 5) {
            // Glowing red eyes
            let rect = CGRect(x: x + 4, y: y + 4, width: pixelSize - 8, height: pixelSize - 8)
            context.setFillColor(eyeColor)
            context.fill(rect)
        }
    }
}

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to convert image to PNG")
}

let outURL = URL(fileURLWithPath: "AppIcon_1024.png")
try pngData.write(to: outURL)
print("Generated AppIcon_1024.png")
