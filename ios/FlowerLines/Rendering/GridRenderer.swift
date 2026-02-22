import UIKit

struct GridRenderer {
    let layout: Layout
    let state: GameState

    // MARK: - Grid Background
    func drawGrid(ctx: CGContext) {
        let L = layout
        // Green gradient background
        let grad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [UIColor(hex: "#dcedc8").cgColor, UIColor(hex: "#c5e1a5").cgColor] as CFArray,
            locations: [0, 1])!
        ctx.drawLinearGradient(grad,
            start: CGPoint(x: 0, y: L.headerHeight),
            end:   CGPoint(x: 0, y: L.headerHeight + L.cellSize * CGFloat(GRID_SIZE)),
            options: [])

        // Checkerboard + grid lines
        for r in 0..<GRID_SIZE {
            for c in 0..<GRID_SIZE {
                let x = CGFloat(c) * L.cellSize
                let y = L.headerHeight + CGFloat(r) * L.cellSize
                let rect = CGRect(x: x, y: y, width: L.cellSize, height: L.cellSize)
                if (r + c) % 2 == 0 {
                    ctx.setFillColor(UIColor(white: 1, alpha: 0.22).cgColor)
                    ctx.fill(rect)
                }
                ctx.setStrokeColor(UIColor(red: 0.51, green: 0.71, blue: 0.47, alpha: 0.55).cgColor)
                ctx.setLineWidth(0.7)
                ctx.stroke(rect.insetBy(dx: 0.35, dy: 0.35))
            }
        }
    }

    // MARK: - Highlights
    func drawHighlights(ctx: CGContext) {
        guard let moves = state.validMoves else { return }
        let L = layout
        for pos in moves {
            let x = CGFloat(pos.col) * L.cellSize + 1
            let y = L.headerHeight + CGFloat(pos.row) * L.cellSize + 1
            ctx.setFillColor(UIColor(red: 1, green: 0.9, blue: 0.2, alpha: 0.40).cgColor)
            ctx.fill(CGRect(x: x, y: y, width: L.cellSize-2, height: L.cellSize-2))
            ctx.setFillColor(UIColor(red: 0.78, green: 0.67, blue: 0, alpha: 0.25).cgColor)
            ctx.addEllipse(in: CGRect(x: L.cellCX(pos.col)-4, y: L.cellCY(pos.row)-4, width: 8, height: 8))
            ctx.fillPath()
        }
    }

    // MARK: - Score Bar
    func drawScoreBar(ctx: CGContext) {
        let L = layout
        let grad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [UIColor(hex: "#2e7d32").cgColor, UIColor(hex: "#1b5e20").cgColor] as CFArray,
            locations: [0, 1])!
        ctx.drawLinearGradient(grad,
            start: .zero, end: CGPoint(x: 0, y: L.headerHeight), options: [])

        // Score
        let scoreAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: L.scoreFontSize),
            .foregroundColor: UIColor.white
        ]
        NSAttributedString(string: "Score: \(state.score)", attributes: scoreAttr)
            .draw(at: CGPoint(x: 16*L.scale, y: L.headerHeight/2 - L.scoreFontSize/2))

        // Best
        let bestAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: L.bestFontSize),
            .foregroundColor: UIColor(hex: "#a5d6a7")
        ]
        NSAttributedString(string: "Best: \(state.highScore)", attributes: bestAttr)
            .draw(at: CGPoint(x: 160*L.scale, y: L.headerHeight/2 - L.bestFontSize/2))

        // Volume button
        drawRoundedButton(ctx: ctx, rect: L.volumeBtn, fill: UIColor(hex: "#43a047"),
                          stroke: UIColor(hex: "#81c784"), label: "🔊", fontSize: 16*L.scale)

        // New Game button
        drawRoundedButton(ctx: ctx, rect: L.newGameBtn, fill: UIColor(hex: "#43a047"),
                          stroke: UIColor(hex: "#81c784"), label: "New Game", fontSize: L.buttonFontSize)
    }

    // MARK: - Game Over Overlay
    func drawGameOver(ctx: CGContext) {
        let L = layout
        // Dim grid
        ctx.setFillColor(UIColor(white: 0, alpha: 0.72).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: L.gridWidth, height: L.totalHeight))

        // Panel
        let panelX: CGFloat = 40 * L.scale
        let panelW: CGFloat = L.gridWidth - 80 * L.scale
        ctx.setFillColor(UIColor(red: 0.106, green: 0.369, blue: 0.125, alpha: 0.97).cgColor)
        let panelPath = UIBezierPath(roundedRect: CGRect(x: panelX, y: 155*L.scale, width: panelW, height: 300*L.scale), cornerRadius: 16*L.scale)
        ctx.addPath(panelPath.cgPath); ctx.fillPath()
        ctx.setStrokeColor(UIColor(hex: "#4caf50").cgColor); ctx.setLineWidth(2)
        ctx.addPath(panelPath.cgPath); ctx.strokePath()

        let cx = L.gridWidth / 2

        // Title
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: L.gameOverTitleFont),
            .foregroundColor: UIColor.white
        ]
        let title = NSAttributedString(string: "Game Over", attributes: titleAttr)
        title.draw(at: CGPoint(x: cx - title.size().width/2, y: 215*L.scale - L.gameOverTitleFont/2))

        // Scores
        let scoreAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: L.gameOverBodyFont),
            .foregroundColor: UIColor(hex: "#a5d6a7")
        ]
        let s1 = NSAttributedString(string: "Final Score: \(state.score)", attributes: scoreAttr)
        s1.draw(at: CGPoint(x: cx - s1.size().width/2, y: 268*L.scale - L.gameOverBodyFont/2))

        let bestAttr2: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: L.gameOverBodyFont),
            .foregroundColor: UIColor(hex: "#ffd54f")
        ]
        let s2 = NSAttributedString(string: "Best Score: \(state.highScore)", attributes: bestAttr2)
        s2.draw(at: CGPoint(x: cx - s2.size().width/2, y: 310*L.scale - L.gameOverBodyFont/2))

        // Buttons
        drawRoundedButton(ctx: ctx, rect: L.gobAdBtn, fill: UIColor(hex: "#2e7d32"),
                          stroke: UIColor(hex: "#81c784"), label: "▶ Watch Ad & Play Again",
                          fontSize: L.gameOverBtnFont * 0.82)
        drawRoundedButton(ctx: ctx, rect: L.gobBtn, fill: UIColor(hex: "#1b5e20"),
                          stroke: UIColor(hex: "#4caf50"), label: "Play Again",
                          fontSize: L.gameOverBtnFont * 0.88)
    }

    // MARK: - Helper
    func drawRoundedButton(ctx: CGContext, rect: CGRect, fill: UIColor, stroke: UIColor,
                            label: String, fontSize: CGFloat) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8 * layout.scale)
        ctx.setFillColor(fill.cgColor); ctx.addPath(path.cgPath); ctx.fillPath()
        ctx.setStrokeColor(stroke.cgColor); ctx.setLineWidth(1.5)
        ctx.addPath(path.cgPath); ctx.strokePath()

        let attr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white
        ]
        let str = NSAttributedString(string: label, attributes: attr)
        let sz = str.size()
        str.draw(at: CGPoint(x: rect.midX - sz.width/2, y: rect.midY - sz.height/2))
    }
}
