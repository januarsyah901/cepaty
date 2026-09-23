import AppKit
import SwiftUI

@main
struct CepatyApp: App {
    @StateObject private var model = TrafficViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            TrafficPopover(model: model)
        } label: {
            MenuBarLabel(apps: model.apps)
        }
        .menuBarExtraStyle(.window)
    }
}
