package com.flowerlines.game

const val GRID_SIZE   = 9
const val NUM_TYPES   = 7
const val LINE_MIN    = 5
const val SPAWN_COUNT = 3
val PETAL_COUNTS = intArrayOf(5, 6, 8, 4, 6, 5, 7)

enum class GamePhase { IDLE, SELECTED, ANIMATING, GAMEOVER }

data class GridPos(val row: Int, val col: Int)

class GameState(var highScore: Int = 0) {
    // null = empty, 0-6 = flower type
    val board: Array<Array<Int?>> = Array(GRID_SIZE) { Array(GRID_SIZE) { null } }
    var score: Int = 0
    var selected: GridPos? = null
    var validMoves: Set<GridPos>? = null
    var nextFlowers: MutableList<Int> = mutableListOf()
    var animQueue: MutableList<AnimItem> = mutableListOf()
    var phase: GamePhase = GamePhase.IDLE
    var pendingPhase: String? = null
    var eliminatingCells: List<AnimCell>? = null
    var spawningCells: List<AnimCell>? = null
    var animStart: Long = 0L  // timestamp ms

    fun emptyCells(): List<GridPos> {
        val cells = mutableListOf<GridPos>()
        for (r in 0 until GRID_SIZE)
            for (c in 0 until GRID_SIZE)
                if (board[r][c] == null) cells.add(GridPos(r, c))
        return cells
    }

    fun resetBoard() {
        for (r in 0 until GRID_SIZE)
            for (c in 0 until GRID_SIZE)
                board[r][c] = null
    }
}
