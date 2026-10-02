import SwiftUI

/// Окошко, которое открывается по клику на глазик в строке меню.
struct PopoverView: View {
    /// Прозрачные поля вокруг окошка, чтобы было куда падать тени.
    static let shadowMargin: CGFloat = 24

    @ObservedObject var controller: BreakController
    @ObservedObject var settings: Settings
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatusCard(controller: controller, settings: settings)
            actions
            divider
            settingsRows
            divider
            footer
        }
        .padding(14)
        .frame(width: 300)
        .foregroundStyle(Palette.ink)
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Palette.ink.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        .padding(PopoverView.shadowMargin)
        .onChange(of: settings.sound) { SoundPlayer.shared.play($0, ending: false) }
        .onChange(of: launchAtLogin) { LoginItem.set($0) }
    }

    @ViewBuilder
    private var actions: some View {
        HStack(spacing: 8) {
            switch controller.phase {
            case .working:
                Button("Перерыв сейчас") { controller.breakNow() }
                    .buttonStyle(SoftButtonStyle())
                Button {
                    PopupMenu.show([
                        ("На 30 минут", { controller.pause(for: 30 * 60) }),
                        ("На час", { controller.pause(for: 60 * 60) }),
                        ("До завтра", { controller.pauseUntilTomorrow() }),
                    ])
                } label: {
                    HStack(spacing: 4) {
                        Text("Пауза")
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                }
                .buttonStyle(SoftButtonStyle())
            case .onBreak:
                Button("Пропустить перерыв") { controller.skipBreak() }
                    .buttonStyle(SoftButtonStyle())
            case .paused:
                Button("Продолжить") { controller.resume() }
                    .buttonStyle(SoftButtonStyle())
            }
            Spacer()
        }
    }

    private var settingsRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("Работаю") {
                CycleControl(options: Settings.workOptions, selection: $settings.workMinutes, title: Format.workOption)
            }
            row("Отдыхаю") {
                CycleControl(options: Settings.breakOptions, selection: $settings.breakSeconds, title: Format.breakOption)
            }
            row("Перерыв") {
                ChipPicker(options: BreakStyle.allCases, selection: $settings.breakStyle, title: \.title)
            }
            Text(settings.breakStyle.hint)
                .font(.system(size: 11))
                .opacity(0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
            row("Звук") {
                CycleControl(options: SoundChoice.allCases, selection: $settings.sound, title: \.title)
            }
        }
        .font(.system(size: 13))
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
            Spacer()
            content()
        }
    }

    private var footer: some View {
        HStack {
            SoftToggle(title: "Запускать вместе с Mac", isOn: $launchAtLogin)
            Spacer()
            Button("Выйти") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .opacity(0.6)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.ink.opacity(0.1))
            .frame(height: 1)
    }
}

private struct StatusCard: View {
    @ObservedObject var controller: BreakController
    @ObservedObject var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("глазки")
                .font(Fonts.typewriter(13))
                .opacity(0.6)
            Text(title)
                .font(Fonts.typewriter(40))
                .monospacedDigit()
            Text(subtitle)
                .font(.system(size: 12))
                .opacity(0.7)
            progressLine
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Haze())
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var title: String {
        controller.isPaused ? "пауза" : Format.clock(controller.remaining)
    }

    private var subtitle: String {
        switch controller.phase {
        case .working:
            return "до перерыва"
        case .onBreak:
            return "перерыв — посмотри вдаль 🌿"
        case .paused(let until):
            guard let until else { return "напоминания выключены" }
            if !Calendar.current.isDate(until, inSameDayAs: controller.now) { return "до завтра — хорошего вечера ☾" }
            return "до \(Format.time(until))"
        }
    }

    private var progressLine: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.ink.opacity(0.1))
                Capsule()
                    .fill(Palette.rose)
                    .frame(width: max(4, geo.size.width * (controller.isPaused ? 0 : controller.progress)))
                    .animation(.linear(duration: 1), value: controller.progress)
            }
        }
        .frame(height: 4)
    }
}
