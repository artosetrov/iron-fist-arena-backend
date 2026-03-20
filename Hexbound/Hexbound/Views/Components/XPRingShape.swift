import SwiftUI

/// A custom Shape that draws a rounded rectangle starting from top-center, proceeding clockwise.
/// This allows using `.trim(from: 0, to: percentage)` for XP progress effects on the avatar.
struct XPRingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let cornerRadius: CGFloat = LayoutConstants.widgetAvatarRadius + 2
        let inset: CGFloat = LayoutConstants.widgetXpRingWidth / 2

        let adjustedRect = rect.insetBy(dx: inset, dy: inset)

        // Starting point: top-center
        let startX = adjustedRect.midX
        let startY = adjustedRect.minY

        // Move to start (top center)
        path.move(to: CGPoint(x: startX, y: startY))

        // Top edge → top-right corner
        path.addLine(to: CGPoint(x: adjustedRect.maxX - cornerRadius, y: startY))

        // Top-right corner arc
        let topRightCenter = CGPoint(
            x: adjustedRect.maxX - cornerRadius,
            y: adjustedRect.minY + cornerRadius
        )
        path.addArc(
            center: topRightCenter,
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right edge
        path.addLine(to: CGPoint(x: adjustedRect.maxX, y: adjustedRect.maxY - cornerRadius))

        // Bottom-right corner arc
        let bottomRightCenter = CGPoint(
            x: adjustedRect.maxX - cornerRadius,
            y: adjustedRect.maxY - cornerRadius
        )
        path.addArc(
            center: bottomRightCenter,
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: adjustedRect.minX + cornerRadius, y: adjustedRect.maxY))

        // Bottom-left corner arc
        let bottomLeftCenter = CGPoint(
            x: adjustedRect.minX + cornerRadius,
            y: adjustedRect.maxY - cornerRadius
        )
        path.addArc(
            center: bottomLeftCenter,
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left edge
        path.addLine(to: CGPoint(x: adjustedRect.minX, y: adjustedRect.minY + cornerRadius))

        // Top-left corner arc
        let topLeftCenter = CGPoint(
            x: adjustedRect.minX + cornerRadius,
            y: adjustedRect.minY + cornerRadius
        )
        path.addArc(
            center: topLeftCenter,
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        // Back to top center
        path.addLine(to: CGPoint(x: startX, y: startY))

        return path
    }
}
