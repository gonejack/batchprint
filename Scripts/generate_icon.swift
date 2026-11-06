import AppKit

let outputPath = CommandLine.arguments.dropFirst().first ?? "AppIcon-1024.png"
let pixelSize = 1024
let canvas = NSSize(width: pixelSize, height: pixelSize)

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixelSize,
    pixelsHigh: pixelSize,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Unable to create bitmap")
}
bitmap.size = canvas

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to create graphics context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let context = graphicsContext.cgContext
context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)

// MARK: - Small drawing helpers

func fill(_ path: NSBezierPath, _ color: NSColor) {
    color.setFill()
    path.fill()
}

func stroke(_ path: NSBezierPath, _ color: NSColor, width: CGFloat) {
    path.lineWidth = width
    color.setStroke()
    path.stroke()
}

func gradientFill(_ path: NSBezierPath, _ colors: [NSColor], angle: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    NSGradient(colors: colors)!.draw(in: path.bounds, angle: angle)
    NSGraphicsContext.restoreGraphicsState()
}

func withShadow(
    color: NSColor,
    blur: CGFloat,
    offset: NSSize,
    draw: () -> Void
) {
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = color
    shadow.shadowBlurRadius = blur
    shadow.shadowOffset = offset
    shadow.set()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

// MARK: - Palette

let bgTop = NSColor(srgbRed: 0.958, green: 0.963, blue: 0.972, alpha: 1)
let bgBottom = NSColor(srgbRed: 0.874, green: 0.883, blue: 0.900, alpha: 1)
let bodyTop = NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1)
let bodyBottom = NSColor(srgbRed: 0.82, green: 0.85, blue: 0.91, alpha: 1)
let bodyEdge = NSColor(srgbRed: 0.43, green: 0.49, blue: 0.59, alpha: 0.55)
let coralTop = NSColor(srgbRed: 1.00, green: 0.62, blue: 0.45, alpha: 1)
let coralBottom = NSColor(srgbRed: 0.93, green: 0.29, blue: 0.35, alpha: 1)
let navyTop = NSColor(srgbRed: 0.17, green: 0.21, blue: 0.32, alpha: 1)
let navyBottom = NSColor(srgbRed: 0.05, green: 0.07, blue: 0.12, alpha: 1)
let ink = NSColor(srgbRed: 0.02, green: 0.03, blue: 0.06, alpha: 1)
let cyan = NSColor(srgbRed: 0.22, green: 0.80, blue: 0.98, alpha: 1)
let magenta = NSColor(srgbRed: 1.00, green: 0.34, blue: 0.63, alpha: 1)
let yellow = NSColor(srgbRed: 1.00, green: 0.82, blue: 0.24, alpha: 1)
let teal = NSColor(srgbRed: 0.10, green: 0.82, blue: 0.76, alpha: 1)
let mint = NSColor(srgbRed: 0.33, green: 0.96, blue: 0.65, alpha: 1)

// MARK: - Rounded tile, Safari-like proportions

let tileRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: 185, yRadius: 185)

// Soft drop shadow below the tile.
withShadow(
    color: NSColor.black.withAlphaComponent(0.20),
    blur: 38,
    offset: NSSize(width: 0, height: -14)
) {
    fill(tilePath, .white)
}

gradientFill(tilePath, [bgTop, bgBottom], angle: -62)

NSGraphicsContext.saveGraphicsState()
tilePath.addClip()

// Very light shading at the bottom of the tile.
let tileShade = NSGradient(colors: [
    NSColor.black.withAlphaComponent(0.030),
    NSColor.clear
])!
tileShade.draw(in: NSRect(x: 100, y: 100, width: 824, height: 300), angle: 90)

// Frosted-glass sheen in the upper-left corner.
let glassGlow = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.38),
    NSColor.white.withAlphaComponent(0.0)
])!
glassGlow.draw(
    fromCenter: NSPoint(x: 300, y: 850),
    radius: 0,
    toCenter: NSPoint(x: 300, y: 850),
    radius: 660,
    options: []
)

