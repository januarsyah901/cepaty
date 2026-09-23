import SwiftUI

struct AppRow: View {
    let app: AppTraffic

    var body: some View {
        HStack(spacing: 10) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("↓ \(ByteFormatter.speed(app.downSpeed))")
                        .foregroundColor(.blue)
                    Text("↑ \(ByteFormatter.speed(app.upSpeed))")
                        .foregroundColor(.purple)
                }
                .font(.caption)
                .monospacedDigit()
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Total")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(ByteFormatter.amount(app.sessionUsage))
                    .font(.caption)
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
    }
}
