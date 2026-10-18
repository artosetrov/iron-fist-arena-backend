import SwiftUI

// MARK: - Style

enum FortuneTableStyle {
    /// Seat 0 is always the player (they open the round); the regulars take
    /// the rest in the order they sat down, so a colour never jumps seats.
    static func color(forSeat seat: Int) -> Color {
        let palette: [Color] = [
            DarkFantasyTheme.goldBright,
            DarkFantasyTheme.info,
            DarkFantasyTheme.purple,
            DarkFantasyTheme.success,
            DarkFantasyTheme.danger,
            DarkFantasyTheme.cyan,
        ]
        return palette[((seat % palette.count) + palette.count) % palette.count]
    }

    static func tierColor(_ key: String) -> Color {
        switch key {
        case "silver": DarkFantasyTheme.rankSilver
        case "gold": DarkFantasyTheme.rankGold
        default: DarkFantasyTheme.rankBronze
        }
    }

    static func styleLabel(_ style: String) -> String? {
        switch style {
        case "cautious": "Cautious"
        case "steady": "Regular"
        case "whale": "High roller"
        case "gambler": "Gambler"
        default: nil
        }
    }

    /// Spin: long and heavy at the start, a slow crawl over the last slices.
    static let spinDuration: Double = 6.5
    static let spinCurve = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.12, y: 0.75),
        endControlPoint: UnitPoint(x: 0.22, y: 1.0)
    )
    static var spinAnimation: Animation {
        .timingCurve(0.12, 0.75, 0.22, 1.0, duration: spinDuration)
    }
}

// MARK: - Geometry

/// Slices clockwise from 12 o'clock in seat order, sized by stake — the
/// same cut the server uses, so `ticket × 360°` lands in the winner's slice.
struct FortuneTableSliceGeometry: Identifiable, Equatable {
    let seat: FortuneTableSeat
    let start: Double
    let end: Double

    var id: String { seat.id }
    var mid: Double { (start + end) / 2 }
    var span: Double { end - start }

    static func slices(for seats: [FortuneTableSeat]) -> [FortuneTableSliceGeometry] {
        let pot = seats.reduce(0) { $0 + $1.stake }
        guard pot > 0 else { return [] }
        var cumulative = 0
        return seats.map { seat in
            let start = Double(cumulative) / Double(pot) * 360
            cumulative += seat.stake
            let end = Double(cumulative) / Double(pot) * 360
            return FortuneTableSliceGeometry(seat: seat, start: start, end: end)
        }
    }
}

// MARK: - Wheel

struct FortuneTableWheel: View {
    let seats: [FortuneTableSeat]
    let pot: Int
    let rotation: Double
    /// Seat to outline once the wheel rests; the other slices dim.
    var winnerSeat: Int?
    var playerAvatar: String?
    var playerClass: CharacterClass = .warrior

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let faceRadius = radius * 0.9
            let slices = FortuneTableSliceGeometry.slices(for: seats)

