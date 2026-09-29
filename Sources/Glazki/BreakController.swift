import AppKit
import Combine

/// Сердце приложения: отсчитывает время работы и перерыва.
@MainActor
final class BreakController: ObservableObject {
    static let shared = BreakController()

    enum Phase: Equatable {
        case working(start: Date, end: Date)
        case onBreak(start: Date, end: Date)
        case paused(until: Date?)
    }

    @Published private(set) var phase: Phase
    @Published private(set) var now = Date()

    let settings = Settings.shared
    private let presenter = BreakPresenter()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    /// Если за компьютером никого нет столько времени — начинаем отсчёт заново.
    private static let awayThreshold: TimeInterval = 5 * 60
    private static let snoozeInterval: TimeInterval = 5 * 60

    private init() {
        let start = Date()
        phase = .working(start: start, end: start.addingTimeInterval(Double(Settings.shared.workMinutes) * 60))
    }

    func start() {
        guard timer == nil else { return }

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        settings.$workMinutes
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] minutes in self?.workDurationChanged(minutes) }
            .store(in: &cancellables)

        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.userWentAway() }
            }
        }
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.userCameBack() }
            }
        }
    }

    // MARK: - Состояние для интерфейса

    var isPaused: Bool {
        if case .paused = phase { return true }
        return false
    }

    var isOnBreak: Bool {
        if case .onBreak = phase { return true }
        return false
    }

    var remaining: TimeInterval {
        switch phase {
        case .working(_, let end), .onBreak(_, let end):
            return max(0, end.timeIntervalSince(now))
        case .paused:
            return 0
        }
    }

    /// Сколько уже прошло: от 0 до 1.
    var progress: Double {
        switch phase {
        case .working(let start, let end), .onBreak(let start, let end):
            let total = end.timeIntervalSince(start)
            guard total > 0 else { return 1 }
            return min(1, max(0, now.timeIntervalSince(start) / total))
        case .paused:
            return 0
        }
    }

    var breakDuration: TimeInterval {
        if case .onBreak(let start, let end) = phase { return end.timeIntervalSince(start) }
        return Double(settings.breakSeconds)
    }

    // MARK: - Действия

    func breakNow() {
        startBreak()
    }

    func skipBreak() {
        finishBreak(playSound: false)
    }

    func snooze() {
        presenter.hide()
        now = Date()
        phase = .working(start: now, end: now.addingTimeInterval(Self.snoozeInterval))
    }

    func pause(for interval: TimeInterval) {
        presenter.hide()
        now = Date()
        phase = .paused(until: now.addingTimeInterval(interval))
    }

    func pauseUntilTomorrow() {
        presenter.hide()
        now = Date()
        let tomorrow = Calendar.current.startOfDay(for: now.addingTimeInterval(24 * 60 * 60))
        phase = .paused(until: tomorrow)
    }

    func resume() {
        startWork()
    }

    // MARK: - Внутренняя логика

    private func tick() {
        now = Date()
        switch phase {
        case .working(_, let end):
            if Self.secondsSinceLastInput() >= Self.awayThreshold {
                // Отошла от компьютера — глаза и так отдыхают, начнём заново, когда вернёшься.
                startWork()
            } else if now >= end {
                startBreak()
            }
        case .onBreak(_, let end):
            if now >= end { finishBreak(playSound: true) }
        case .paused(let until):
            if let until, now >= until { startWork() }
        }
    }

    private func startWork() {
        now = Date()
        phase = .working(start: now, end: now.addingTimeInterval(Double(settings.workMinutes) * 60))
    }

    private func startBreak() {
        now = Date()
        phase = .onBreak(start: now, end: now.addingTimeInterval(Double(settings.breakSeconds)))
        SoundPlayer.shared.play(settings.sound, ending: false)
        presenter.show(style: settings.breakStyle, controller: self)
    }

    private func finishBreak(playSound: Bool) {
        presenter.hide()
        if playSound { SoundPlayer.shared.play(settings.sound, ending: true) }
        startWork()
    }

    private func workDurationChanged(_ minutes: Int) {
        guard case .working = phase else { return }
        now = Date()
        phase = .working(start: now, end: now.addingTimeInterval(Double(minutes) * 60))
    }

    private func userWentAway() {
        if isPaused { return }
        presenter.hide(animated: false)
        startWork()
    }

    private func userCameBack() {
        if isPaused { return }
        startWork()
    }

    private static func secondsSinceLastInput() -> TimeInterval {
        // ~0 означает «любое событие»: клавиатура, мышь, трекпад.
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }
}
