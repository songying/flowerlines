import UIKit

struct Layout {
    let cellSize: CGFloat
    let scale: CGFloat
    let flowerRadius: CGFloat
    let sidebarFlowerRadius: CGFloat
    let headerHeight: CGFloat
    let sidebarWidth: CGFloat
    let gridWidth: CGFloat
    let totalWidth: CGFloat
    let totalHeight: CGFloat
    let offsetX: CGFloat   // horizontal centering offset
    let offsetY: CGFloat   // vertical centering offset

    // Scaled font sizes
    var scoreFontSize: CGFloat    { 19 * scale }
    var bestFontSize: CGFloat     { 15 * scale }
    var buttonFontSize: CGFloat   { 14 * scale }
    var sidebarTitleFont: CGFloat { 13 * scale }
    var gameOverTitleFont: CGFloat{ 34 * scale }
    var gameOverBodyFont: CGFloat { 22 * scale }
    var gameOverBtnFont: CGFloat  { 18 * scale }

    // Button rects (in local layout coords, before offsetting)
    var newGameBtn: CGRect {
        CGRect(x: 340*scale, y: 12*scale, width: 150*scale, height: 36*scale)
    }
    var volumeBtn: CGRect {
        CGRect(x: 290*scale, y: 12*scale, width: 36*scale, height: 36*scale)
    }
    var gobAdBtn: CGRect {
        CGRect(x: 142*scale, y: 340*scale, width: 220*scale, height: 44*scale)
    }
    var gobBtn: CGRect {
        CGRect(x: 142*scale, y: 394*scale, width: 220*scale, height: 38*scale)
    }

    func cellCX(_ col: Int) -> CGFloat { CGFloat(col) * cellSize + cellSize/2 }
    func cellCY(_ row: Int) -> CGFloat { headerHeight + CGFloat(row) * cellSize + cellSize/2 }
    func cellRect(_ row: Int, _ col: Int) -> CGRect {
        CGRect(x: CGFloat(col)*cellSize, y: headerHeight + CGFloat(row)*cellSize,
               width: cellSize, height: cellSize)
    }
}

func calculateLayout(bounds: CGRect, safeAreaInsets: UIEdgeInsets) -> Layout {
    let usableW = bounds.width  - safeAreaInsets.left - safeAreaInsets.right
    let usableH = bounds.height - safeAreaInsets.top  - safeAreaInsets.bottom

    let cellFromWidth  = usableW / (CGFloat(GRID_SIZE) + 130.0/56.0)
    let cellFromHeight = usableH / (CGFloat(GRID_SIZE) + 60.0/56.0)
    let cellSize = min(cellFromWidth, cellFromHeight)
    let scale    = cellSize / 56.0

    let sidebarWidth  = 130.0 * scale
    let headerHeight  = 60.0  * scale
    let gridWidth     = cellSize * CGFloat(GRID_SIZE)
    let totalWidth    = gridWidth + sidebarWidth
    let totalHeight   = headerHeight + cellSize * CGFloat(GRID_SIZE)

    let offsetX = safeAreaInsets.left + (usableW - totalWidth)  / 2
    let offsetY = safeAreaInsets.top  + (usableH - totalHeight) / 2

    return Layout(
        cellSize: cellSize, scale: scale,
        flowerRadius: 20 * scale, sidebarFlowerRadius: 22 * scale,
        headerHeight: headerHeight, sidebarWidth: sidebarWidth,
        gridWidth: gridWidth, totalWidth: totalWidth, totalHeight: totalHeight,
        offsetX: max(offsetX, safeAreaInsets.left),
        offsetY: max(offsetY, safeAreaInsets.top)
    )
}
