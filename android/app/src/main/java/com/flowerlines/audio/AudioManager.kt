package com.flowerlines.audio

import android.content.Context
import android.media.MediaPlayer
import com.flowerlines.persistence.ScoreStore

class AudioManager(private val context: Context, private val store: ScoreStore) {

    private var bgmPlayer: MediaPlayer? = null
    private var sfxPool: SoundEffectPool? = null

    var bgmVolume: Float = 0.45f
        private set
    var sfxVolume: Float = 0.45f
        private set
    var bgmMuted: Boolean = false
        private set
    var sfxMuted: Boolean = false
        private set

    fun setup() {
        bgmVolume = store.bgmVolume
        sfxVolume = store.sfxVolume
        bgmMuted  = store.bgmMuted
        sfxMuted  = store.sfxMuted

        // BGM
        val bgmId = context.resources.getIdentifier("bgm", "raw", context.packageName)
        if (bgmId != 0) {
            bgmPlayer = MediaPlayer.create(context, bgmId)?.also { mp ->
                mp.isLooping = true
                val vol = if (bgmMuted) 0f else bgmVolume
                mp.setVolume(vol, vol)
                mp.start()
            }
        }

        sfxPool = SoundEffectPool(context)
    }

    fun playSelect()   { if (!sfxMuted) sfxPool?.play("sfx_select",   sfxVolume) }
    fun playMove()     { if (!sfxMuted) sfxPool?.play("sfx_move",     sfxVolume) }
    fun playElim()     { if (!sfxMuted) sfxPool?.play("sfx_eliminate", sfxVolume) }
    fun playGameOver() { if (!sfxMuted) sfxPool?.play("sfx_gameover",  sfxVolume) }

    fun setBGMVolume(v: Float) {
        bgmVolume = v.coerceIn(0f, 1f)
        val vol = if (bgmMuted) 0f else bgmVolume
        bgmPlayer?.setVolume(vol, vol)
        store.bgmVolume = bgmVolume
    }

    fun setSFXVolume(v: Float) {
        sfxVolume = v.coerceIn(0f, 1f)
        store.sfxVolume = sfxVolume
    }

    fun toggleBGMMute() {
        bgmMuted = !bgmMuted
        val vol = if (bgmMuted) 0f else bgmVolume
        bgmPlayer?.setVolume(vol, vol)
        store.bgmMuted = bgmMuted
    }

    fun toggleSFXMute() {
        sfxMuted = !sfxMuted
        store.sfxMuted = sfxMuted
    }

    fun release() {
        bgmPlayer?.release(); bgmPlayer = null
        sfxPool?.release();   sfxPool = null
    }
}
