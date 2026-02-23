import UIKit

class GameView: UIView {
    var gameState: GameState!
    var gameLogic: GameLogic!
    var audioManager: AudioManager = .shared
    var onWatchAd: (() -> Void)?
    var onNewGame: (() -> Void)?
    var onVolumeToggle: (() -> Void)?

    private var displayLink: CADisplayLink?
    private var layout: Layout = calculateLayout(bounds: .zero, safeAreaInsets: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = true
        backgroundColor = UIColor(hex: "#1a3a1a")
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    // MARK: - Display Link
    func startLoop() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stopLoop() { displayLink?.invalidate(); displayLink = nil }

    @objc private func tick(_ link: CADisplayLink) {
        setNeedsDisplay()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        layout = calculateLayout(bounds: bounds, safeAreaInsets: safeAreaInsets)
    }

    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let ts = (displayLink?.timestamp ?? 0) * 1000 // ms
        ctx.saveGState()
        ctx.translateBy(x: layout.offsetX, y: layout.offsetY)
        renderGame(ctx: ctx, ts: ts)
        ctx.restoreGState()
    }

    private func renderGame(ctx: CGContext, ts: Double) {
        let L = layout
        let state = gameState!

        // 1. Grid
        GridRenderer(layout: L, state: state).drawGrid(ctx: ctx)
        // 3. Highlights
        GridRenderer(layout: L, state: state).drawHighlights(ctx: ctx)

        // 4. Animating keys
        let animKeys = getAnimatingKeys()
        // 5. Static flowers
        for r in 0..<GRID_SIZE {
            for c in 0..<GRID_SIZE {
                guard let type = state.board[r][c] else { continue }
                let pos = GridPos(row: r, col: c)
                if animKeys.contains(pos) { continue }
                if let sel = state.selected, sel.row == r, sel.col == c { continue }
                drawFlower(ctx: ctx, cx: L.cellCX(c), cy: L.cellCY(r), type: type, r: L.flowerRadius)
            }
        }

        // 6. Anim frame
        drawAnimFrame(ctx: ctx, ts: ts)
        // 7. Selected marker
        drawSelectedMarker(ctx: ctx, ts: ts)
        // 8. Score bar
        GridRenderer(layout: L, state: state).drawScoreBar(ctx: ctx)
        // 9. Game Over
        if state.phase == .gameover {
            GridRenderer(layout: L, state: state).drawGameOver(ctx: ctx)
        }
    }

    private func getAnimatingKeys() -> Set<GridPos> {
        var keys = Set<GridPos>()
        gameState.eliminatingCells?.forEach { keys.insert(GridPos(row: $0.row, col: $0.col)) }
        gameState.spawningCells?.forEach    { keys.insert(GridPos(row: $0.row, col: $0.col)) }
        return keys
    }

    private func drawAnimFrame(ctx: CGContext, ts: Double) {
        let state = gameState!
        guard let anim = state.animQueue.first else { return }
        let L = layout
        let rawT = min((ts - state.animStart) / anim.duration, 1.0)

        switch anim.kind {
        case .move:
            let t = easeInOut(rawT)
            let path = anim.path!
            let segs = path.count - 1
            var x: CGFloat, y: CGFloat
            if segs <= 0 {
                x = L.cellCX(path[0].col); y = L.cellCY(path[0].row)
            } else {
                let rawIdx = t * Double(segs)
                let si = min(Int(rawIdx), segs - 1)
                let from = path[si], to = path[si+1]
                x = CGFloat(lerp(Double(L.cellCX(from.col)), Double(L.cellCX(to.col)), rawIdx - Double(si)))
                y = CGFloat(lerp(Double(L.cellCY(from.row)), Double(L.cellCY(to.row)), rawIdx - Double(si)))
            }
            drawFlower(ctx: ctx, cx: x, cy: y, type: anim.type!, r: L.flowerRadius)

        case .eliminate:
            let t = easeOut(rawT)
            state.eliminatingCells?.forEach { cell in
                drawFlower(ctx: ctx, cx: L.cellCX(cell.col), cy: L.cellCY(cell.row),
                           type: cell.type, r: L.flowerRadius * CGFloat(1-t), alpha: CGFloat(1-t))
            }

        case .spawn:
            let t = elasticOut(rawT)
            state.spawningCells?.forEach { cell in
                drawFlower(ctx: ctx, cx: L.cellCX(cell.col), cy: L.cellCY(cell.row),
                           type: cell.type, r: L.flowerRadius * CGFloat(t),
                           alpha: CGFloat(min(1, rawT * 4)))
            }
        }

        if rawT >= 1.0 { gameLogic.onAnimDone(ts: ts) }
    }

    private func drawSelectedMarker(ctx: CGContext, ts: Double) {
        guard let sel = gameState.selected else { return }
        guard let type = gameState.board[sel.row][sel.col] else { return }
        let L = layout
        let pulse = CGFloat(sin(ts / 180.0))
        let cx = L.cellCX(sel.col), cy = L.cellCY(sel.row)

        ctx.saveGState()
        ctx.setStrokeColor(UIColor(red: 1, green: 1, blue: 0.39, alpha: 0.9).cgColor)
        ctx.setLineWidth(3)
        ctx.setShadow(offset: .zero, blur: 10, color: UIColor(red: 1, green: 0.9, blue: 0, alpha: 0.8).cgColor)
        ctx.addEllipse(in: CGRect(x: cx - L.flowerRadius - 7 - pulse*3,
                                   y: cy - L.flowerRadius - 7 - pulse*3,
                                   width: (L.flowerRadius + 7 + pulse*3)*2,
                                   height: (L.flowerRadius + 7 + pulse*3)*2))
        ctx.strokePath()
        ctx.restoreGState()

        drawFlower(ctx: ctx, cx: cx, cy: cy, type: type,
                   r: L.flowerRadius * (1 + pulse * 0.07))
    }

    // MARK: - Input
    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        let pt = gr.location(in: self)
        // Transform to layout coords
        let lx = pt.x - layout.offsetX
        let ly = pt.y - layout.offsetY
        let L = layout
        let state = gameState!

        // Sidebar — ignore
        if lx >= L.gridWidth { return }

        // Score bar
        if ly < L.headerHeight {
            if L.newGameBtn.contains(CGPoint(x: lx, y: ly)) { onNewGame?() }
            if L.volumeBtn.contains(CGPoint(x: lx, y: ly))  { onVolumeToggle?() }
            return
        }

        // Game over buttons
        if state.phase == .gameover {
            if L.gobAdBtn.contains(CGPoint(x: lx, y: ly)) { onWatchAd?() }
            else if L.gobBtn.contains(CGPoint(x: lx, y: ly)) { onNewGame?() }
            return
        }

        // Grid
        if ly >= L.headerHeight {
            let col = Int(lx / L.cellSize)
            let row = Int((ly - L.headerHeight) / L.cellSize)
            if col >= 0, col < GRID_SIZE, row >= 0, row < GRID_SIZE {
                let ts = (displayLink?.timestamp ?? 0) * 1000
                gameLogic.handleTap(row: row, col: col, ts: ts)
            }
        }
    }
}
