import Foundation

struct ScoreStore {
    private static let hsKey      = "gardenHS"
    private static let bgmVolKey  = "bgm_volume"
    private static let sfxVolKey  = "sfx_volume"
    private static let bgmMuteKey = "bgm_muted"
    private static let sfxMuteKey = "sfx_muted"

    static var highScore: Int {
        get { UserDefaults.standard.integer(forKey: hsKey) }
        set { UserDefaults.standard.set(newValue, forKey: hsKey) }
    }

    static var bgmVolume: Float {
        get {
            let v = UserDefaults.standard.float(forKey: bgmVolKey)
            return v == 0 && !UserDefaults.standard.bool(forKey: bgmMuteKey) ? 0.45 : v
        }
        set { UserDefaults.standard.set(newValue, forKey: bgmVolKey) }
    }

    static var sfxVolume: Float {
        get {
            let v = UserDefaults.standard.float(forKey: sfxVolKey)
            return v == 0 && !UserDefaults.standard.bool(forKey: sfxMuteKey) ? 0.45 : v
        }
        set { UserDefaults.standard.set(newValue, forKey: sfxVolKey) }
    }

    static var bgmMuted: Bool {
        get { UserDefaults.standard.bool(forKey: bgmMuteKey) }
        set { UserDefaults.standard.set(newValue, forKey: bgmMuteKey) }
    }

    static var sfxMuted: Bool {
        get { UserDefaults.standard.bool(forKey: sfxMuteKey) }
        set { UserDefaults.standard.set(newValue, forKey: sfxMuteKey) }
    }
}
