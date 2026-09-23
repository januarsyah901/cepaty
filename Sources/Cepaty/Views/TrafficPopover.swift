import SwiftUI

struct TrafficPopover: View {
    @ObservedObject var model: TrafficViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Lalu Lintas Jaringan")
                    .font(.headline)
                Spacer()
                Picker("", selection: $model.sortMode) {
                    ForEach(SortMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            if model.apps.isEmpty {
                VStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Memindai koneksi jaringan...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 320)
            } else {
                List(Array(model.apps.prefix(15))) { app in
                    AppRow(app: app)
                }
                .listStyle(.inset)
                .frame(height: 320)
            }

            Divider()

            HStack {
                Toggle("Buka saat login", isOn: $model.launchAtLogin)
                    .toggleStyle(.checkbox)
                    .font(.subheadline)
                Spacer()
                Button("Keluar") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 350)
        .onAppear { model.setPopoverVisible(true) }
        .onDisappear { model.setPopoverVisible(false) }
    }
}
