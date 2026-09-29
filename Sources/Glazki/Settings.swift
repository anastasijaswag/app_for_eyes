import Foundation

enum BreakStyle: String, CaseIterable, Identifiable {
    case dim, corner

    var id: Self { self }

    var title: String {
        switch self {
        case .dim: return "Затемнять"
        case .corner: return "В уголке"
        }
    }

    var hint: String {
        switch self {
        case .dim: return "Экран мягко затуманится, по центру — обратный отсчёт"
        case .corner: return "Маленькое окошко в углу — удобно на созвонах"
        }
    }
}

enum SoundChoice: String, CaseIterable, Identifiable {
    case bell, drop, chime, none

    var id: Self { self }

    var title: String {
        switch self {
        case .bell: return "Колокольчик"
        case .drop: return "Капелька"
        case .chime: return "Ветерок"
        case .none: return "Без звука"
        }
    }

    var fileName: String? {
        self == .none ? nil : rawValue
    }
}

@MainActor
final class Settings: ObservableObject {
    static let shared = Settings()

    static let workOptions = [10, 15, 20, 25, 30, 40, 45, 50, 60, 90]
    static let breakOptions = [20, 30, 60, 120, 300, 600]

    @Published var workMinutes: Int {
        didSet { UserDefaults.standard.set(workMinutes, forKey: Keys.work) }
    }
    @Published var breakSeconds: Int {
        didSet { UserDefaults.standard.set(breakSeconds, forKey: Keys.rest) }
    }
    @Published var breakStyle: BreakStyle {
        didSet { UserDefaults.standard.set(breakStyle.rawValue, forKey: Keys.style) }
    }
    @Published var sound: SoundChoice {
        didSet { UserDefaults.standard.set(sound.rawValue, forKey: Keys.sound) }
    }

    private enum Keys {
        static let work = "workMinutes"
        static let rest = "breakSeconds"
        static let style = "breakStyle"
        static let sound = "sound"
    }

    private init() {
        let d = UserDefaults.standard
        d.register(defaults: [
            Keys.work: 20,
            Keys.rest: 20,
            Keys.style: BreakStyle.dim.rawValue,
            Keys.sound: SoundChoice.bell.rawValue,
        ])
        workMinutes = d.integer(forKey: Keys.work)
        breakSeconds = d.integer(forKey: Keys.rest)
        breakStyle = BreakStyle(rawValue: d.string(forKey: Keys.style) ?? "") ?? .dim
        sound = SoundChoice(rawValue: d.string(forKey: Keys.sound) ?? "") ?? .bell
    }
}
