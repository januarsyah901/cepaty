import SwiftUI

/// Smooth, continuously scrolling throughput graph (download + upload).
/// TimelineView redraws every frame and positions samples by wall-clock time,
/// so the graph glides between 1 Hz samples instead of jumping.
struct SparklineView: View {
    let samples: [NetworkSample]
    /// Redraw every frame only while the menu is visible; a hidden 30 fps timeline burns CPU.
    let isLive: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isLive)) { timeline in
            Canvas { ctx, size in
                draw(ctx, size, now: timeline.date)
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, now: Date) {
        let window = TrafficViewModel.window
        let start = now.addingTimeInterval(-window)
        let visible = samples.filter { $0.time >= start.addingTimeInterval(-5) }
        guard visible.count > 1 else { return }

        let peak = max(50_000.0, visible.map { max($0.down, $0.up) }.max() ?? 0) * 1.15

        func points(_ value: (NetworkSample) -> Double) -> [CGPoint] {
            visible.map { s in
                let x = CGFloat(s.time.timeIntervalSince(start) / window) * size.width
                let y = size.height - CGFloat(value(s) / peak) * size.height
                return CGPoint(x: x, y: y)
            }
        }

        // faint baseline
        var base = Path()
        base.move(to: CGPoint(x: 0, y: size.height - 0.5))
        base.addLine(to: CGPoint(x: size.width, y: size.height - 0.5))
        ctx.stroke(base, with: .color(.primary.opacity(0.15)), lineWidth: 0.5)

        layer(ctx, size, points(\.up), Theme.upload)
        layer(ctx, size, points(\.down), Theme.download)
    }

    private func layer(_ ctx: GraphicsContext, _ size: CGSize, _ pts: [CGPoint], _ color: Color) {
        guard let first = pts.first, let last = pts.last else { return }

        var line = Path()
        line.move(to: first)
        for i in 1..<pts.count {
            let mid = CGPoint(x: (pts[i - 1].x + pts[i].x) / 2, y: (pts[i - 1].y + pts[i].y) / 2)
            line.addQuadCurve(to: mid, control: pts[i - 1])
        }
        line.addLine(to: last)

        var area = line
        area.addLine(to: CGPoint(x: last.x, y: size.height))
        area.addLine(to: CGPoint(x: first.x, y: size.height))
        area.closeSubpath()

        ctx.fill(area, with: .linearGradient(
            Gradient(colors: [color.opacity(0.45), color.opacity(0.02)]),
            startPoint: .zero,
            endPoint: CGPoint(x: 0, y: size.height)))
        ctx.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
    }
}
