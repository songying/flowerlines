import Foundation

// MARK: - Animation Cell (used by ELIMINATE and SPAWN)
struct AnimCell {
    let row: Int
    let col: Int
    let type: Int
}

// MARK: - Animation Item
enum AnimKind {
    case move, eliminate, spawn
}

struct AnimItem {
    let kind: AnimKind
    let duration: Double    // milliseconds

    // MOVE
    var type: Int?
    var path: [GridPos]?
    var toRow: Int?
    var toCol: Int?

    // ELIMINATE / SPAWN
    var cells: [AnimCell]?

    static func move(type: Int, path: [GridPos], toRow: Int, toCol: Int) -> AnimItem {
        let dur = max(300.0, Double(path.count) * 55.0)
        return AnimItem(kind: .move, duration: dur, type: type, path: path,
                        toRow: toRow, toCol: toCol, cells: nil)
    }

    static func eliminate(cells: [AnimCell]) -> AnimItem {
        AnimItem(kind: .eliminate, duration: 450, type: nil, path: nil,
                 toRow: nil, toCol: nil, cells: cells)
    }

    static func spawn(cells: [AnimCell]) -> AnimItem {
        AnimItem(kind: .spawn, duration: 400, type: nil, path: nil,
                 toRow: nil, toCol: nil, cells: cells)
    }
}

// MARK: - Easing
func easeInOut(_ t: Double) -> Double { t < 0.5 ? 2*t*t : -1+(4-2*t)*t }
func easeOut(_ t: Double) -> Double   { 1 - (1-t)*(1-t) }
func elasticOut(_ t: Double) -> Double {
    if t <= 0 { return 0 }
    if t >= 1 { return 1 }
    return pow(2, -10*t) * sin((t - 0.075) * (2 * .pi) / 0.3) + 1
}
func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b-a)*t }
