package com.flowerlines.rendering

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.os.Build
import android.view.Choreographer
import android.view.MotionEvent
import android.view.View
import android.view.WindowInsets
import com.flowerlines.game.*
import com.flowerlines.layout.Layout
import com.flowerlines.layout.calculateLayout
import kotlin.math.min
import kotlin.math.sin

@SuppressLint("ClickableViewAccessibility")
class GameView(context: Context) : View(context) {

    lateinit var gameState: GameState
    lateinit var gameLogic: GameLogic
    var onWatchAd:     (() -> Unit)? = null
    var onNewGame:     (() -> Unit)? = null
    var onVolumeToggle:(() -> Unit)? = null

    private var layout  = calculateLayout(1, 1)
    private var tsMs: Long = 0
    private var running = false

    private val bgPaint = Paint().apply { color = Color.parseColor("#1a3a1a") }

    // Choreographer callback
    private val frameCallback = object : Choreographer.FrameCallback {
        override fun doFrame(frameTimeNanos: Long) {
            tsMs = frameTimeNanos / 1_000_000L
            invalidate()
            if (running) Choreographer.getInstance().postFrameCallback(this)
        }
    }

    fun startLoop() {
        running = true
        Choreographer.getInstance().postFrameCallback(frameCallback)
    }

    fun stopLoop() { running = false }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        recalcLayout(w, h)
    }

    private fun recalcLayout(w: Int, h: Int) {
        var l = 0; var t = 0; var r = 0; var b = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val insets = rootWindowInsets?.getInsets(WindowInsets.Type.systemBars())
            l = insets?.left ?: 0; t = insets?.top ?: 0
            r = insets?.right ?: 0; b = insets?.bottom ?: 0
        }
        layout = calculateLayout(w, h, l, t, r, b)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val L = layout
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), bgPaint)
        canvas.save()
        canvas.translate(L.offsetX, L.offsetY)
        renderGame(canvas, L)
        canvas.restore()
    }

    private fun renderGame(canvas: Canvas, L: Layout) {
        val state = gameState

        // 1. Sidebar
        SidebarRenderer(L, state).draw(canvas, tsMs)
        // 2. Grid
        val grid = GridRenderer(L, state)
        grid.drawGrid(canvas)
        // 3. Highlights
        grid.drawHighlights(canvas)

        // 4-5. Static flowers
        val animKeys = getAnimatingKeys()
        for (r in 0 until GRID_SIZE) {
            for (c in 0 until GRID_SIZE) {
                val type = state.board[r][c] ?: continue
                val pos = GridPos(r, c)
                if (pos in animKeys) continue
                val sel = state.selected
                if (sel != null && sel.row == r && sel.col == c) continue
                FlowerRenderer.draw(canvas, L.cellCX(c), L.cellCY(r), type, L.flowerRadius)
            }
        }

        // 6. Anim frame
        drawAnimFrame(canvas, L)
        // 7. Selected marker
        drawSelectedMarker(canvas, L)
        // 8. Score bar
        grid.drawScoreBar(canvas)
        // 9. Game over
        if (state.phase == GamePhase.GAMEOVER) grid.drawGameOver(canvas)
    }

    private fun getAnimatingKeys(): Set<GridPos> {
        val keys = mutableSetOf<GridPos>()
        gameState.eliminatingCells?.forEach { keys.add(GridPos(it.row, it.col)) }
        gameState.spawningCells?.forEach    { keys.add(GridPos(it.row, it.col)) }
        return keys
    }

    private fun drawAnimFrame(canvas: Canvas, L: Layout) {
        val state = gameState
        val anim = state.animQueue.firstOrNull() ?: return
        val rawT = min((tsMs - state.animStart).toDouble() / anim.duration.toDouble(), 1.0)

        when (anim.kind) {
            AnimKind.MOVE -> {
                val t = easeInOut(rawT)
                val path = anim.path!!
                val segs = path.size - 1
                val x: Float; val y: Float
                if (segs <= 0) {
                    x = L.cellCX(path[0].col); y = L.cellCY(path[0].row)
                } else {
                    val rawIdx = t * segs
                    val si = min(rawIdx.toInt(), segs - 1)
                    val from = path[si]; val to = path[si + 1]
                    x = lerp(L.cellCX(from.col).toDouble(), L.cellCX(to.col).toDouble(), rawIdx - si).toFloat()
                    y = lerp(L.cellCY(from.row).toDouble(), L.cellCY(to.row).toDouble(), rawIdx - si).toFloat()
                }
                FlowerRenderer.draw(canvas, x, y, anim.type!!, L.flowerRadius)
            }
            AnimKind.ELIMINATE -> {
                val t = easeOut(rawT).toFloat()
                state.eliminatingCells?.forEach { cell ->
                    FlowerRenderer.draw(canvas, L.cellCX(cell.col), L.cellCY(cell.row),
                        cell.type, L.flowerRadius * (1f - t), 1f - t)
                }
            }
            AnimKind.SPAWN -> {
                val t = elasticOut(rawT).toFloat()
                state.spawningCells?.forEach { cell ->
                    FlowerRenderer.draw(canvas, L.cellCX(cell.col), L.cellCY(cell.row),
                        cell.type, L.flowerRadius * t, min(1f, rawT.toFloat() * 4f))
                }
            }
        }

        if (rawT >= 1.0) gameLogic.onAnimDone(tsMs)
    }

    private val selPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeWidth = 3f; color = Color.argb(230, 255, 255, 100)
    }

    private fun drawSelectedMarker(canvas: Canvas, L: Layout) {
        val sel = gameState.selected ?: return
        val type = gameState.board[sel.row][sel.col] ?: return
        val pulse = sin(tsMs.toDouble() / 180.0).toFloat()
        val cx = L.cellCX(sel.col); val cy = L.cellCY(sel.row)
        val ringR = L.flowerRadius + 7f * L.scale + pulse * 3f * L.scale
        canvas.drawCircle(cx, cy, ringR, selPaint)
        FlowerRenderer.draw(canvas, cx, cy, type, L.flowerRadius * (1f + pulse * 0.07f))
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (event.action != MotionEvent.ACTION_UP) return true
        val L = layout
        val lx = event.x - L.offsetX
        val ly = event.y - L.offsetY
        val state = gameState

        if (lx >= L.gridWidth) return true  // sidebar

        if (ly < L.headerHeight) {
            if (L.newGameBtn.contains(lx, ly))  { onNewGame?.invoke(); return true }
            if (L.volumeBtn.contains(lx, ly))   { onVolumeToggle?.invoke(); return true }
            return true
        }

        if (state.phase == GamePhase.GAMEOVER) {
            if (L.gobAdBtn.contains(lx, ly))    { onWatchAd?.invoke() }
            else if (L.gobBtn.contains(lx, ly)) { onNewGame?.invoke() }
            return true
        }

        if (ly >= L.headerHeight) {
            val col = (lx / L.cellSize).toInt()
            val row = ((ly - L.headerHeight) / L.cellSize).toInt()
            if (col in 0 until GRID_SIZE && row in 0 until GRID_SIZE) {
                gameLogic.handleTap(row, col, tsMs)
            }
        }
        return true
    }
}
