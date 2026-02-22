package com.flowerlines.rendering

import android.graphics.*
import com.flowerlines.game.GameState
import com.flowerlines.game.GRID_SIZE
import com.flowerlines.layout.Layout
import kotlin.math.sin

class SidebarRenderer(private val layout: Layout, private val state: GameState) {

    private val fillPaint   = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val textPaint   = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }

    private val colorNames = arrayOf("Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple")

    fun draw(canvas: Canvas, tsMs: Long) {
        val L = layout
        val sx = L.gridWidth
        val sw = L.sidebarWidth
        val scx = sx + sw / 2f
        val ts = tsMs.toDouble()

        // Background gradient
        val grad = LinearGradient(sx, 0f, sx + sw, 0f,
            Color.parseColor("#163516"), Color.parseColor("#1e4d1e"), Shader.TileMode.CLAMP)
        fillPaint.shader = grad
        canvas.drawRect(sx, 0f, sx + sw, L.totalHeight, fillPaint)
        fillPaint.shader = null

        // Separator
        strokePaint.color = Color.argb(128, 76, 175, 80)
        strokePaint.strokeWidth = 1.5f
        canvas.drawLine(sx, 0f, sx, L.totalHeight, strokePaint)

        // Title bar
        fillPaint.color = Color.argb(64, 0, 0, 0)
        canvas.drawRect(sx, 0f, sx + sw, L.headerHeight, fillPaint)

        textPaint.apply { color = Color.parseColor("#a5d6a7"); textSize = L.sidebarTitleFont; isFakeBoldText = true }
        canvas.drawText("Next Turn", scx, L.headerHeight / 2 + L.sidebarTitleFont / 3, textPaint)

        // Flower slots
        val gridH = L.cellSize * GRID_SIZE
        val slotH = gridH / 3f

        for ((i, type) in state.nextFlowers.withIndex()) {
            val slotY = L.headerHeight + i * slotH
            val cy    = slotY + slotH / 2f

            // Card
            val cardRect = RectF(sx + 8f*L.scale, slotY + 8f*L.scale,
                                 sx + sw - 8f*L.scale, slotY + slotH - 8f*L.scale)
            fillPaint.color = Color.argb(15, 255, 255, 255)
            canvas.drawRoundRect(cardRect, 10f*L.scale, 10f*L.scale, fillPaint)
            strokePaint.color = Color.argb(64, 76, 175, 80); strokePaint.strokeWidth = 1f
            canvas.drawRoundRect(cardRect, 10f*L.scale, 10f*L.scale, strokePaint)

            // Number badge
            fillPaint.color = Color.argb(89, 165, 214, 167)
            canvas.drawCircle(sx + 18f*L.scale, slotY + 18f*L.scale, 9f*L.scale, fillPaint)
            textPaint.apply { color = Color.parseColor("#c8e6c9"); textSize = 10f*L.scale; isFakeBoldText = true; textAlign = Paint.Align.CENTER }
            canvas.drawText("${i+1}", sx + 18f*L.scale, slotY + 18f*L.scale + 4f*L.scale, textPaint)

            // Float animation
            val floatY = sin(ts / 900.0 + i * 2.1).toFloat() * 4f * L.scale
            FlowerRenderer.draw(canvas, scx, cy + floatY, type, L.sidebarFlowerRadius)

            // Color name
            textPaint.apply { color = FLOWER_COLORS[type]; textSize = 12f*L.scale; isFakeBoldText = false; textAlign = Paint.Align.CENTER }
            canvas.drawText(colorNames[type], scx, slotY + slotH - 14f*L.scale, textPaint)
        }
    }
}
