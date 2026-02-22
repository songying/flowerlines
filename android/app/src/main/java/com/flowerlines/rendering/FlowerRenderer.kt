package com.flowerlines.rendering

import android.graphics.*
import com.flowerlines.game.PETAL_COUNTS as PETAL_COUNTS_GAME
import kotlin.math.*

val FLOWER_COLORS = intArrayOf(
    Color.parseColor("#e53935"), // 0 Red
    Color.parseColor("#fb8c00"), // 1 Orange
    Color.parseColor("#fdd835"), // 2 Yellow
    Color.parseColor("#43a047"), // 3 Green
    Color.parseColor("#00acc1"), // 4 Teal
    Color.parseColor("#1e88e5"), // 5 Blue
    Color.parseColor("#8e24aa"), // 6 Purple
)

fun darkenColor(color: Int, amount: Float): Int {
    val r = (Color.red(color)   * (1f - amount)).toInt().coerceIn(0, 255)
    val g = (Color.green(color) * (1f - amount)).toInt().coerceIn(0, 255)
    val b = (Color.blue(color)  * (1f - amount)).toInt().coerceIn(0, 255)
    return Color.rgb(r, g, b)
}

val DARK_FLOWER_COLORS = IntArray(7) { darkenColor(FLOWER_COLORS[it], 0.35f) }

private val PETAL_COUNTS_LOCAL = PETAL_COUNTS_GAME

object FlowerRenderer {
    private val fillPaint   = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeWidth = 1.2f
    }
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        maskFilter = BlurMaskFilter(5f, BlurMaskFilter.Blur.NORMAL)
    }
    private val path = Path()

    fun draw(canvas: Canvas, cx: Float, cy: Float, type: Int, r: Float, alpha: Float = 1f) {
        if (r <= 0f || alpha <= 0f || type < 0 || type >= 7) return

        val alphaByte = (alpha * 255).toInt().coerceIn(0, 255)
        val n = PETAL_COUNTS_LOCAL[type]
        val step = 2f * PI.toFloat() / n

        // Shadow pass (translated down 2px)
        canvas.save()
        canvas.translate(cx, cy + 2f)
        shadowPaint.color = Color.argb((0.28f * alphaByte).toInt(), 0, 0, 0)
        for (i in 0 until n) {
            canvas.save()
            canvas.rotate(Math.toDegrees(step * i.toDouble()).toFloat())
            buildPetal(type, r)
            canvas.drawPath(path, shadowPaint)
            canvas.restore()
        }
        canvas.restore()

        // Petal fill + stroke
        canvas.save()
        canvas.translate(cx, cy)
        fillPaint.color = FLOWER_COLORS[type]; fillPaint.alpha = alphaByte
        strokePaint.color = DARK_FLOWER_COLORS[type]; strokePaint.alpha = alphaByte
        strokePaint.strokeWidth = 1.2f

        for (i in 0 until n) {
            canvas.save()
            canvas.rotate(Math.toDegrees(step * i.toDouble()).toFloat())
            buildPetal(type, r)
            canvas.drawPath(path, fillPaint)
            canvas.drawPath(path, strokePaint)
            canvas.restore()
        }

        // White ring
        fillPaint.color = Color.argb(alphaByte, 242, 242, 242)
        strokePaint.color = DARK_FLOWER_COLORS[type]; strokePaint.strokeWidth = 1f; strokePaint.alpha = alphaByte
        canvas.drawCircle(0f, 0f, r * 0.28f, fillPaint)
        canvas.drawCircle(0f, 0f, r * 0.28f, strokePaint)

        // Color dot
        fillPaint.color = FLOWER_COLORS[type]; fillPaint.alpha = alphaByte
        canvas.drawCircle(0f, 0f, r * 0.12f, fillPaint)

        canvas.restore()
    }

    private fun buildPetal(type: Int, r: Float) {
        path.reset()
        when (type) {
            0 -> { // Red — teardrop
                path.moveTo(0f, 0f)
                path.quadTo(r*0.55f, -r*0.45f, 0f, -r)
                path.quadTo(-r*0.55f, -r*0.45f, 0f, 0f)
            }
            1 -> { // Orange — circle
                path.addCircle(0f, -r*0.52f, r*0.38f, Path.Direction.CW)
            }
            2 -> { // Yellow — slim
                path.moveTo(0f, 0f)
                path.quadTo(r*0.22f, -r*0.5f, 0f, -r)
                path.quadTo(-r*0.22f, -r*0.5f, 0f, 0f)
            }
            3 -> { // Green — clover
                path.moveTo(0f, 0f)
                path.cubicTo(r*0.75f, -r*0.1f, r*0.75f, -r*0.9f, 0f, -r)
                path.cubicTo(-r*0.75f, -r*0.9f, -r*0.75f, -r*0.1f, 0f, 0f)
            }
            4 -> { // Teal — triangle
                path.moveTo(0f, 0f)
                path.lineTo(r*0.22f, -r*0.48f)
                path.lineTo(0f, -r)
                path.lineTo(-r*0.22f, -r*0.48f)
                path.close()
            }
            5 -> { // Blue — wide teardrop
                path.moveTo(0f, 0f)
                path.quadTo(r*0.72f, -r*0.38f, 0f, -r)
                path.quadTo(-r*0.72f, -r*0.38f, 0f, 0f)
            }
            6 -> { // Purple — dagger
                path.moveTo(0f, 0f)
                path.quadTo(r*0.28f, -r*0.52f, 0f, -r)
                path.quadTo(-r*0.28f, -r*0.52f, 0f, 0f)
            }
            else -> { path.addCircle(0f, -r*0.5f, r*0.35f, Path.Direction.CW) }
        }
    }
}
