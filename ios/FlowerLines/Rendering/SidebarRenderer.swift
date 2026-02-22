import UIKit

struct SidebarRenderer {
    let layout: Layout
    let state: GameState

    let colorNames = ["Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple"]

    func drawSidebar(ctx: CGContext, ts: Double) {
        let L = layout
        let sx = L.gridWidth   // sidebar starts here
        let sw = L.sidebarWidth
        let scx = sx + sw / 2

        // Background
        let grad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [UIColor(hex: "#163516").cgColor, UIColor(hex: "#1e4d1e").cgColor] as CFArray,
            locations: [0, 1])!
        ctx.drawLinearGradient(grad,
            start: CGPoint(x: sx, y: 0),
            end:   CGPoint(x: sx + sw, y: 0), options: [])

        // Separator
        ctx.setStrokeColor(UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 0.5).cgColor)
        ctx.setLineWidth(1.5)
        ctx.move(to: CGPoint(x: sx, y: 0))
        ctx.addLine(to: CGPoint(x: sx, y: L.totalHeight))
        ctx.strokePath()

        // Title bar background
        ctx.setFillColor(UIColor(white: 0, alpha: 0.25).cgColor)
        ctx.fill(CGRect(x: sx, y: 0, width: sw, height: L.headerHeight))

        // Title text
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: L.sidebarTitleFont),
            .foregroundColor: UIColor(hex: "#a5d6a7")
        ]
        let title = NSAttributedString(string: "Next Turn", attributes: titleAttr)
        title.draw(at: CGPoint(x: scx - title.size().width/2,
                               y: L.headerHeight/2 - title.size().height/2))

        // Flower preview slots
        let gridH = L.cellSize * CGFloat(GRID_SIZE)
        let slotH = gridH / 3.0

        for (i, type) in state.nextFlowers.enumerated() {
            let slotY = L.headerHeight + CGFloat(i) * slotH
            let cy = slotY + slotH / 2

            // Card background
            let cardRect = CGRect(x: sx + 8*L.scale, y: slotY + 8*L.scale,
                                  width: sw - 16*L.scale, height: slotH - 16*L.scale)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 10*L.scale)
            ctx.setFillColor(UIColor(white: 1, alpha: 0.06).cgColor)
            ctx.addPath(cardPath.cgPath); ctx.fillPath()
            ctx.setStrokeColor(UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 0.25).cgColor)
            ctx.setLineWidth(1)
            ctx.addPath(cardPath.cgPath); ctx.strokePath()

            // Number badge
            ctx.setFillColor(UIColor(red: 0.647, green: 0.839, blue: 0.655, alpha: 0.35).cgColor)
            ctx.addEllipse(in: CGRect(x: sx + 18*L.scale - 9*L.scale,
                                      y: slotY + 18*L.scale - 9*L.scale,
                                      width: 18*L.scale, height: 18*L.scale))
            ctx.fillPath()
            let badgeAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10*L.scale),
                .foregroundColor: UIColor(hex: "#c8e6c9")
            ]
            let badge = NSAttributedString(string: "\(i+1)", attributes: badgeAttr)
            badge.draw(at: CGPoint(x: sx + 18*L.scale - badge.size().width/2,
                                   y: slotY + 18*L.scale - badge.size().height/2))

            // Flower with float animation
            let floatY = CGFloat(sin(ts / 900.0 + Double(i) * 2.1)) * 4.0 * L.scale
            drawFlower(ctx: ctx, cx: scx, cy: cy + floatY, type: type, r: L.sidebarFlowerRadius)

            // Color name
            let nameAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12*L.scale),
                .foregroundColor: FLOWER_COLORS[type]
            ]
            let name = NSAttributedString(string: colorNames[type], attributes: nameAttr)
            name.draw(at: CGPoint(x: scx - name.size().width/2,
                                  y: slotY + slotH - 14*L.scale - name.size().height))
        }
    }
}
