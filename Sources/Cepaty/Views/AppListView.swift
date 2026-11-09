import SwiftUI

/// Per-app section of the dropdown. Fixed height so the menu never resizes while open.
struct AppListView: View {
    static let height: CGFloat = 176
    static let maxRows = 5
    @ObservedObject var model: TrafficViewModel

    private var rows: [AppTraffic] {
        let active = model.apps.filter {
            model.sortMode == .current ? $0.currentUsage > 0 : $0.sessionUsage > 0
        }
        return Array(active.prefix(Self.maxRows))
    }

    private func value(_ app: AppTraffic) -> Double {
        model.sortMode == .current ? app.currentUsage : Double(app.sessionUsage)
    }

    var body: some View {
        let rows = rows
        let peak = rows.map(value).max() ?? 1

        VStack(alignment: .leading, spacing: 0) {
            Text(model.sortMode == .current ? "APLIKASI TERBANYAK" : "TOTAL SESI")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

            if rows.isEmpty {
                Text("Mengukur…")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rows) { app in
                    AppBarRow(app: app,
                              fraction: peak > 0 ? value(app) / peak : 0,
                              text: model.sortMode == .current
                                  ? ByteFormatter.speed(app.currentUsage)
                                  : ByteFormatter.amount(app.sessionUsage))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(width: Theme.menuWidth, height: Self.height, alignment: .topLeading)
    }
}

struct AppBarRow: View {
    let app: AppTraffic
    let fraction: Double
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if let icon = app.icon {
                    Image(nsImage: icon).resizable()
                } else {
                    Image(systemName: "app.fill").resizable().foregroundStyle(.secondary)
                }
            }
            .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.10))
                    GeometryReader { g in
                        Capsule()
                            .fill(LinearGradient(colors: [Theme.download, Theme.upload],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(3, g.size.width * fraction))
                    }
                }
                .frame(height: 3)
            }
            Text(text)
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
        }
        .frame(height: 28)
        .animation(.easeOut(duration: 0.3), value: fraction)
    }
}
