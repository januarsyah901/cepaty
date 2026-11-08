import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = TrafficViewModel()
    private var controller: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
        controller = StatusItemController(model: model)
        model.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stop()   // makes sure the nettop child process goes away
    }
}

@main
struct CepatyApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
