package com.flowerlines.game

// MARK: - BFS
fun bfsReachable(board: Array<Array<Int?>>, start: GridPos): Set<GridPos> {
    val visited = mutableSetOf(start)
    val queue   = ArrayDeque<GridPos>().also { it.add(start) }
    val reachable = mutableSetOf<GridPos>()
    val dirs = listOf(-1 to 0, 1 to 0, 0 to -1, 0 to 1)
    while (queue.isNotEmpty()) {
        val cur = queue.removeFirst()
        for ((dr, dc) in dirs) {
            val r = cur.row + dr; val c = cur.col + dc
            if (r < 0 || r >= GRID_SIZE || c < 0 || c >= GRID_SIZE) continue
            val pos = GridPos(r, c)
            if (pos in visited) continue
            visited.add(pos)
            if (board[r][c] == null) { reachable.add(pos); queue.add(pos) }
        }
    }
    return reachable
}

fun findPath(board: Array<Array<Int?>>, from: GridPos, to: GridPos): List<GridPos>? {
    val parent = mutableMapOf<GridPos, GridPos?>(from to null)
    val queue  = ArrayDeque<GridPos>().also { it.add(from) }
    val dirs   = listOf(-1 to 0, 1 to 0, 0 to -1, 0 to 1)
    while (queue.isNotEmpty()) {
        val cur = queue.removeFirst()
        if (cur == to) {
            val path = mutableListOf<GridPos>()
            var node: GridPos? = to
            while (node != null) { path.add(0, node); node = parent[node] }
            return path
        }
        for ((dr, dc) in dirs) {
            val r = cur.row + dr; val c = cur.col + dc
            if (r < 0 || r >= GRID_SIZE || c < 0 || c >= GRID_SIZE) continue
            val pos = GridPos(r, c)
            if (pos in parent) continue
            if (board[r][c] == null) { parent[pos] = cur; queue.add(pos) }
        }
    }
    return null
}

fun findLines(board: Array<Array<Int?>>): List<AnimCell> {
    val hitSet = mutableSetOf<GridPos>()
    val dirs = listOf(0 to 1, 1 to 0, 1 to 1, 1 to -1)
    for (row in 0 until GRID_SIZE) {
        for (col in 0 until GRID_SIZE) {
            val type = board[row][col] ?: continue
            for ((dr, dc) in dirs) {
                val pr = row - dr; val pc = col - dc
                if (pr in 0 until GRID_SIZE && pc in 0 until GRID_SIZE && board[pr][pc] == type) continue
                val run = mutableListOf<GridPos>()
                var r = row; var c = col
                while (r in 0 until GRID_SIZE && c in 0 until GRID_SIZE && board[r][c] == type) {
                    run.add(GridPos(r, c)); r += dr; c += dc
                }
                if (run.size >= LINE_MIN) hitSet.addAll(run)
            }
        }
    }
    return hitSet.map { AnimCell(it.row, it.col, board[it.row][it.col]!!) }
}

fun calcScore(n: Int) = if (n >= LINE_MIN) 10 + (n - LINE_MIN) * 5 else 0

fun genNextFlowers() = MutableList(SPAWN_COUNT) { (0 until NUM_TYPES).random() }

fun <T> List<T>.shuffledList(): List<T> = this.shuffled()

// MARK: - GameLogic controller
class GameLogic(private val state: GameState) {
    var onGameOver:      (() -> Unit)? = null
    var onEliminateStart:(() -> Unit)? = null
    var onMoveStart:     (() -> Unit)? = null
    var onSelectSound:   (() -> Unit)? = null

    fun initGame() {
        state.resetBoard()
        state.score = 0
        state.selected = null
        state.validMoves = null
        state.animQueue.clear()
        state.phase = GamePhase.IDLE
        state.pendingPhase = null
        state.eliminatingCells = null
        state.spawningCells = null
        state.nextFlowers = genNextFlowers()

        val slots = state.emptyCells().shuffledList().take(3)
        slots.forEach { state.board[it.row][it.col] = (0 until NUM_TYPES).random() }
    }

