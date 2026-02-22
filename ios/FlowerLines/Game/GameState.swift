import Foundation

// MARK: - Constants
let GRID_SIZE   = 9
let NUM_TYPES   = 7
let LINE_MIN    = 5
let SPAWN_COUNT = 3

// MARK: - Game Phase
enum GamePhase {
    case idle, selected, animating, gameover
}

// MARK: - Grid Position
struct GridPos: Hashable, Equatable {
    let row: Int
    let col: Int
}

// MARK: - Game State
class GameState {
    var board: [[Int?]]          // nil = empty, 0-6 = flower type
    var score: Int
    var highScore: Int
    var selected: GridPos?
    var validMoves: Set<GridPos>?
    var nextFlowers: [Int]       // 3 upcoming types
    var animQueue: [AnimItem]
    var phase: GamePhase
    var pendingPhase: String?
    var eliminatingCells: [AnimCell]?
    var spawningCells: [AnimCell]?
    var animStart: Double        // timestamp ms

    init(highScore: Int = 0) {
        self.board = Array(repeating: Array(repeating: nil, count: GRID_SIZE), count: GRID_SIZE)
        self.score = 0
        self.highScore = highScore
        self.selected = nil
        self.validMoves = nil
        self.nextFlowers = []
        self.animQueue = []
        self.phase = .idle
        self.pendingPhase = nil
        self.eliminatingCells = nil
        self.spawningCells = nil
        self.animStart = 0
    }

    func emptyCells() -> [GridPos] {
        var cells: [GridPos] = []
        for r in 0..<GRID_SIZE {
            for c in 0..<GRID_SIZE {
                if board[r][c] == nil { cells.append(GridPos(row: r, col: c)) }
            }
        }
        return cells
    }
}
