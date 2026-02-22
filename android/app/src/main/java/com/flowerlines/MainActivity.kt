package com.flowerlines

import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import com.flowerlines.ads.AdManager
import com.flowerlines.audio.AudioManager
import com.flowerlines.game.GameLogic
import com.flowerlines.game.GameState
import com.flowerlines.persistence.ScoreStore
import com.flowerlines.rendering.GameView
import com.flowerlines.ui.VolumeControlView

class MainActivity : AppCompatActivity() {

    private lateinit var gameView: GameView
    private lateinit var gameState: GameState
    private lateinit var gameLogic: GameLogic
    private lateinit var audioManager: AudioManager
    private lateinit var adManager: AdManager
    private lateinit var store: ScoreStore
    private var volumePanel: VolumeControlView? = null
    private lateinit var rootLayout: FrameLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Full screen immersive
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_FULLSCREEN
        )

        store       = ScoreStore(this)
        audioManager = AudioManager(this, store)
        adManager   = AdManager(this)

        setupGame()
        audioManager.setup()
        adManager.setup()

        // Root layout
        rootLayout = FrameLayout(this)
        gameView = GameView(this)
        gameView.gameState = gameState
        gameView.gameLogic = gameLogic

        gameView.onNewGame      = { startNewGame() }
        gameView.onWatchAd      = { watchAd() }
        gameView.onVolumeToggle = { toggleVolumePanel() }

        rootLayout.addView(gameView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT
        ))
        setContentView(rootLayout)
        gameView.startLoop()
    }

    private fun setupGame() {
        gameState = GameState(store.highScore)
        gameLogic = GameLogic(gameState)
        gameLogic.initGame()

        gameLogic.onGameOver       = { handleGameOver() }
        gameLogic.onEliminateStart = { audioManager.playElim() }
        gameLogic.onMoveStart      = { audioManager.playMove() }
        gameLogic.onSelectSound    = { audioManager.playSelect() }
    }

    private fun startNewGame() {
        store.highScore = gameState.highScore
        gameLogic.initGame()
    }

    private fun watchAd() {
        adManager.showAd { startNewGame() }
    }

    private fun handleGameOver() {
        store.highScore = gameState.highScore
        audioManager.playGameOver()
    }

    private fun toggleVolumePanel() {
        val existing = volumePanel
        if (existing != null) {
            rootLayout.removeView(existing)
            volumePanel = null
        } else {
            val panel = VolumeControlView(this)
            panel.audio = audioManager
            panel.onClose = { toggleVolumePanel() }
            panel.refreshSliders()
            val lp = FrameLayout.LayoutParams(700, FrameLayout.LayoutParams.WRAP_CONTENT).apply {
                gravity = android.view.Gravity.CENTER
            }
            rootLayout.addView(panel, lp)
            volumePanel = panel
        }
    }

    override fun onPause() {
        super.onPause()
        gameView.stopLoop()
    }

    override fun onResume() {
        super.onResume()
        gameView.startLoop()
    }

    override fun onDestroy() {
        super.onDestroy()
        gameView.stopLoop()
        audioManager.release()
    }
}
