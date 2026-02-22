package com.flowerlines.ads

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.os.CountDownTimer
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.TextView
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.interstitial.InterstitialAd
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback

class AdManager(private val activity: Activity) {
    // Use test ID during development — replace before Play Store submission
    private val adUnitId = "ca-app-pub-3940256099942544/1044960115"

    private var interstitialAd: InterstitialAd? = null
    private var overlayView: FrameLayout? = null
    private var windowManager: WindowManager? = null

    fun setup() {
        MobileAds.initialize(activity)
        loadAd()
    }

    fun loadAd() {
        val req = AdRequest.Builder().build()
        InterstitialAd.load(activity, adUnitId, req, object : InterstitialAdLoadCallback() {
            override fun onAdLoaded(ad: InterstitialAd) { interstitialAd = ad }
            override fun onAdFailedToLoad(err: LoadAdError) {
                interstitialAd = null
                println("[Ad] Load failed: $err")
            }
        })
    }

    fun showAd(onFinished: () -> Unit) {
        val ad = interstitialAd ?: run { onFinished(); loadAd(); return }
        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() { removeOverlay(); onFinished(); loadAd() }
            override fun onAdFailedToShowFullScreenContent(e: AdError) { removeOverlay(); onFinished(); loadAd() }
        }
        ad.show(activity)
        showCountdownOverlay(onFinished)
        interstitialAd = null
    }

    private fun showCountdownOverlay(onFinished: () -> Unit) {
        val wm = activity.windowManager
        windowManager = wm

        val overlay = FrameLayout(activity)
        overlay.setBackgroundColor(Color.argb(64, 0, 0, 0))

        val countLabel = TextView(activity).apply {
            text = "3"
            textSize = 42f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setShadowLayer(8f, 0f, 2f, Color.BLACK)
        }
        val skipBtn = Button(activity).apply {
            text = "✕ Skip"
            textSize = 16f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.argb(180, 0, 0, 0))
            visibility = android.view.View.GONE
            setOnClickListener { removeOverlay(); onFinished() }
        }

        val lp1 = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply { gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL; topMargin = 80 }
        val lp2 = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply { gravity = Gravity.TOP or Gravity.END; topMargin = 80; marginEnd = 40 }

        overlay.addView(countLabel, lp1)
        overlay.addView(skipBtn, lp2)
        overlayView = overlay

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            android.graphics.PixelFormat.TRANSLUCENT
        )
        wm.addView(overlay, params)

        object : CountDownTimer(3000, 1000) {
            override fun onTick(ms: Long) { countLabel.text = "${(ms / 1000) + 1}" }
            override fun onFinish() {
                countLabel.visibility = android.view.View.GONE
                skipBtn.visibility = android.view.View.VISIBLE
            }
        }.start()
    }

    private fun removeOverlay() {
        overlayView?.let {
            try { windowManager?.removeView(it) } catch (_: Exception) {}
        }
        overlayView = null
    }
}
