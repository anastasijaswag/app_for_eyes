import AppKit

@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var current: NSSound?

    /// `ending` — тихий звук в конце перерыва.
    func play(_ choice: SoundChoice, ending: Bool) {
        guard let base = choice.fileName else { return }
        let name = ending ? "\(base)-end" : base
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
              let sound = NSSound(contentsOf: url, byReference: true) else { return }
        sound.volume = 0.8
        current?.stop()
        current = sound
        sound.play()
    }
}
