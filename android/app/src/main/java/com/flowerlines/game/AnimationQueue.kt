package com.flowerlines.game

import kotlin.math.*

data class AnimCell(val row: Int, val col: Int, val type: Int)

enum class AnimKind { MOVE, ELIMINATE, SPAWN }

data class AnimItem(
    val kind: AnimKind,
    val duration: Long,        // milliseconds
    // MOVE fields
    val type: Int? = null,
    val path: List<GridPos>? = null,
    val toRow: Int? = null,
    val toCol: Int? = null,
    // ELIMINATE/SPAWN fields
    val cells: List<AnimCell>? = null
) {
    companion object {
        fun move(type: Int, path: List<GridPos>, toRow: Int, toCol: Int): AnimItem {
            val dur = maxOf(300L, path.size.toLong() * 55L)
            return AnimItem(AnimKind.MOVE, dur, type = type, path = path, toRow = toRow, toCol = toCol)
        }
        fun eliminate(cells: List<AnimCell>) = AnimItem(AnimKind.ELIMINATE, 450L, cells = cells)
        fun spawn(cells: List<AnimCell>)     = AnimItem(AnimKind.SPAWN, 400L, cells = cells)
    }
}

fun easeInOut(t: Double) = if (t < 0.5) 2*t*t else -1+(4-2*t)*t
fun easeOut(t: Double)   = 1.0 - (1-t)*(1-t)
fun elasticOut(t: Double): Double {
    if (t <= 0.0) return 0.0
    if (t >= 1.0) return 1.0
    return 2.0.pow(-10*t) * sin((t - 0.075) * 2 * PI / 0.3) + 1
}
fun lerp(a: Double, b: Double, t: Double) = a + (b - a) * t
