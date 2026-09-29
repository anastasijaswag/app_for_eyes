import AppKit
import Combine
import SwiftUI

/// Прозрачное окно-«поповер», которое умеет принимать клавиатуру, не активируя приложение.
private final class PopoverPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Глазик в строке меню и наше собственное окошко под ним — со скруглением, какое хотим.
@MainActor
final class StatusItemController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let panel: PopoverPanel
    private var clickMonitor: Any?
    private var keyMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    init(controller: BreakController, settings: Settings) {
        panel = PopoverPanel(contentRect: .zero,
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered,
                             defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: PopoverView(controller: controller, settings: settings))

        if let button = statusItem.button {
            button.image = MenuBarIcon.open
            button.target = self
            button.action = #selector(togglePanel)
        }

        controller.$phase
            .map { phase -> Bool in
                if case .paused = phase { return true }
                return false
            }
            .removeDuplicates()
            .sink { [weak self] paused in
                self?.statusItem.button?.image = paused ? MenuBarIcon.closed : MenuBarIcon.open
            }
            .store(in: &cancellables)
    }

    @objc private func togglePanel() {
        panel.isVisible ? close() : open()
    }

    private func open() {
        guard let button = statusItem.button, let buttonWindow = button.window,
              let content = panel.contentView else { return }

        let size = content.fittingSize
        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let margin = PopoverView.shadowMargin
        var origin = NSPoint(x: buttonFrame.midX - size.width / 2,
                             y: buttonFrame.minY - size.height + margin - 6)
        if let visible = (buttonWindow.screen ?? NSScreen.main)?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX - margin + 8), visible.maxX - size.width + margin - 8)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
        button.highlight(true)

        // Клик в любом другом месте или Esc — закрываем, как обычное меню.
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.close() }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Esc
                Task { @MainActor in self?.close() }
                return nil
            }
            return event
        }
    }

    private func close() {
        guard panel.isVisible else { return }
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        clickMonitor = nil
        keyMonitor = nil
        statusItem.button?.highlight(false)
        panel.orderOut(nil)
    }
}
