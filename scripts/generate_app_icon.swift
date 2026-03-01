import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Assets/AppIcon.iconset"

let outputDirectory = URL(fileURLWithPath: outputPath, isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconFiles: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for file in iconFiles {
    let destination = outputDirectory.appendingPathComponent(file.name)
    try writeIconPNG(size: file.size, to: destination)
}

print("Generated \(iconFiles.count) icon PNG files in \(outputDirectory.path)")

func writeIconPNG(size: Int, to url: URL) throws {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw NSError(domain: "IconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot create graphics context"])
    }

    context.interpolationQuality = .high
    let rect = CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))
    drawBackground(context: context, rect: rect)
    drawCountdownMark(context: context, rect: rect)

    guard let image = context.makeImage() else {
        throw NSError(domain: "IconGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot create image from context"])
    }

    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "IconGenerator", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot create PNG destination"])
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "IconGenerator", code: 4, userInfo: [NSLocalizedDescriptionKey: "Cannot finalize PNG"])
    }
}

func drawBackground(context: CGContext, rect: CGRect) {
    let radius = rect.width * 0.22
    let rounded = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.addPath(rounded)
    context.clip()

    let colors: [CGColor] = [
        CGColor(red: 0.07, green: 0.09, blue: 0.22, alpha: 1.0),
        CGColor(red: 0.12, green: 0.24, blue: 0.50, alpha: 1.0),
        CGColor(red: 0.12, green: 0.43, blue: 0.84, alpha: 1.0),
    ]
    let locations: [CGFloat] = [0.0, 0.55, 1.0]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)!
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )

    let highlightRect = CGRect(
        x: rect.minX + rect.width * 0.12,
        y: rect.midY + rect.height * 0.04,
        width: rect.width * 0.76,
        height: rect.height * 0.50
    )
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.12))
    context.fillEllipse(in: highlightRect)
}

func drawCountdownMark(context: CGContext, rect: CGRect) {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = rect.width * 0.27
    let lineWidth = max(1.2, rect.width * 0.085)

    context.setLineWidth(lineWidth)
    context.setLineCap(.round)

    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.24))
    context.strokeEllipse(in: CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    ))

    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    context.addArc(
        center: center,
        radius: radius,
        startAngle: .pi / 2,
        endAngle: -.pi * 1.05,
        clockwise: true
    )
    context.strokePath()

    let knobSize = max(2.8, rect.width * 0.08)
    let knobCenter = CGPoint(x: center.x + radius * 0.95, y: center.y - radius * 0.15)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    context.fillEllipse(in: CGRect(
        x: knobCenter.x - knobSize / 2,
        y: knobCenter.y - knobSize / 2,
        width: knobSize,
        height: knobSize
    ))
}