            ZStack {
                // Turning face: slices, studs, portraits.
                ZStack {
                    Circle()
                        .fill(DarkFantasyTheme.bgAbyss)
                        .frame(width: faceRadius * 2, height: faceRadius * 2)

                    ForEach(slices) { slice in
                        let color = FortuneTableStyle.color(forSeat: slice.seat.seat)
                        let dimmed = winnerSeat != nil && winnerSeat != slice.seat.seat
                        FortuneTableSlice(start: slice.start, end: slice.end, radiusFactor: 0.9)
                            .fill(
                                RadialGradient(
                                    colors: [color.opacity(DarkFantasyTheme.opacityStrong), color.opacity(DarkFantasyTheme.opacityOpaque)],
                                    center: .center,
                                    startRadius: radius * 0.18,
                                    endRadius: faceRadius
                                )
                            )
                            .opacity(dimmed ? DarkFantasyTheme.opacityStrong : 1)
                        FortuneTableSlice(start: slice.start, end: slice.end, radiusFactor: 0.9)
                            .stroke(DarkFantasyTheme.bgAbyss, lineWidth: 2)
                    }
                    .animation(MotionConstants.springBouncy, value: seats)

                    if let winnerSeat, let slice = slices.first(where: { $0.seat.seat == winnerSeat }) {
                        FortuneTableSlice(start: slice.start, end: slice.end, radiusFactor: 0.9)
                            .stroke(DarkFantasyTheme.goldBright, lineWidth: 4)
                    }

                    studs(radius: radius)

                    ForEach(slices) { slice in
                        medallion(for: slice, radius: radius)
                            // Faces stay upright while the wheel turns.
                            .rotationEffect(.degrees(-rotation))
                            .offset(
                                x: radius * 0.62 * sin(slice.mid * .pi / 180),
                                y: -radius * 0.62 * cos(slice.mid * .pi / 180)
                            )
                            .animation(MotionConstants.springBouncy, value: seats)
                    }
                }
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .animation(FortuneTableStyle.spinAnimation, value: rotation)

                // Fixed rim.
                Circle()
                    .strokeBorder(DarkFantasyTheme.goldGradient, lineWidth: radius * 0.06)
                    .frame(width: faceRadius * 2 + radius * 0.1, height: faceRadius * 2 + radius * 0.1)
                Circle()
                    .stroke(DarkFantasyTheme.bgAbyss.opacity(DarkFantasyTheme.opacityHeavy), lineWidth: 2)
                    .frame(width: faceRadius * 2, height: faceRadius * 2)

                hub(radius: radius)
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: Pieces

    private func studs(radius: CGFloat) -> some View {
        ForEach(0..<24, id: \.self) { i in
            Circle()
                .fill(DarkFantasyTheme.goldDim)
                .frame(width: radius * 0.035, height: radius * 0.035)
                .offset(y: -radius * 0.86)
                .rotationEffect(.degrees(Double(i) * 15))
        }
    }

    @ViewBuilder
    private func medallion(for slice: FortuneTableSliceGeometry, radius: CGFloat) -> some View {
        // Thin slices get a smaller coin, the thinnest none at all.
        let chord = 2 * radius * 0.62 * sin(min(slice.span, 180) / 2 * .pi / 180)
        let side = min(radius * 0.3, max(radius * 0.14, chord * 0.7))
        if slice.span >= 14 {
            let color = FortuneTableStyle.color(forSeat: slice.seat.seat)
            ZStack {
                Circle().fill(DarkFantasyTheme.bgAbyss)
                Group {
                    if slice.seat.isYou {
                        AvatarImageView(skinKey: playerAvatar, characterClass: playerClass, size: side)
                    } else if let portrait = slice.seat.portrait {
                        Image(portrait)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFill()
                    }
                }
                .frame(width: side, height: side)
                .clipShape(Circle())
                Circle().strokeBorder(color, lineWidth: 2.5)
            }
            .frame(width: side, height: side)
            .depthShadow(.card)
            .opacity(winnerSeat != nil && winnerSeat != slice.seat.seat ? DarkFantasyTheme.opacityHeavy : 1)
        }
    }

    private func hub(radius: CGFloat) -> some View {
        let side = radius * 0.62
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DarkFantasyTheme.bgSecondary, DarkFantasyTheme.bgAbyss],
                        center: .center,
                        startRadius: 2,
                        endRadius: side / 2
                    )
                )
            Circle().strokeBorder(DarkFantasyTheme.gold, lineWidth: 2.5)
            Circle()
                .strokeBorder(DarkFantasyTheme.goldBright.opacity(DarkFantasyTheme.opacityStrong), lineWidth: 1)
                .padding(5)
            VStack(spacing: 0) {
                Text("POT")
                    .font(DarkFantasyTheme.body)
                    .foregroundStyle(DarkFantasyTheme.textSecondary)
                    .tracking(2)
                NumberTickUpText(value: pot, color: DarkFantasyTheme.goldBright, font: DarkFantasyTheme.section)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, LayoutConstants.spaceXS)
        }
        .frame(width: side, height: side)
        .depthShadow(.card)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pot \(pot) gold")
    }
}

// MARK: - Slice shape

/// A pie slice between two angles (degrees clockwise from 12 o'clock).
/// Animatable, so slices grow and shrink as others sit down or raise.
struct FortuneTableSlice: Shape {
    var start: Double
    var end: Double
    var radiusFactor: Double = 1

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(start, end) }
        set { start = newValue.first; end = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * radiusFactor
        var path = Path()
        guard end - start > 0.01 else { return path }
        if end - start >= 359.99 {
            path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            return path
        }
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(start - 90), endAngle: .degrees(end - 90), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// MARK: - Pointer ticks

/// Plays a tick each time a slice boundary passes under the pointer while
/// the wheel turns from `from` to `to` degrees along the spin curve.
@MainActor
enum FortuneTableTicker {
    static func run(from: Double, to: Double, boundaries: [Double]) async {
        guard !boundaries.isEmpty, to > from else { return }
        let duration = FortuneTableStyle.spinDuration
        let started = Date.now
        var last = from
        var lastTick = Date.distantPast
        while !Task.isCancelled {
            let t = min(1, Date.now.timeIntervalSince(started) / duration)
            let now = from + (to - from) * FortuneTableStyle.spinCurve.value(at: t)
            // The pointer reads wheel angle −rotation; boundary b passes it
            // whenever rotation + b crosses a multiple of 360.
            let crossed = boundaries.contains { b in
                floor((now + b) / 360) != floor((last + b) / 360)
            }
            if crossed, Date.now.timeIntervalSince(lastTick) > 0.06 {
                SFXManager.shared.play(.uiTap)
                lastTick = .now
            }
            last = now
            if t >= 1 { return }
            try? await Task.sleep(for: .milliseconds(16))
        }
    }
}
