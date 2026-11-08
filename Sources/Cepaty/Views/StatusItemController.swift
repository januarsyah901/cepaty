import AppKit
import SwiftUI

/// Hosting view that lets clicks fall through to the NSStatusBarButton underneath,
/// otherwise the menu would never open when clicking on the widget.
final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

/// NSStatusItem (live SwiftUI meter) + native NSMenu (SwiftUI only for graph and list).
/// Native menu = real highlight, keyboard navigation, correct dark/light behaviour.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let model: TrafficViewModel
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var sortItems: [NSMenuItem] = []
    private var loginItem: NSMenuItem?

    init(model: TrafficViewModel) {
        self.model = model
        // Fixed width: no jitter of neighbouring menu bar items when digits change.
        self.statusItem = NSStatusBar.system.statusItem(withLength: Theme.statusWidth)
        super.init()

        if let button = statusItem.button {
            let host = PassthroughHostingView(rootView: MeterView(model: model))
            host.frame = button.bounds
            host.autoresizingMask = [.width, .height]
            button.addSubview(host)
            button.setAccessibilityLabel("Lalu lintas jaringan")
        }

        menu.delegate = self
        menu.autoenablesItems = false
        buildMenu()
        statusItem.menu = menu
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