    fun handleTap(row: Int, col: Int, tsMs: Long) {
        if (state.phase == GamePhase.ANIMATING || state.phase == GamePhase.GAMEOVER) return
        val type = state.board[row][col]
        if (type != null) {
            val sel = state.selected
            if (sel != null && sel.row == row && sel.col == col) {
                state.selected = null; state.validMoves = null; state.phase = GamePhase.IDLE
            } else {
                state.selected = GridPos(row, col)
                state.validMoves = bfsReachable(state.board, GridPos(row, col))
                state.phase = GamePhase.SELECTED
                onSelectSound?.invoke()
            }
        } else if (state.phase == GamePhase.SELECTED) {
            val sel = state.selected ?: return
            val pos = GridPos(row, col)
            if (state.validMoves?.contains(pos) == true) {
                initiateMove(sel.row, sel.col, row, col, tsMs)
                onMoveStart?.invoke()
            }
        }
    }

    fun initiateMove(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int, tsMs: Long) {
        val path = findPath(state.board, GridPos(fromRow, fromCol), GridPos(toRow, toCol)) ?: return
        val type = state.board[fromRow][fromCol]!!
        state.board[fromRow][fromCol] = null
        state.selected = null; state.validMoves = null
        state.phase = GamePhase.ANIMATING
        state.pendingPhase = "POST_MOVE"
        pushAnim(AnimItem.move(type, path, toRow, toCol), tsMs)
    }

    fun pushAnim(anim: AnimItem, tsMs: Long) {
        state.animQueue.add(anim)
        if (state.animQueue.size == 1) state.animStart = tsMs
    }

    fun onAnimDone(tsMs: Long) {
        val done = state.animQueue.removeAt(0)
        when (done.kind) {
            AnimKind.MOVE     -> state.board[done.toRow!!][done.toCol!!] = done.type!!
            AnimKind.ELIMINATE-> state.eliminatingCells = null
            AnimKind.SPAWN    -> state.spawningCells = null
        }
        if (state.animQueue.isNotEmpty()) { state.animStart = tsMs; return }
        advancePhase(tsMs)
    }

    private fun advancePhase(tsMs: Long) {
        when (state.pendingPhase) {
            "POST_MOVE" -> {
                val lines = findLines(state.board)
                if (lines.isNotEmpty()) applyEliminate(lines, "POST_ELIMINATE_NO_SPAWN", tsMs)
                else doSpawn(tsMs)
            }
            "POST_ELIMINATE_NO_SPAWN" -> { state.phase = GamePhase.IDLE; state.pendingPhase = null }
            "POST_SPAWN" -> {
                val lines = findLines(state.board)
                if (lines.isNotEmpty()) applyEliminate(lines, "POST_ELIMINATE_AFTER_SPAWN", tsMs)
                else finishTurn()
            }
            "POST_ELIMINATE_AFTER_SPAWN" -> finishTurn()
        }
    }

    private fun applyEliminate(lines: List<AnimCell>, next: String, tsMs: Long) {
        state.score += calcScore(lines.size)
        saveHS()
        lines.forEach { state.board[it.row][it.col] = null }
        state.eliminatingCells = lines
        state.pendingPhase = next
        pushAnim(AnimItem.eliminate(lines), tsMs)
        state.animStart = tsMs
        onEliminateStart?.invoke()
    }

    private fun doSpawn(tsMs: Long) {
        val empties = state.emptyCells()
        if (empties.isEmpty()) { finishTurn(); return }
        val slots = empties.shuffledList().take(SPAWN_COUNT)
        val spawnCells = slots.mapIndexed { i, cell ->
            AnimCell(cell.row, cell.col, state.nextFlowers[i % state.nextFlowers.size])
        }
        spawnCells.forEach { state.board[it.row][it.col] = it.type }
        state.nextFlowers = genNextFlowers()
        state.spawningCells = spawnCells
        state.pendingPhase = "POST_SPAWN"
        pushAnim(AnimItem.spawn(spawnCells), tsMs)
        state.animStart = tsMs
    }

    private fun finishTurn() {
        saveHS()
        if (state.emptyCells().isEmpty()) {
            state.phase = GamePhase.GAMEOVER; state.pendingPhase = null
            onGameOver?.invoke()
        } else {
            state.phase = GamePhase.IDLE; state.pendingPhase = null
        }
    }

    private fun saveHS() { if (state.score > state.highScore) state.highScore = state.score }
}
