package com.flowerlines.ui

import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.view.Gravity
import android.widget.*
import com.flowerlines.audio.AudioManager

class VolumeControlView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : LinearLayout(context, attrs) {

    lateinit var audio: AudioManager
    var onClose: (() -> Unit)? = null

    private lateinit var bgmSeek: SeekBar
    private lateinit var sfxSeek: SeekBar
    private lateinit var bgmMuteBtn: Button
    private lateinit var sfxMuteBtn: Button

    init {
        orientation = VERTICAL
        setPadding(40, 40, 40, 40)
        setBackgroundColor(Color.argb(235, 25, 25, 25))
        gravity = Gravity.CENTER_HORIZONTAL
        buildUI()
    }

    private fun buildUI() {
        val title = TextView(context).apply {
            text = "Volume Settings"; textSize = 18f; setTextColor(Color.WHITE)
            gravity = Gravity.CENTER; setPadding(0, 0, 0, 16)
        }
        addView(title)

        // BGM row
        bgmSeek = SeekBar(context).apply { max = 100 }
        bgmMuteBtn = makeBtn("Mute") { toggleBGMMute() }
        addView(makeLabel("🎵 BGM"))
        addView(makeRow(bgmSeek, bgmMuteBtn))

        // SFX row
        sfxSeek = SeekBar(context).apply { max = 100 }
        sfxMuteBtn = makeBtn("Mute") { toggleSFXMute() }
        addView(makeLabel("🔊 SFX"))
        addView(makeRow(sfxSeek, sfxMuteBtn))

        val closeBtn = makeBtn("Close") { onClose?.invoke() }
        closeBtn.setBackgroundColor(Color.parseColor("#2e7d32"))
        val closeLp = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply { topMargin = 24 }
        addView(closeBtn, closeLp)

        bgmSeek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(s: SeekBar, p: Int, fromUser: Boolean) {
                if (fromUser && ::audio.isInitialized) audio.setBGMVolume(p / 100f)
            }
            override fun onStartTrackingTouch(s: SeekBar) {}
            override fun onStopTrackingTouch(s: SeekBar) {}
        })
        sfxSeek.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(s: SeekBar, p: Int, fromUser: Boolean) {
                if (fromUser && ::audio.isInitialized) audio.setSFXVolume(p / 100f)
            }
            override fun onStartTrackingTouch(s: SeekBar) {}
            override fun onStopTrackingTouch(s: SeekBar) {}
        })
    }

    fun refreshSliders() {
        if (!::audio.isInitialized) return
        bgmSeek.progress = ((if (audio.bgmMuted) 0f else audio.bgmVolume) * 100).toInt()
        sfxSeek.progress = ((if (audio.sfxMuted) 0f else audio.sfxVolume) * 100).toInt()
        bgmMuteBtn.text = if (audio.bgmMuted) "Unmute" else "Mute"
        sfxMuteBtn.text = if (audio.sfxMuted) "Unmute" else "Mute"
    }

    private fun toggleBGMMute() { audio.toggleBGMMute(); refreshSliders() }
    private fun toggleSFXMute() { audio.toggleSFXMute(); refreshSliders() }

    private fun makeLabel(text: String) = TextView(context).apply {
        this.text = text; textSize = 14f; setTextColor(Color.parseColor("#a5d6a7"))
        setPadding(0, 12, 0, 4)
    }

    private fun makeBtn(label: String, onClick: () -> Unit) = Button(context).apply {
        text = label; textSize = 13f; setTextColor(Color.WHITE)
        setBackgroundColor(Color.argb(180, 60, 60, 60))
        setOnClickListener { onClick() }
    }

    private fun makeRow(seek: SeekBar, btn: Button): LinearLayout {
        return LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            val seekLp = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f)
            val btnLp  = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply { marginStart = 12 }
            addView(seek, seekLp)
            addView(btn, btnLp)
        }
    }
}
