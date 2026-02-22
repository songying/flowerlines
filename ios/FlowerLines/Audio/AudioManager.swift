import AVFoundation
import Foundation

class AudioManager {
    static let shared = AudioManager()

    private var bgmPlayer: AVAudioPlayer?
    private var sfxSelect:   SoundEffect?
    private var sfxMove:     SoundEffect?
    private var sfxElim:     SoundEffect?
    private var sfxGameOver: SoundEffect?

    private(set) var bgmVolume: Float = 0.45
    private(set) var sfxVolume: Float = 0.45
    private(set) var bgmMuted: Bool = false
    private(set) var sfxMuted: Bool = false

    private init() {}

    func setup() {
        // Session
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        // Load persisted volumes
        bgmVolume = ScoreStore.bgmVolume
        sfxVolume = ScoreStore.sfxVolume
        bgmMuted  = ScoreStore.bgmMuted
        sfxMuted  = ScoreStore.sfxMuted

        // BGM
        if let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") {
            bgmPlayer = try? AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = bgmMuted ? 0 : bgmVolume
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
        }

        // SFX
        sfxSelect   = SoundEffect(named: "sfx_select.wav")
        sfxMove     = SoundEffect(named: "sfx_move.wav")
        sfxElim     = SoundEffect(named: "sfx_eliminate.wav")
        sfxGameOver = SoundEffect(named: "sfx_gameover.wav")
    }

    // MARK: - Play SFX
    func playSelect()   { guard !sfxMuted else { return }; sfxSelect?.play(volume: sfxVolume) }
    func playMove()     { guard !sfxMuted else { return }; sfxMove?.play(volume: sfxVolume) }
    func playElim()     { guard !sfxMuted else { return }; sfxElim?.play(volume: sfxVolume) }
    func playGameOver() { guard !sfxMuted else { return }; sfxGameOver?.play(volume: sfxVolume) }

    // MARK: - Volume Control
    func setBGMVolume(_ v: Float) {
        bgmVolume = max(0, min(1, v))
        bgmPlayer?.volume = bgmMuted ? 0 : bgmVolume
        ScoreStore.bgmVolume = bgmVolume
    }

    func setSFXVolume(_ v: Float) {
        sfxVolume = max(0, min(1, v))
        ScoreStore.sfxVolume = sfxVolume
    }

    func toggleBGMMute() {
        bgmMuted = !bgmMuted
        bgmPlayer?.volume = bgmMuted ? 0 : bgmVolume
        ScoreStore.bgmMuted = bgmMuted
    }

    func toggleSFXMute() {
        sfxMuted = !sfxMuted
        ScoreStore.sfxMuted = sfxMuted
    }
}
