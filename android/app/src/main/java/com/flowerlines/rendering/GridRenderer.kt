package com.flowerlines.rendering

import android.graphics.*
import com.flowerlines.game.GameState
import com.flowerlines.game.GRID_SIZE
import com.flowerlines.layout.Layout

class GridRenderer(private val layout: Layout, private val state: GameState) {

    private val fillPaint   = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val textPaint   = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }

    fun drawGrid(canvas: Canvas) {
        val L = layout
        // Green gradient
        val grad = LinearGradient(
            0f, L.headerHeight, 0f, L.headerHeight + L.cellSize * GRID_SIZE,
            Color.parseColor("#dcedc8"), Color.parseColor("#c5e1a5"), Shader.TileMode.CLAMP
        )
        fillPaint.shader = grad
        canvas.drawRect(0f, L.headerHeight, L.gridWidth, L.headerHeight + L.cellSize * GRID_SIZE, fillPaint)
        fillPaint.shader = null

        // Checkerboard + grid lines
        for (r in 0 until GRID_SIZE) {
            for (c in 0 until GRID_SIZE) {
                val x = c.toFloat() * L.cellSize
                val y = L.headerHeight + r.toFloat() * L.cellSize
                if ((r + c) % 2 == 0) {
                    fillPaint.color = Color.argb(56, 255, 255, 255)
                    canvas.drawRect(x, y, x + L.cellSize, y + L.cellSize, fillPaint)
                }
                strokePaint.color = Color.argb(140, 130, 180, 120)
                strokePaint.strokeWidth = 0.7f
                canvas.drawRect(x + 0.35f, y + 0.35f, x + L.cellSize - 0.7f, y + L.cellSize - 0.7f, strokePaint)
            }
        }
    }

    fun drawHighlights(canvas: Canvas) {
        val moves = state.validMoves ?: return
        val L = layout
        for (pos in moves) {
            val x = pos.col.toFloat() * L.cellSize + 1
            val y = L.headerHeight + pos.row.toFloat() * L.cellSize + 1
            fillPaint.color = Color.argb(102, 255, 230, 50)
            canvas.drawRect(x, y, x + L.cellSize - 2, y + L.cellSize - 2, fillPaint)
            fillPaint.color = Color.argb(64, 200, 170, 0)
            canvas.drawCircle(L.cellCX(pos.col), L.cellCY(pos.row), 4f, fillPaint)
        }
    }

    fun drawScoreBar(canvas: Canvas) {
        val L = layout
        val grad = LinearGradient(0f, 0f, 0f, L.headerHeight,
            Color.parseColor("#2e7d32"), Color.parseColor("#1b5e20"), Shader.TileMode.CLAMP)
        fillPaint.shader = grad
        canvas.drawRect(0f, 0f, L.gridWidth, L.headerHeight, fillPaint)
        fillPaint.shader = null

        val cy = L.headerHeight / 2f
        textPaint.apply {
            textAlign = Paint.Align.LEFT
            color = Color.WHITE
            textSize = L.scoreFontSize
            isFakeBoldText = true
        }
        canvas.drawText("Score: ${state.score}", 16f * L.scale, cy + L.scoreFontSize/3, textPaint)

        textPaint.apply { color = Color.parseColor("#a5d6a7"); textSize = L.bestFontSize; isFakeBoldText = false }
        canvas.drawText("Best: ${state.highScore}", 160f * L.scale, cy + L.bestFontSize/3, textPaint)

        // Volume button
        drawRoundedButton(canvas, L.volumeBtn, Color.parseColor("#43a047"),
            Color.parseColor("#81c784"), "🔊", 16f * L.scale, bold = false)

        // New Game button
        drawRoundedButton(canvas, L.newGameBtn, Color.parseColor("#43a047"),
            Color.parseColor("#81c784"), "New Game", L.buttonFontSize)
    }

    fun drawGameOver(canvas: Canvas) {
        val L = layout
        fillPaint.color = Color.argb(184, 0, 0, 0)
        canvas.drawRect(0f, 0f, L.gridWidth, L.totalHeight, fillPaint)

        val panelX = 40f * L.scale
        val panelW = L.gridWidth - 80f * L.scale
        val panelRect = RectF(panelX, 155f * L.scale, panelX + panelW, (155f + 300f) * L.scale)

        fillPaint.color = Color.argb(247, 27, 94, 32)
        canvas.drawRoundRect(panelRect, 16f * L.scale, 16f * L.scale, fillPaint)
        strokePaint.color = Color.parseColor("#4caf50"); strokePaint.strokeWidth = 2f
        canvas.drawRoundRect(panelRect, 16f * L.scale, 16f * L.scale, strokePaint)

        val cx = L.gridWidth / 2f
        textPaint.apply { textAlign = Paint.Align.CENTER; color = Color.WHITE; textSize = L.gameOverTitleFont; isFakeBoldText = true }
        canvas.drawText("Game Over", cx, 215f * L.scale + L.gameOverTitleFont / 3, textPaint)

        textPaint.apply { color = Color.parseColor("#a5d6a7"); textSize = L.gameOverBodyFont; isFakeBoldText = false }
        canvas.drawText("Final Score: ${state.score}", cx, 268f * L.scale + L.gameOverBodyFont / 3, textPaint)

        textPaint.color = Color.parseColor("#ffd54f")
        canvas.drawText("Best Score: ${state.highScore}", cx, 310f * L.scale + L.gameOverBodyFont / 3, textPaint)

        drawRoundedButton(canvas, L.gobAdBtn, Color.parseColor("#2e7d32"),
            Color.parseColor("#81c784"), "▶ Watch Ad & Play Again", L.gameOverBtnFont * 0.82f)
        drawRoundedButton(canvas, L.gobBtn, Color.parseColor("#1b5e20"),
            Color.parseColor("#4caf50"), "Play Again", L.gameOverBtnFont * 0.88f)
    }

    private fun drawRoundedButton(
        canvas: Canvas, rect: RectF, fill: Int, stroke: Int,
        label: String, fontSize: Float, bold: Boolean = true
    ) {
        val corner = 8f * layout.scale
        fillPaint.color = fill
        canvas.drawRoundRect(rect, corner, corner, fillPaint)
        strokePaint.color = stroke; strokePaint.strokeWidth = 1.5f
        canvas.drawRoundRect(rect, corner, corner, strokePaint)
        textPaint.apply { textAlign = Paint.Align.CENTER; color = Color.WHITE; textSize = fontSize; isFakeBoldText = bold }
        canvas.drawText(label, rect.centerX(), rect.centerY() + fontSize / 3, textPaint)
    }
}
