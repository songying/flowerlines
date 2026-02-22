import Foundation

// MARK: - BFS Pathfinding
func bfsReachable(board: [[Int?]], from start: GridPos) -> Set<GridPos> {
    var visited: Set<GridPos> = [start]
    var queue: [GridPos] = [start]
    var reachable: Set<GridPos> = []
    let dirs = [(-1,0),(1,0),(0,-1),(0,1)]
    while !queue.isEmpty {
        let cur = queue.removeFirst()
        for (dr,dc) in dirs {
            let r = cur.row+dr, c = cur.col+dc
            guard r >= 0, r < GRID_SIZE, c >= 0, c < GRID_SIZE else { continue }
            let pos = GridPos(row: r, col: c)
            guard !visited.contains(pos) else { continue }
            visited.insert(pos)
            if board[r][c] == nil { reachable.insert(pos); queue.append(pos) }
        }
    }
    return reachable
}

func findPath(board: [[Int?]], from: GridPos, to: GridPos) -> [GridPos]? {
    var parent: [GridPos: GridPos?] = [from: nil]
    var queue: [GridPos] = [from]
    let dirs = [(-1,0),(1,0),(0,-1),(0,1)]
    while !queue.isEmpty {
        let cur = queue.removeFirst()
        if cur == to {
            var path: [GridPos] = []
            var node: GridPos? = to
            while let n = node {
                path.insert(n, at: 0)
                node = parent[n] ?? nil
            }
            return path
        }
        for (dr,dc) in dirs {
            let r = cur.row+dr, c = cur.col+dc
            guard r >= 0, r < GRID_SIZE, c >= 0, c < GRID_SIZE else { continue }
            let pos = GridPos(row: r, col: c)
            guard parent[pos] == nil else { continue }
            if board[r][c] == nil { parent[pos] = cur; queue.append(pos) }
        }
    }
    return nil
}

// MARK: - Line Detection
func findLines(board: [[Int?]]) -> [AnimCell] {
    var hitSet: Set<GridPos> = []
    let dirs = [(0,1),(1,0),(1,1),(1,-1)]
    for row in 0..<GRID_SIZE {
        for col in 0..<GRID_SIZE {
            guard let type = board[row][col] else { continue }
            for (dr,dc) in dirs {
                let pr = row-dr, pc = col-dc
                if pr >= 0, pr < GRID_SIZE, pc >= 0, pc < GRID_SIZE,
                   board[pr][pc] == type { continue }
                var run: [GridPos] = []
                var r = row, c = col
                while r >= 0, r < GRID_SIZE, c >= 0, c < GRID_SIZE, board[r][c] == type {
                    run.append(GridPos(row: r, col: c)); r += dr; c += dc
                }
                if run.count >= LINE_MIN { run.forEach { hitSet.insert($0) } }
            }
        }
    }
    return hitSet.map { AnimCell(row: $0.row, col: $0.col, type: board[$0.row][$0.col]!) }
}

func calcScore(_ n: Int) -> Int {
    guard n >= LINE_MIN else { return 0 }
    return 10 + (n - LINE_MIN) * 5
}

// MARK: - Shuffle
func shuffled<T>(_ arr: [T]) -> [T] {
    var a = arr
    for i in stride(from: a.count-1, through: 1, by: -1) {
        let j = Int.random(in: 0...i)
        a.swapAt(i, j)
    }
    return a
}

func genNextFlowers() -> [Int] {
    (0..<SPAWN_COUNT).map { _ in Int.random(in: 0..<NUM_TYPES) }
}

// MARK: - Turn Flow (mutates GameState)
class GameLogic {
    weak var state: GameState?
    var onGameOver: (() -> Void)?
    var onEliminateStart: (() -> Void)?
    var onMoveStart: (() -> Void)?
    var onSelectSound: (() -> Void)?

    init(state: GameState) { self.state = state }

    func initGame() {
        guard let state = state else { return }
        state.board = Array(repeating: Array(repeating: nil, count: GRID_SIZE), count: GRID_SIZE)
        state.score = 0
        state.selected = nil
        state.validMoves = nil
        state.animQueue = []
        state.phase = .idle
        state.pendingPhase = nil
        state.eliminatingCells = nil
        state.spawningCells = nil
        state.nextFlowers = genNextFlowers()

        let slots = Array(shuffled(state.emptyCells()).prefix(3))
        slots.forEach { state.board[$0.row][$0.col] = Int.random(in: 0..<NUM_TYPES) }
    }

