import AppKit
import SwiftUI

// Палитра по референсам: пыльная пастель, кремовая бумага, шалфей, лаванда, тёплый огонёк.
enum Palette {
    static let paper = dynamic(light: 0xF6F0E4, dark: 0x2A2533)
    static let ink = dynamic(light: 0x5E4E63, dark: 0xEFE6DA)
    static let pink = dynamic(light: 0xECBDB8, dark: 0x7E5462)
    static let lavender = dynamic(light: 0xD3CAE8, dark: 0x4F4876)
    static let sage = dynamic(light: 0xB9C7A4, dark: 0x485743)
    static let glow = dynamic(light: 0xF6C58E, dark: 0xC08A5A)
    static let rose = dynamic(light: 0xD4908B, dark: 0xE8AAA4)

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? rgb(dark) : rgb(light)
        })
    }

    private static func rgb(_ hex: UInt32) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }
}

enum Fonts {
    /// Печатная машинка — как подписи на референсах.
    static func typewriter(_ size: CGFloat) -> Font {
        .custom("American Typewriter", size: size)
    }
}

/// Зернистость «пастели по бумаге». Картинка рисуется один раз и повторяется плиткой.
enum Grain {
    static let image: NSImage = {
        let size = 128
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        for y in 0..<size {
            for x in 0..<size {
                let v: CGFloat = Bool.random() ? 1 : 0
                rep.setColor(NSColor(deviceRed: v, green: v, blue: v, alpha: .random(in: 0...0.07)), atX: x, y: y)
            }
        }
        let image = NSImage(size: NSSize(width: size, height: size))
        image.addRepresentation(rep)
        return image
    }()
}

struct GrainOverlay: View {
    var body: some View {
        Image(nsImage: Grain.image)
            .resizable(resizingMode: .tile)
            .allowsHitTesting(false)
    }
}

/// Мягкая пастельная «дымка» из размытых пятен — фон карточек и экрана перерыва.
struct Haze: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let m = max(w, h)
            ZStack {
                Palette.paper
                blob(Palette.pink, size: m * 0.6, x: w * 0.15, y: h * 0.25, blur: m * 0.14)
                blob(Palette.lavender, size: m * 0.65, x: w * 0.85, y: h * 0.3, blur: m * 0.15)
                blob(Palette.sage, size: m * 0.7, x: w * 0.5, y: h * 1.0, blur: m * 0.16)
                blob(Palette.glow, size: m * 0.12, x: w * 0.5, y: h * 0.12, blur: m * 0.05)
                    .opacity(0.7)
                GrainOverlay()
            }
        }
        .clipped()
        .allowsHitTesting(false)
    }

    private func blob(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat, blur: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .blur(radius: blur)
    }
}

/// Кружок обратного отсчёта: розовая дуга тает по мере того, как идёт время.
struct CountdownRing: View {
    var progress: Double
    var label: String
    var caption: String?
    var size: CGFloat
    var lineWidth: CGFloat
    var fontSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.ink.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, 1 - progress))
                .stroke(Palette.rose, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            VStack(spacing: 0) {
                Text(label)
                    .font(Fonts.typewriter(fontSize))
                    .monospacedDigit()
                if let caption {
                    Text(caption)
                        .font(Fonts.typewriter(max(11, fontSize * 0.22)))
                        .opacity(0.6)
                }
            }
            .foregroundStyle(Palette.ink)
        }
        .frame(width: size, height: size)
    }
}

/// Тихая текстовая кнопка — «пропустить», «через 5 мин».
struct QuietButton: View {
    let title: String
    var size: CGFloat = 14
    let action: () -> Void

    init(_ title: String, size: CGFloat = 14, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Fonts.typewriter(size))
                .foregroundStyle(Palette.ink.opacity(0.65))
                .underline(true, color: Palette.ink.opacity(0.25))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Мягкая кнопка-«таблетка» для меню.
struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Palette.ink.opacity(configuration.isPressed ? 0.14 : 0.07)))
            .contentShape(Capsule())
    }
}

/// Значок в строке меню: глазик с ресничками (закрытый — когда на паузе).
enum MenuBarIcon {
    static let open = make(closed: false)
    static let closed = make(closed: true)

