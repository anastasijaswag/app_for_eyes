import SwiftUI

/// Окошко, которое открывается по клику на глазик в строке меню.
struct PopoverView: View {
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
        .background(Palette.paper)
        .foregroundStyle(Palette.ink)
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
                Menu {
                    Button("На 30 минут") { controller.pause(for: 30 * 60) }
                    Button("На час") { controller.pause(for: 60 * 60) }
                    Button("До завтра") { controller.pauseUntilTomorrow() }
                } label: {
                    Text("Пауза")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Palette.ink.opacity(0.07)))
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
                Picker("", selection: $settings.workMinutes) {
                    ForEach(Settings.workOptions, id: \.self) { Text(Format.workOption($0)).tag($0) }
                }
            }
            row("Отдыхаю") {
                Picker("", selection: $settings.breakSeconds) {
                    ForEach(Settings.breakOptions, id: \.self) { Text(Format.breakOption($0)).tag($0) }
                }
            }
            row("Перерыв") {
                Picker("", selection: $settings.breakStyle) {
                    ForEach(BreakStyle.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Text(settings.breakStyle.hint)
                .font(.system(size: 11))
                .opacity(0.6)
                .fixedSize(horizontal: false, vertical: true)
            row("Звук") {
                Picker("", selection: $settings.sound) {
                    ForEach(SoundChoice.allCases) { Text($0.title).tag($0) }
                }
            }
        }
        .font(.system(size: 13))
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
            Spacer()
            content()
                .labelsHidden()
                .fixedSize()
        }
    }

    private var footer: some View {
        HStack {
            Toggle("Запускать вместе с Mac", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.system(size: 12))
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
            return "до перерыва · \(Format.workOption(settings.workMinutes)) работы, \(Format.breakOption(settings.breakSeconds)) отдыха"
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