    func handleTap(row: Int, col: Int, ts: Double) {
        guard let state = state else { return }
        guard state.phase != .animating, state.phase != .gameover else { return }

        let type = state.board[row][col]
        if let type = type {
            if let sel = state.selected, sel.row == row, sel.col == col {
                state.selected = nil; state.validMoves = nil; state.phase = .idle
            } else {
                state.selected = GridPos(row: row, col: col)
                state.validMoves = bfsReachable(board: state.board, from: GridPos(row: row, col: col))
                state.phase = .selected
                onSelectSound?()
            }
        } else if state.phase == .selected, let sel = state.selected {
            let pos = GridPos(row: row, col: col)
            if state.validMoves?.contains(pos) == true {
                initiateMove(fromRow: sel.row, fromCol: sel.col, toRow: row, toCol: col, ts: ts)
                onMoveStart?()
            }
        }
    }

    func initiateMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, ts: Double) {
        guard let state = state else { return }
        guard let path = findPath(board: state.board, from: GridPos(row: fromRow, col: fromCol),
                                  to: GridPos(row: toRow, col: toCol)) else { return }
        let type = state.board[fromRow][fromCol]!
        state.board[fromRow][fromCol] = nil
        state.selected = nil
        state.validMoves = nil
        state.phase = .animating
        state.pendingPhase = "POST_MOVE"
        pushAnim(.move(type: type, path: path, toRow: toRow, toCol: toCol), ts: ts)
    }

    func pushAnim(_ anim: AnimItem, ts: Double) {
        guard let state = state else { return }
        state.animQueue.append(anim)
        if state.animQueue.count == 1 { state.animStart = ts }
    }

    func onAnimDone(ts: Double) {
        guard let state = state else { return }
        let done = state.animQueue.removeFirst()
        switch done.kind {
        case .move:
            state.board[done.toRow!][done.toCol!] = done.type!
        case .eliminate:
            state.eliminatingCells = nil
        case .spawn:
            state.spawningCells = nil
        }
        if !state.animQueue.isEmpty { state.animStart = ts; return }
        advancePhase(ts: ts)
    }

    func advancePhase(ts: Double) {
        guard let state = state else { return }
        switch state.pendingPhase {
        case "POST_MOVE":
            let lines = findLines(board: state.board)
            if !lines.isEmpty { applyEliminate(lines, next: "POST_ELIMINATE_NO_SPAWN", ts: ts) }
            else { doSpawn(ts: ts) }
        case "POST_ELIMINATE_NO_SPAWN":
            state.phase = .idle; state.pendingPhase = nil
        case "POST_SPAWN":
            let lines = findLines(board: state.board)
            if !lines.isEmpty { applyEliminate(lines, next: "POST_ELIMINATE_AFTER_SPAWN", ts: ts) }
            else { finishTurn() }
        case "POST_ELIMINATE_AFTER_SPAWN":
            finishTurn()
        default:
            break
        }
    }

    func applyEliminate(_ lines: [AnimCell], next: String, ts: Double) {
        guard let state = state else { return }
        state.score += calcScore(lines.count)
        saveHS()
        lines.forEach { state.board[$0.row][$0.col] = nil }
        state.eliminatingCells = lines
        state.pendingPhase = next
        pushAnim(.eliminate(cells: lines), ts: ts)
        state.animStart = ts
        onEliminateStart?()
    }

    func doSpawn(ts: Double) {
        guard let state = state else { return }
        let empties = state.emptyCells()
        if empties.isEmpty { finishTurn(); return }
        let slots = Array(shuffled(empties).prefix(SPAWN_COUNT))
        let spawnCells = slots.enumerated().map { (i, cell) in
            AnimCell(row: cell.row, col: cell.col,
                     type: state.nextFlowers[i % state.nextFlowers.count])
        }
        spawnCells.forEach { state.board[$0.row][$0.col] = $0.type }
        state.nextFlowers = genNextFlowers()
        state.spawningCells = spawnCells
        state.pendingPhase = "POST_SPAWN"
        pushAnim(.spawn(cells: spawnCells), ts: ts)
        state.animStart = ts
    }

    func finishTurn() {
        guard let state = state else { return }
        saveHS()
        if state.emptyCells().isEmpty {
            state.phase = .gameover
            state.pendingPhase = nil
            onGameOver?()
        } else {
            state.phase = .idle
            state.pendingPhase = nil
        }
    }

    func saveHS() {
        guard let state = state else { return }
        if state.score > state.highScore { state.highScore = state.score }
    }
}
