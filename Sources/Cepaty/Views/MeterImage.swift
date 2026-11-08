import AppKit

/// The live widget in the status item: two mini level bars + two rate lines.
///
/// Drawn directly with AppKit instead of a SwiftUI view: building a SwiftUI graph once per
/// second just to produce a 78x22 pt image was a measurable part of the idle CPU. The image
/// uses a drawing handler, so label colors resolve against the menu bar's own appearance
/// (light/dark/tinted) every time it is drawn.
enum MeterImage {
    static let size = NSSize(width: Theme.statusWidth, height: 22)

    private static let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium)
    private static let symbolConfig = NSImage.SymbolConfiguration(pointSize: 7, weight: .bold)
    private static let upSymbol = symbol("arrow.up")
    private static let downSymbol = symbol("arrow.down")

    private static func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(symbolConfig)
    }

    static func make(down: Double, up: Double) -> NSImage {
        let upText = ByteFormatter.speed(up)
        let downText = ByteFormatter.speed(down)
        let upLevel = ByteFormatter.level(up)
        let downLevel = ByteFormatter.level(down)

        let image = NSImage(size: size, flipped: false) { _ in
            // Mini bars: upload first, then download (same order as before).
            drawBar(x: 4, level: upLevel, tint: NSColor(Theme.upload))
            drawBar(x: 10, level: downLevel, tint: NSColor(Theme.download))

            // Two right-aligned lines, vertically centered, upload on top.
            let lineHeight = ceil(font.ascender - font.descender)
            let bottom = (size.height - 2 * lineHeight) / 2
            drawLine(downText, symbol: downSymbol, y: bottom, height: lineHeight)
            drawLine(upText, symbol: upSymbol, y: bottom + lineHeight, height: lineHeight)
            return true
        }
        image.isTemplate = false
        return image
    }

    private static func drawBar(x: CGFloat, level: Double, tint: NSColor) {
        let track = NSRect(x: x, y: 3, width: 4, height: 16)
        NSColor.labelColor.withAlphaComponent(0.18).setFill()
        NSBezierPath(roundedRect: track, xRadius: 1.5, yRadius: 1.5).fill()

        var fill = track
        fill.size.height = max(2, 16 * level)
        tint.setFill()
        NSBezierPath(roundedRect: fill, xRadius: 1.5, yRadius: 1.5).fill()
    }

    private static func drawLine(_ text: String, symbol: NSImage?, y: CGFloat, height: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let right = size.width - 4
        (text as NSString).draw(at: NSPoint(x: right - textSize.width, y: y + (height - textSize.height) / 2),
                                withAttributes: attributes)

        guard let symbol else { return }
        let gap: CGFloat = 2
        let origin = NSPoint(x: right - textSize.width - gap - symbol.size.width,
                             y: y + (height - symbol.size.height) / 2)
        tinted(symbol, color: .labelColor).draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
    }

    private static func tinted(_ image: NSImage, color: NSColor) -> NSImage {
        NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
