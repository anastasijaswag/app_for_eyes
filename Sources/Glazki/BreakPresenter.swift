import AppKit
import SwiftUI

/// Панель, на которой работают кнопки, но которая не забирает фокус у текущего приложения.
private final class BreakPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Показывает и прячет окна перерыва.
@MainActor
final class BreakPresenter {
    private var panels: [NSPanel] = []

    func show(style: BreakStyle, controller: BreakController) {
        hide(animated: false)
        let phrase = Phrases.random()

        switch style {
        case .dim:
            for screen in NSScreen.screens {
                let panel = makePanel(frame: screen.frame, level: .screenSaver)
                panel.appearance = NSAppearance(named: .darkAqua) // сумеречная палитра — темнее и спокойнее
                panel.contentView = NSHostingView(rootView: FullBreakView(controller: controller, phrase: phrase))
                panels.append(panel)
            }
        case .corner:
            guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
            let host = NSHostingView(rootView: CornerBreakView(controller: controller, phrase: phrase))
            let size = host.fittingSize
            let visible = screen.visibleFrame
            let frame = NSRect(x: visible.maxX - size.width,
                               y: visible.maxY - size.height,
                               width: size.width,
                               height: size.height)
            let panel = makePanel(frame: frame, level: .statusBar)
            panel.contentView = host
            panels.append(panel)
        }

        for panel in panels {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }
        let shown = panels
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.9
            for panel in shown { panel.animator().alphaValue = 1 }
        }
    }

    func hide(animated: Bool = true) {
        let old = panels
        panels = []
        guard !old.isEmpty else { return }
        guard animated else {
            old.forEach { $0.orderOut(nil) }
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.7
            for panel in old { panel.animator().alphaValue = 0 }
        }, completionHandler: {
            old.forEach { $0.orderOut(nil) }
        })
    }

    private func makePanel(frame: NSRect, level: NSWindow.Level) -> NSPanel {
        let panel = BreakPanel(contentRect: frame,
                               styleMask: [.borderless, .nonactivatingPanel],
                               backing: .buffered,
                               defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = level
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.setFrame(frame, display: false)
        return panel
    }
}
