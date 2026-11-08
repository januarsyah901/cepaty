import SwiftUI

/// The live widget shown in the status item (rendered to an image once per second): two mini level bars + two rate lines.
struct MeterView: View {
    let down: Double
    let up: Double

    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 2) {
                MiniBar(level: ByteFormatter.level(up), tint: Theme.upload)
                MiniBar(level: ByteFormatter.level(down), tint: Theme.download)
            }
            VStack(alignment: .trailing, spacing: 0) {
                rate("arrow.up", up)
                rate("arrow.down", down)
            }
        }
        .padding(.horizontal, 4)
        .frame(width: Theme.statusWidth, height: 22)
    }

    private func rate(_ symbol: String, _ value: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: symbol).font(.system(size: 7, weight: .bold))
            Text(ByteFormatter.speed(value))
                .font(.system(size: 9, weight: .medium).monospacedDigit())
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct MiniBar: View {
    let level: Double
    let tint: Color

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 1.5).fill(Color.primary.opacity(0.18))
            RoundedRectangle(cornerRadius: 1.5).fill(tint)
                .frame(height: max(2, 16 * level))
        }
        .frame(width: 4, height: 16)
    }
}
