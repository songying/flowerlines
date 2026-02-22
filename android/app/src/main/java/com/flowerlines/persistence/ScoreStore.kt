package com.flowerlines.persistence

import android.content.Context
import android.content.SharedPreferences

class ScoreStore(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("flower_lines_prefs", Context.MODE_PRIVATE)

    var highScore: Int
        get() = prefs.getInt("gardenHS", 0)
        set(v) = prefs.edit().putInt("gardenHS", v).apply()

    var bgmVolume: Float
        get() {
            val v = prefs.getFloat("bgm_volume", -1f)
            return if (v < 0 && !bgmMuted) 0.45f else if (v < 0) 0f else v
        }
        set(v) = prefs.edit().putFloat("bgm_volume", v).apply()

    var sfxVolume: Float
        get() {
            val v = prefs.getFloat("sfx_volume", -1f)
            return if (v < 0 && !sfxMuted) 0.45f else if (v < 0) 0f else v
        }
        set(v) = prefs.edit().putFloat("sfx_volume", v).apply()

    var bgmMuted: Boolean
        get() = prefs.getBoolean("bgm_muted", false)
        set(v) = prefs.edit().putBoolean("bgm_muted", v).apply()

    var sfxMuted: Boolean
        get() = prefs.getBoolean("sfx_muted", false)
        set(v) = prefs.edit().putBoolean("sfx_muted", v).apply()
}
