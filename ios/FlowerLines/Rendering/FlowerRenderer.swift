import UIKit

// MARK: - Flower Colors
let FLOWER_COLORS: [UIColor] = [
    UIColor(hex: "#e53935"), // 0 Red
    UIColor(hex: "#fb8c00"), // 1 Orange
    UIColor(hex: "#fdd835"), // 2 Yellow
    UIColor(hex: "#43a047"), // 3 Green
    UIColor(hex: "#00acc1"), // 4 Teal
    UIColor(hex: "#1e88e5"), // 5 Blue
    UIColor(hex: "#8e24aa"), // 6 Purple
]
let DARK_FLOWER_COLORS: [UIColor] = FLOWER_COLORS.map { $0.darkened(by: 0.35) }
let PETAL_COUNTS = [5, 6, 8, 4, 6, 5, 7]

extension UIColor {
    convenience init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(red: CGFloat((val >> 16) & 0xFF)/255,
                  green: CGFloat((val >> 8) & 0xFF)/255,
                  blue: CGFloat(val & 0xFF)/255, alpha: 1)
    }
    func darkened(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r*(1-amount), green: g*(1-amount), blue: b*(1-amount), alpha: a)
    }
}

// MARK: - Flower Renderer
func drawFlower(ctx: CGContext, cx: CGFloat, cy: CGFloat, type: Int, r: CGFloat, alpha: CGFloat = 1) {
    guard r > 0, alpha > 0, type >= 0, type < 7 else { return }
    ctx.saveGState()
    ctx.setAlpha(alpha)
    ctx.translateBy(x: cx, y: cy)

    let n = PETAL_COUNTS[type]
    let step = CGFloat.pi * 2 / CGFloat(n)

    // Shadow
    ctx.setShadow(offset: CGSize(width: 0, height: 2), blur: 5,
                  color: UIColor(white: 0, alpha: 0.28).cgColor)
    ctx.setFillColor(FLOWER_COLORS[type].cgColor)
    ctx.setStrokeColor(DARK_FLOWER_COLORS[type].cgColor)
    ctx.setLineWidth(1.2)

    for i in 0..<n {
        ctx.saveGState()
        ctx.rotate(by: step * CGFloat(i))
        drawPetal(ctx: ctx, type: type, r: r)
        ctx.restoreGState()
    }

    // White ring center
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.setFillColor(UIColor(white: 1, alpha: 0.95).cgColor)
    ctx.setStrokeColor(DARK_FLOWER_COLORS[type].cgColor)
    ctx.setLineWidth(1)
    ctx.addEllipse(in: CGRect(x: -r*0.28, y: -r*0.28, width: r*0.56, height: r*0.56))
    ctx.drawPath(using: .fillStroke)

    // Colored dot
    ctx.setFillColor(FLOWER_COLORS[type].cgColor)
    ctx.addEllipse(in: CGRect(x: -r*0.12, y: -r*0.12, width: r*0.24, height: r*0.24))
    ctx.fillPath()

    ctx.restoreGState()
}

private func drawPetal(ctx: CGContext, type: Int, r: CGFloat) {
    let path = UIBezierPath()
    switch type {
    case 0: // Red — 5 petals, teardrop
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -r), controlPoint: CGPoint(x: r*0.55, y: -r*0.45))
        path.addQuadCurve(to: .zero,                 controlPoint: CGPoint(x: -r*0.55, y: -r*0.45))
    case 1: // Orange — circle offset
        path.addArc(withCenter: CGPoint(x: 0, y: -r*0.52), radius: r*0.38,
                    startAngle: 0, endAngle: .pi*2, clockwise: true)
    case 2: // Yellow — slim
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -r), controlPoint: CGPoint(x: r*0.22, y: -r*0.5))
        path.addQuadCurve(to: .zero,                 controlPoint: CGPoint(x: -r*0.22, y: -r*0.5))
    case 3: // Green — clover
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: 0, y: -r),
                      controlPoint1: CGPoint(x:  r*0.75, y: -r*0.1),
                      controlPoint2: CGPoint(x:  r*0.75, y: -r*0.9))
        path.addCurve(to: .zero,
                      controlPoint1: CGPoint(x: -r*0.75, y: -r*0.9),
                      controlPoint2: CGPoint(x: -r*0.75, y: -r*0.1))
    case 4: // Teal — triangle
        path.move(to: .zero)
        path.addLine(to: CGPoint(x:  r*0.22, y: -r*0.48))
        path.addLine(to: CGPoint(x: 0, y: -r))
        path.addLine(to: CGPoint(x: -r*0.22, y: -r*0.48))
        path.close()
    case 5: // Blue — wide teardrop
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -r), controlPoint: CGPoint(x:  r*0.72, y: -r*0.38))
        path.addQuadCurve(to: .zero,                 controlPoint: CGPoint(x: -r*0.72, y: -r*0.38))
    case 6: // Purple — dagger
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: 0, y: -r), controlPoint: CGPoint(x:  r*0.28, y: -r*0.52))
        path.addQuadCurve(to: .zero,                 controlPoint: CGPoint(x: -r*0.28, y: -r*0.52))
    default:
        path.addArc(withCenter: CGPoint(x: 0, y: -r*0.5), radius: r*0.35,
                    startAngle: 0, endAngle: .pi*2, clockwise: true)
    }
    ctx.addPath(path.cgPath)
    ctx.drawPath(using: .fillStroke)
}
