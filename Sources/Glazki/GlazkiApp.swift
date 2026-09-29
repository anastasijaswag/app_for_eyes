import SwiftUI

@main
struct GlazkiApp: App {
    @StateObject private var controller = BreakController.shared
    @StateObject private var settings = Settings.shared

    init() {
        BreakController.shared.start()
        LoginItem.enableOnFirstLaunch()
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(controller: controller, settings: settings)
        } label: {
            Image(nsImage: controller.isPaused ? MenuBarIcon.closed : MenuBarIcon.open)
        }
        .menuBarExtraStyle(.window)
    }
}
