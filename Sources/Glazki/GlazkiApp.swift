import SwiftUI

@main
struct GlazkiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Окон у приложения нет — только глазик в строке меню (см. StatusItemController).
        SwiftUI.Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        BreakController.shared.start()
        LoginItem.enableOnFirstLaunch()
        statusItem = StatusItemController(controller: BreakController.shared, settings: Settings.shared)
    }
}
