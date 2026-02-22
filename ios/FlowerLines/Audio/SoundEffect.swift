import AVFoundation

/// Wraps a preloaded AVAudioPlayer for a single SFX file.
class SoundEffect {
    private var players: [AVAudioPlayer] = []
    private var index = 0
    private let poolSize = 3   // allow overlapping playback

    init?(named filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil)
                     ?? Bundle.main.url(forResource: filename, withExtension: "wav") else {
            print("[SFX] File not found: \(filename)")
            return nil
        }
        do {
            for _ in 0..<poolSize {
                let p = try AVAudioPlayer(contentsOf: url)
                p.prepareToPlay()
                players.append(p)
            }
        } catch {
            print("[SFX] Init error: \(error)")
            return nil
        }
    }

    func play(volume: Float) {
        guard !players.isEmpty else { return }
        let p = players[index % players.count]
        index = (index + 1) % players.count
        p.volume = volume
        p.currentTime = 0
        p.play()
    }

    func stop() { players.forEach { $0.stop() } }
}
