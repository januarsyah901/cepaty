import AppKit
import Combine
import SwiftUI

/// NSStatusItem (live SwiftUI meter) + native NSMenu (SwiftUI only for graph and list).
/// Native menu = real highlight, keyboard navigation, correct dark/light behaviour.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let model: TrafficViewModel
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var sortItems: [NSMenuItem] = []
    private var loginItem: NSMenuItem?
    private var cancellable: AnyCancellable?
    private var lastRendered = ""

    init(model: TrafficViewModel) {
        self.model = model
        // Fixed width: no jitter of neighbouring menu bar items when digits change.
        self.statusItem = NSStatusBar.system.statusItem(withLength: Theme.statusWidth)
        super.init()

        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.setAccessibilityLabel("Lalu lintas jaringan")
        renderMeter()
        // The history grows once per second, right after down/up are updated.
        cancellable = model.$history.sink { [weak self] _ in self?.renderMeter() }

        menu.delegate = self
        menu.autoenablesItems = false
        buildMenu()
        statusItem.menu = menu
    }

    // MARK: Meter

    /// Rendering the widget to a plain image is far cheaper than hosting a live SwiftUI
    /// view inside the status button: macOS re-lays-out hosted views on every change.
    private func renderMeter() {
        guard let button = statusItem.button else { return }
        let isDark = button.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let key = "\(ByteFormatter.speed(model.down))|\(ByteFormatter.speed(model.up))|\(Int(ByteFormatter.level(model.down) * 20))|\(Int(ByteFormatter.level(model.up) * 20))|\(isDark)"
        guard key != lastRendered else { return }   // nothing visible changed
        lastRendered = key

        let renderer = ImageRenderer(content:
            MeterView(down: model.down, up: model.up)
                .environment(\.colorScheme, isDark ? .dark : .light))
        renderer.scale = button.window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        if let image = renderer.nsImage {
            image.isTemplate = false
            button.image = image
        }
    }

    // MARK: Menu

    private func hostedItem<V: View>(_ view: V, height: CGFloat) -> NSMenuItem {
        let host = NSHostingView(rootView: view)
        host.sizingOptions = []
        host.frame = NSRect(x: 0, y: 0, width: Theme.menuWidth, height: height)
        let item = NSMenuItem()
        item.view = host
        return item
    }

    private func buildMenu() {
        menu.addItem(hostedItem(MenuHeaderView(model: model), height: MenuHeaderView.height))
        menu.addItem(.separator())
        menu.addItem(hostedItem(AppListView(model: model), height: AppListView.height))
        menu.addItem(.separator())

        let sortRoot = NSMenuItem(title: "Urutkan", action: nil, keyEquivalent: "")
        let sortMenu = NSMenu()
        for mode in SortMode.allCases {
            let item = NSMenuItem(title: mode.rawValue, action: #selector(setSort(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            sortMenu.addItem(item)
            sortItems.append(item)
        }
        sortRoot.submenu = sortMenu
        menu.addItem(sortRoot)

        let monitor = NSMenuItem(title: "Buka Monitor Aktivitas…", action: #selector(openActivityMonitor), keyEquivalent: "")
        monitor.target = self
        menu.addItem(monitor)

        let login = NSMenuItem(title: "Buka saat login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        menu.addItem(login)
        loginItem = login

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Keluar dari Cepaty", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    // MARK: NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        for item in sortItems {
            item.state = (item.representedObject as? String == model.sortMode.rawValue) ? .on : .off
        }
        loginItem?.state = model.launchAtLogin ? .on : .off
        model.setMenuOpen(true)
    }

    func menuDidClose(_ menu: NSMenu) {
        model.setMenuOpen(false)
    }

    // MARK: Actions

    @objc private func setSort(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let mode = SortMode(rawValue: raw) {
            model.sortMode = mode
        }
    }

    @objc private func toggleLogin() { model.launchAtLogin.toggle() }

    @objc private func openActivityMonitor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
