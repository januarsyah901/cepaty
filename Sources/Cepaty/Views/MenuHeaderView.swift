import SwiftUI

/// Top of the dropdown: current rates + sparkline + time axis.
struct MenuHeaderView: View {
    static let height: CGFloat = 118
    @ObservedObject var model: TrafficViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                badge("arrow.down", model.down, Theme.download)
                Spacer()
                badge("arrow.up", model.up, Theme.upload)
            }
            SparklineView(samples: model.history, isLive: model.menuOpen)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            HStack {
                Text("5 menit lalu")
                Spacer()
                Text("sekarang")
            }
            .font(.system(size: 9))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: Theme.menuWidth, height: Self.height, alignment: .topLeading)
    }

    private func badge(_ symbol: String, _ value: Double, _ tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 10, weight: .bold)).foregroundStyle(tint)
            Text(ByteFormatter.speed(value))
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: value)
        }
    }
}
