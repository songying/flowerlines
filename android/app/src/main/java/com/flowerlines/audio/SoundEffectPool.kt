package com.flowerlines.audio

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool

class SoundEffectPool(context: Context) {
    private val pool: SoundPool
    private val soundIds = mutableMapOf<String, Int>()

    init {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        pool = SoundPool.Builder()
            .setMaxStreams(6)
            .setAudioAttributes(attrs)
            .build()
        // Load all SFX files from res/raw
        listOf("sfx_select", "sfx_move", "sfx_eliminate", "sfx_gameover").forEach { name ->
            val resId = context.resources.getIdentifier(name, "raw", context.packageName)
            if (resId != 0) soundIds[name] = pool.load(context, resId, 1)
        }
    }

    fun play(name: String, volume: Float) {
        val id = soundIds[name] ?: return
        pool.play(id, volume, volume, 1, 0, 1f)
    }

    fun release() = pool.release()
}
