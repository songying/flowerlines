package com.flowerlines.layout

import android.graphics.RectF
import com.flowerlines.game.GRID_SIZE

data class Layout(
    val cellSize: Float,
    val scale: Float,
    val flowerRadius: Float,
    val sidebarFlowerRadius: Float,
    val headerHeight: Float,
    val sidebarWidth: Float,
    val gridWidth: Float,
    val totalWidth: Float,
    val totalHeight: Float,
    val offsetX: Float,
    val offsetY: Float
) {
    val scoreFontSize:     Float get() = 19f * scale
    val bestFontSize:      Float get() = 15f * scale
    val buttonFontSize:    Float get() = 14f * scale
    val sidebarTitleFont:  Float get() = 13f * scale
    val gameOverTitleFont: Float get() = 34f * scale
    val gameOverBodyFont:  Float get() = 22f * scale
    val gameOverBtnFont:   Float get() = 18f * scale

    val newGameBtn: RectF  get() = RectF(340f*scale, 12f*scale, (340f+150f)*scale, (12f+36f)*scale)
    val volumeBtn:  RectF  get() = RectF(290f*scale, 12f*scale, (290f+36f)*scale,  (12f+36f)*scale)
    val gobAdBtn:   RectF  get() = RectF(142f*scale, 340f*scale,(142f+220f)*scale, (340f+44f)*scale)
    val gobBtn:     RectF  get() = RectF(142f*scale, 394f*scale,(142f+220f)*scale, (394f+38f)*scale)

    fun cellCX(col: Int) = col.toFloat() * cellSize + cellSize / 2f
    fun cellCY(row: Int) = headerHeight + row.toFloat() * cellSize + cellSize / 2f
}

fun calculateLayout(
    viewWidth: Int, viewHeight: Int,
    insetLeft: Int = 0, insetTop: Int = 0, insetRight: Int = 0, insetBottom: Int = 0
): Layout {
    val usableW = viewWidth  - insetLeft - insetRight
    val usableH = viewHeight - insetTop  - insetBottom

    val cellFromWidth  = usableW  / (GRID_SIZE + 130f / 56f)
    val cellFromHeight = usableH / (GRID_SIZE + 60f  / 56f)
    val cellSize = minOf(cellFromWidth, cellFromHeight)
    val scale    = cellSize / 56f

    val sidebarWidth = 130f * scale
    val headerHeight = 60f  * scale
    val gridWidth    = cellSize * GRID_SIZE
    val totalWidth   = gridWidth + sidebarWidth
    val totalHeight  = headerHeight + cellSize * GRID_SIZE

    val offsetX = insetLeft  + (usableW - totalWidth)  / 2f
    val offsetY = insetTop   + (usableH - totalHeight) / 2f

    return Layout(
        cellSize = cellSize, scale = scale,
        flowerRadius = 20f * scale, sidebarFlowerRadius = 22f * scale,
        headerHeight = headerHeight, sidebarWidth = sidebarWidth,
        gridWidth = gridWidth, totalWidth = totalWidth, totalHeight = totalHeight,
        offsetX = maxOf(offsetX, insetLeft.toFloat()),
        offsetY = maxOf(offsetY, insetTop.toFloat())
    )
}