NSGraphicsContext.restoreGraphicsState()

// Thin dark edge keeps the tile visible on light backgrounds; the inner white
// rim gives the gray surface a glass-like translucent edge.
stroke(tilePath, NSColor.black.withAlphaComponent(0.08), width: 2)
let rimPath = NSBezierPath(
    roundedRect: tileRect.insetBy(dx: 2.5, dy: 2.5),
    xRadius: 182.5,
    yRadius: 182.5
)
stroke(rimPath, NSColor.white.withAlphaComponent(0.45), width: 2)

// MARK: - Printer illustration

func drawPrinter() {
    // MARK: Paper stack feeding into the top

    NSGraphicsContext.saveGraphicsState()
    let stackTransform = NSAffineTransform()
    stackTransform.translateX(by: 510, yBy: 775)
    stackTransform.rotate(byDegrees: -4)
    stackTransform.translateX(by: -510, yBy: -775)
    stackTransform.concat()

    let sheetYs: [CGFloat] = [688, 698, 708]
    let sheetColors: [NSColor] = [
        NSColor(srgbRed: 0.85, green: 0.89, blue: 0.95, alpha: 1),
        NSColor(srgbRed: 0.93, green: 0.95, blue: 0.98, alpha: 1),
        .white
    ]

    for index in 0..<3 {
        let sheetRect = NSRect(x: 330, y: sheetYs[index], width: 360, height: 86)
        let sheet = NSBezierPath(roundedRect: sheetRect, xRadius: 16, yRadius: 16)
        withShadow(
            color: NSColor.black.withAlphaComponent(0.12),
            blur: 12,
            offset: NSSize(width: 0, height: -5)
        ) {
            fill(sheet, sheetColors[index])
        }
        stroke(sheet, NSColor(srgbRed: 0.55, green: 0.61, blue: 0.70, alpha: 0.35), width: 1.4)
    }

    // A small colorful print on the top sheet.
    let topPrint = NSBezierPath(
        roundedRect: NSRect(x: 352, y: 724, width: 316, height: 54),
        xRadius: 10,
        yRadius: 10
    )
    gradientFill(topPrint, [cyan, magenta, yellow], angle: -12)

    NSGraphicsContext.saveGraphicsState()
    topPrint.addClip()
    let sun = NSBezierPath(ovalIn: NSRect(x: 596, y: 742, width: 34, height: 34))
    fill(sun, NSColor.white.withAlphaComponent(0.85))
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()

    // MARK: Feet

    for x in [CGFloat(294), CGFloat(664)] {
        let foot = NSBezierPath(
            roundedRect: NSRect(x: x, y: 372, width: 66, height: 28),
            xRadius: 12,
            yRadius: 12
        )
        fill(foot, NSColor(srgbRed: 0.10, green: 0.13, blue: 0.20, alpha: 1))
    }

    // MARK: Main body

    let bodyRect = NSRect(x: 230, y: 390, width: 564, height: 270)
    let body = NSBezierPath(roundedRect: bodyRect, xRadius: 58, yRadius: 58)

    withShadow(
        color: NSColor.black.withAlphaComponent(0.24),
        blur: 32,
        offset: NSSize(width: 0, height: -16)
    ) {
        fill(body, .white)
    }

    NSGraphicsContext.saveGraphicsState()
    body.addClip()

    gradientFill(body, [bodyTop, bodyBottom], angle: -90)

    // Cool shading along the lower edge.
    let bodyShade = NSGradient(colors: [
        NSColor(srgbRed: 0.35, green: 0.42, blue: 0.55, alpha: 0.16),
        NSColor.clear
    ])!
    bodyShade.draw(in: NSRect(x: 230, y: 390, width: 564, height: 92), angle: 90)

    NSGraphicsContext.restoreGraphicsState()
    stroke(body, bodyEdge, width: 2.2)

    // MARK: Coral scanner lid

    let lidRect = NSRect(x: 246, y: 650, width: 532, height: 62)
    let lid = NSBezierPath(roundedRect: lidRect, xRadius: 28, yRadius: 28)

    withShadow(
        color: NSColor.black.withAlphaComponent(0.18),
        blur: 16,
        offset: NSSize(width: 0, height: -7)
    ) {
        fill(lid, .white)
    }

    NSGraphicsContext.saveGraphicsState()
    lid.addClip()

    gradientFill(lid, [coralTop, coralBottom], angle: -90)

    let lidGloss = NSBezierPath(
        roundedRect: NSRect(x: 262, y: 694, width: 500, height: 12),
        xRadius: 6,
        yRadius: 6
    )
    gradientFill(lidGloss, [
        NSColor.white.withAlphaComponent(0.70),
        NSColor.white.withAlphaComponent(0.02)
    ], angle: -90)

    // Dark scanner glass with a cyan reflection.
    let glass = NSBezierPath(
        roundedRect: NSRect(x: 300, y: 670, width: 390, height: 18),
        xRadius: 9,
        yRadius: 9
    )
    gradientFill(glass, [
        NSColor(srgbRed: 0.10, green: 0.25, blue: 0.35, alpha: 1),
        NSColor(srgbRed: 0.02, green: 0.06, blue: 0.10, alpha: 1)
    ], angle: -90)

    let glassLine = NSBezierPath(
        roundedRect: NSRect(x: 312, y: 683, width: 366, height: 3),
        xRadius: 1.5,
        yRadius: 1.5
    )
    fill(glassLine, cyan.withAlphaComponent(0.85))

    NSGraphicsContext.restoreGraphicsState()
    stroke(lid, NSColor(srgbRed: 0.62, green: 0.16, blue: 0.22, alpha: 0.55), width: 2)

    // MARK: Compact control strip

    let stripRect = NSRect(x: 280, y: 552, width: 480, height: 64)
    let strip = NSBezierPath(roundedRect: stripRect, xRadius: 22, yRadius: 22)

    withShadow(
        color: NSColor.black.withAlphaComponent(0.18),
        blur: 12,
        offset: NSSize(width: 0, height: -5)
    ) {
        fill(strip, ink)
    }

    NSGraphicsContext.saveGraphicsState()
    strip.addClip()

    gradientFill(strip, [navyTop, navyBottom], angle: -90)

    let stripLine = NSBezierPath(
        roundedRect: NSRect(x: 296, y: 605, width: 448, height: 3),
        xRadius: 1.5,
        yRadius: 1.5
    )
    gradientFill(stripLine, [cyan, teal], angle: 0)

    NSGraphicsContext.restoreGraphicsState()
    stroke(strip, NSColor.black.withAlphaComponent(0.50), width: 1.8)

    // Subtle vents on the white body, below the control strip.
    for index in 0..<3 {
        let vent = NSBezierPath(
            roundedRect: NSRect(x: 300, y: 500 + CGFloat(index) * 11, width: 74, height: 3),
            xRadius: 1.5,
            yRadius: 1.5
        )
        fill(vent, NSColor(srgbRed: 0.53, green: 0.59, blue: 0.68, alpha: 0.34))
    }

    // MARK: Output paper with a colorful print

    let paper = NSBezierPath()
    paper.move(to: NSPoint(x: 332, y: 455))
    paper.line(to: NSPoint(x: 692, y: 455))
    paper.curve(
        to: NSPoint(x: 700, y: 430),
        controlPoint1: NSPoint(x: 699, y: 450),
        controlPoint2: NSPoint(x: 700, y: 440)
    )
    paper.line(to: NSPoint(x: 696, y: 300))
    paper.curve(
        to: NSPoint(x: 680, y: 275),
        controlPoint1: NSPoint(x: 695, y: 285),
        controlPoint2: NSPoint(x: 690, y: 278)
    )
    paper.curve(
        to: NSPoint(x: 512, y: 262),
        controlPoint1: NSPoint(x: 640, y: 260),
        controlPoint2: NSPoint(x: 560, y: 250)
    )
    paper.curve(
        to: NSPoint(x: 344, y: 275),
        controlPoint1: NSPoint(x: 460, y: 252),
        controlPoint2: NSPoint(x: 380, y: 262)
    )
    paper.curve(
        to: NSPoint(x: 328, y: 300),
        controlPoint1: NSPoint(x: 334, y: 280),
        controlPoint2: NSPoint(x: 329, y: 290)
    )
    paper.line(to: NSPoint(x: 328, y: 430))
    paper.curve(
        to: NSPoint(x: 332, y: 455),
        controlPoint1: NSPoint(x: 328, y: 442),
        controlPoint2: NSPoint(x: 329, y: 452)
    )
    paper.close()

    withShadow(
        color: NSColor.black.withAlphaComponent(0.24),
        blur: 24,
        offset: NSSize(width: 0, height: -12)
    ) {
        fill(paper, .white)
    }
    stroke(paper, NSColor(srgbRed: 0.52, green: 0.58, blue: 0.68, alpha: 0.40), width: 1.6)

    let artwork = NSBezierPath(
        roundedRect: NSRect(x: 348, y: 286, width: 328, height: 140),
        xRadius: 14,
        yRadius: 14
    )

    NSGraphicsContext.saveGraphicsState()
    artwork.addClip()

    gradientFill(artwork, [
        NSColor(srgbRed: 1.00, green: 0.82, blue: 0.38, alpha: 1),
        NSColor(srgbRed: 1.00, green: 0.49, blue: 0.55, alpha: 1),
        NSColor(srgbRed: 0.48, green: 0.35, blue: 0.96, alpha: 1)
    ], angle: -90)

    // Sun.
    let artSun = NSBezierPath(ovalIn: NSRect(x: 576, y: 366, width: 56, height: 56))
    withShadow(
        color: NSColor.white.withAlphaComponent(0.55),
        blur: 18,
        offset: .zero
    ) {
        fill(artSun, NSColor(srgbRed: 1.00, green: 0.96, blue: 0.78, alpha: 1))
    }

    // Layered waves.
    let waveBack = NSBezierPath()
    waveBack.move(to: NSPoint(x: 348, y: 344))
    waveBack.curve(
        to: NSPoint(x: 676, y: 330),
        controlPoint1: NSPoint(x: 448, y: 370),
        controlPoint2: NSPoint(x: 570, y: 310)
    )
    waveBack.line(to: NSPoint(x: 676, y: 286))
    waveBack.line(to: NSPoint(x: 348, y: 286))
    waveBack.close()
    fill(waveBack, teal.withAlphaComponent(0.95))

    let waveFront = NSBezierPath()
    waveFront.move(to: NSPoint(x: 348, y: 316))
    waveFront.curve(
        to: NSPoint(x: 676, y: 304),
        controlPoint1: NSPoint(x: 448, y: 338),
        controlPoint2: NSPoint(x: 566, y: 282)
    )
    waveFront.line(to: NSPoint(x: 676, y: 286))
    waveFront.line(to: NSPoint(x: 348, y: 286))
    waveFront.close()
    fill(waveFront, NSColor(srgbRed: 0.16, green: 0.28, blue: 0.78, alpha: 0.88))

    NSGraphicsContext.restoreGraphicsState()
    stroke(artwork, NSColor.white.withAlphaComponent(0.55), width: 2)

    // Folded bottom-right corner.
    let fold = NSBezierPath()
    fold.move(to: NSPoint(x: 684, y: 275))
    fold.line(to: NSPoint(x: 700, y: 298))
    fold.line(to: NSPoint(x: 678, y: 298))
    fold.close()
    fill(fold, NSColor(srgbRed: 0.90, green: 0.93, blue: 0.97, alpha: 1))
    stroke(fold, NSColor(srgbRed: 0.62, green: 0.68, blue: 0.77, alpha: 0.55), width: 1.2)

    // MARK: Output slot lip

    let slot = NSBezierPath(
        roundedRect: NSRect(x: 316, y: 430, width: 392, height: 30),
        xRadius: 15,
        yRadius: 15
    )
    gradientFill(slot, [
        NSColor(srgbRed: 0.03, green: 0.04, blue: 0.07, alpha: 1),
        NSColor(srgbRed: 0.09, green: 0.12, blue: 0.18, alpha: 1)
    ], angle: -90)

    let slotHighlight = NSBezierPath(
        roundedRect: NSRect(x: 332, y: 431, width: 360, height: 2),
        xRadius: 1,
        yRadius: 1
    )
    fill(slotHighlight, NSColor.white.withAlphaComponent(0.14))

    // MARK: Control cluster

    let screen = NSBezierPath(
        roundedRect: NSRect(x: 646, y: 560, width: 76, height: 42),
        xRadius: 9,
        yRadius: 9
    )
    fill(screen, NSColor(srgbRed: 0.02, green: 0.04, blue: 0.08, alpha: 1))
    stroke(screen, NSColor(srgbRed: 0.25, green: 0.32, blue: 0.45, alpha: 0.9), width: 1.6)

    NSGraphicsContext.saveGraphicsState()
    screen.addClip()
    let screenBar = NSBezierPath(
        roundedRect: NSRect(x: 656, y: 586, width: 56, height: 8),
        xRadius: 4,
        yRadius: 4
    )
    gradientFill(screenBar, [cyan, magenta, yellow], angle: 0)

    let screenLine1 = NSBezierPath(
        roundedRect: NSRect(x: 656, y: 576, width: 46, height: 3),
        xRadius: 1.5,
        yRadius: 1.5
    )
    fill(screenLine1, NSColor.white.withAlphaComponent(0.42))

    let screenLine2 = NSBezierPath(
        roundedRect: NSRect(x: 656, y: 569, width: 32, height: 3),
        xRadius: 1.5,
        yRadius: 1.5
    )
    fill(screenLine2, NSColor.white.withAlphaComponent(0.24))
    NSGraphicsContext.restoreGraphicsState()

    // Glowing mint power button.
    let buttonRect = NSRect(x: 732, y: 568, width: 28, height: 28)
    let button = NSBezierPath(ovalIn: buttonRect)
    withShadow(
        color: mint.withAlphaComponent(0.75),
        blur: 16,
        offset: .zero
    ) {
        fill(button, mint)
    }
    let buttonCore = NSBezierPath(ovalIn: NSRect(x: 738, y: 574, width: 16, height: 16))
    gradientFill(buttonCore, [
        NSColor.white.withAlphaComponent(0.85),
        mint
    ], angle: -90)

    // CMYK registration dots.
    let dots: [(CGFloat, NSColor)] = [
        (300, cyan),
        (322, magenta),
        (344, yellow),
        (366, NSColor(srgbRed: 0.16, green: 0.18, blue: 0.22, alpha: 1))
    ]
    for (x, color) in dots {
        let dot = NSBezierPath(ovalIn: NSRect(x: x, y: 578, width: 13, height: 13))
        fill(dot, color)
    }
}

// Scale the whole illustration around the tile center, so it fills the
// squircle at a Safari-like ratio.
NSGraphicsContext.saveGraphicsState()
let groupTransform = NSAffineTransform()
groupTransform.translateX(by: 0, yBy: -40)
groupTransform.translateX(by: 512, yBy: 512)
groupTransform.scale(by: 1.10)
groupTransform.translateX(by: -512, yBy: -512)
groupTransform.concat()

drawPrinter()

NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.restoreGraphicsState()

guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon")
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print("Generated \(outputPath) (\(bitmap.pixelsWide)×\(bitmap.pixelsHigh))")