    private static func make(closed: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            NSColor.black.set()
            // Сдвигаем рисунок так, чтобы глазик стоял ровно по центру строки меню.
            let transform = NSAffineTransform()
            transform.translateX(by: 0, yBy: closed ? 3 : -0.4)
            transform.concat()
            let path = NSBezierPath()
            path.lineWidth = 1.4
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            if closed {
                path.move(to: NSPoint(x: 3, y: 9))
                path.curve(to: NSPoint(x: 17, y: 9),
                           controlPoint1: NSPoint(x: 6.5, y: 4.5),
                           controlPoint2: NSPoint(x: 13.5, y: 4.5))
                lash(path, from: NSPoint(x: 6.2, y: 6.5), to: NSPoint(x: 5.2, y: 4.0))
                lash(path, from: NSPoint(x: 10, y: 5.6), to: NSPoint(x: 10, y: 3.0))
                lash(path, from: NSPoint(x: 13.8, y: 6.5), to: NSPoint(x: 14.8, y: 4.0))
                path.stroke()
            } else {
                path.move(to: NSPoint(x: 2, y: 8))
                path.curve(to: NSPoint(x: 18, y: 8),
                           controlPoint1: NSPoint(x: 6, y: 13.5),
                           controlPoint2: NSPoint(x: 14, y: 13.5))
                path.curve(to: NSPoint(x: 2, y: 8),
                           controlPoint1: NSPoint(x: 14, y: 2.5),
                           controlPoint2: NSPoint(x: 6, y: 2.5))
                path.close()
                lash(path, from: NSPoint(x: 5.6, y: 11.1), to: NSPoint(x: 4.6, y: 13.6))
                lash(path, from: NSPoint(x: 10, y: 12.1), to: NSPoint(x: 10, y: 14.8))
                lash(path, from: NSPoint(x: 14.4, y: 11.1), to: NSPoint(x: 15.4, y: 13.6))
                path.stroke()
                NSBezierPath(ovalIn: NSRect(x: 7.5, y: 5.5, width: 5, height: 5)).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func lash(_ path: NSBezierPath, from: NSPoint, to: NSPoint) {
        path.move(to: from)
        path.line(to: to)
    }
}

enum Format {
    static func workOption(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) мин" }
        if minutes % 60 == 0 { return "\(minutes / 60) ч" }
        return "\(minutes / 60) ч \(minutes % 60) мин"
    }

    static func breakOption(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds) сек" : "\(seconds / 60) мин"
    }

    static func clock(_ interval: TimeInterval) -> String {
        let s = Int(interval.rounded(.up))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    static func plural(_ n: Int, _ one: String, _ few: String, _ many: String) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return one }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return few }
        return many
    }
}

enum Phrases {
    static let all = [
        "Посмотри в окно —\nкакое там сейчас небо?",
        "Найди вдалеке\nчто-нибудь зелёное 🌿",
        "Медленно поморгай,\nкак сонный котик",
        "Взгляд подальше — туда,\nгде деревья и облака",
        "Экран подождёт.\nГлазки отдыхают ☁︎",
    ]

    static func random() -> String {
        all.randomElement() ?? all[0]
    }
}

// MARK: - Свои контролы вместо системных синих

/// «‹ 20 мин ›» — листаешь стрелочками, без выпадающих списков.
struct CycleControl<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    private var index: Int { options.firstIndex(of: selection) ?? 0 }

    var body: some View {
        HStack(spacing: 0) {
            arrow("chevron.left", step: -1)
            Text(title(selection))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 78)
            arrow("chevron.right", step: 1)
        }
        .foregroundStyle(Palette.ink)
        .padding(.vertical, 3)
        .background(Capsule().fill(Palette.ink.opacity(0.07)))
    }

    private func arrow(_ symbol: String, step: Int) -> some View {
        let target = index + step
        let enabled = options.indices.contains(target)
        return Button {
            if enabled { selection = options[target] }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
                .frame(width: 24, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 0.7 : 0.2)
        .disabled(!enabled)
    }
}

/// Два-три варианта «таблетками», выбранный подсвечен розовым.
struct ChipPicker<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = option }
                } label: {
                    Text(title(option))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.ink.opacity(selected ? 1 : 0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(selected ? Palette.rose.opacity(0.35) : .clear))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Capsule().fill(Palette.ink.opacity(0.07)))
    }
}

/// Мягкий переключатель вместо синей галочки.
struct SoftToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? Palette.rose : Palette.ink.opacity(0.15))
                        .frame(width: 26, height: 15)
                    Circle()
                        .fill(Palette.paper)
                        .frame(width: 11, height: 11)
                        .padding(2)
                }
                .animation(.easeOut(duration: 0.15), value: isOn)
                Text(title)
                    .font(.system(size: 12))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Обычное системное выпадающее меню, которое можно открыть из нашей кнопки.
@MainActor
enum PopupMenu {
    private final class Item: NSObject {
        let action: () -> Void
        init(_ action: @escaping () -> Void) { self.action = action }
        @objc func run() { action() }
    }

    /// `view` — кнопка, под которой выпадает меню (как у обычных системных выпадашек).
    static func show(_ items: [(String, () -> Void)], below view: NSView?) {
        let menu = NSMenu()
        for (title, action) in items {
            let handler = Item(action)
            let item = NSMenuItem(title: title, action: #selector(Item.run), keyEquivalent: "")
            item.target = handler
            item.representedObject = handler // target — слабая ссылка, держим обработчик здесь
            menu.addItem(item)
        }
        if let view {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: -4), in: view)
        } else {
            menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
    }
}

/// Запоминает AppKit-вид под SwiftUI-кнопкой, чтобы знать, откуда выпадать меню.
final class MenuAnchor {
    weak var view: NSView?
}

struct MenuAnchorView: NSViewRepresentable {
    let anchor: MenuAnchor

    private final class AnchorView: NSView {
        override var isFlipped: Bool { false } // y = 0 — нижний край кнопки
    }

    func makeNSView(context: Context) -> NSView {
        let view = AnchorView()
        anchor.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        anchor.view = nsView
    }
}
