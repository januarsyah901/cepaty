import SwiftUI

struct MenuBarLabel: View {
    let apps: [AppTraffic]

    var body: some View {
        let down = apps.reduce(0) { $0 + $1.downSpeed }
        let up = apps.reduce(0) { $0 + $1.upSpeed }
        HStack(spacing: 4) {
            Text("↓ \(ByteFormatter.speed(down))")
            Text("↑ \(ByteFormatter.speed(up))")
        }
        .monospacedDigit()
    }
}
