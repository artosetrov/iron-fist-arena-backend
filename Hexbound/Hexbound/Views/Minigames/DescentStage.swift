import SwiftUI

// MARK: - Scene backdrop

/// A Descent painting, aspect-filled and anchored on `focusY`, with the dim and
/// vignette every room shares. The painting is art; all light on top of it is code.
struct DescentBackdrop: View {
    let asset: String
    var dim: Double = 0.2
    var aspect: CGFloat = DescentGeometry.sceneAspect
    var focusY: CGFloat = 0.52

    var body: some View {
        GeometryReader { geo in
            let map = DescentSceneMapper(size: geo.size, aspect: aspect, focusY: focusY)
            ZStack {
                DarkFantasyTheme.bgAbyss
                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: map.imageRect.width, height: map.imageRect.height)
                    .position(x: map.imageRect.midX, y: map.imageRect.midY)
                DarkFantasyTheme.bgAbyss.opacity(dim)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Darkens the corners so the eye goes to the middle of the room.
struct DescentVignette: View {
    var strength: Double = 0.6

    var body: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [.clear, .clear, DarkFantasyTheme.bgAbyss.opacity(strength)],
                center: UnitPoint(x: 0.5, y: 0.46),
                startRadius: 0,
                endRadius: max(geo.size.width, geo.size.height) * 0.78
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Flickering torchlight at a point of the painting.
struct DescentTorchGlow: View {
    let center: CGPoint
    let radius: CGFloat
    let t: Double
    var phase: Double = 0
    var color: Color = DarkFantasyTheme.glowEmber

    var body: some View {
        let f = DescentMotion.flicker(t + phase, period: 1.3)
        Circle()
            .fill(RadialGradient(
                colors: [color.opacity(0.55), color.opacity(0.18), color.opacity(0)],
                center: .center, startRadius: 0, endRadius: radius
            ))
            .frame(width: radius * 2, height: radius * 2)
            .position(center)
            .opacity(0.55 + 0.4 * f)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }
}

// MARK: - Time-driven motion helpers

/// Pure functions of time, so a single TimelineView drives every looping effect
/// and pausing it (off screen, Reduce Motion) stops all of them at once.
enum DescentMotion {
    static func wave(_ t: Double, period: Double, phase: Double = 0) -> Double {
        0.5 - 0.5 * cos(2 * .pi * (t / period + phase))
    }

    static func frac(_ t: Double, period: Double, offset: Double = 0) -> Double {
        let v = (t + offset) / period
        return v - floor(v)
    }

    /// Torch-like flicker in 0...1 (stepped, like a real flame).
    static func flicker(_ t: Double, period: Double) -> Double {
        let f = frac(t, period: period)
        switch f {
        case ..<0.17: return 0.25
        case ..<0.31: return 0.85
        case ..<0.49: return 0.1
        case ..<0.63: return 0.7
        case ..<0.82: return 0.35
        default: return 1
        }
    }

    /// 1 = open, dips to a slit once per period.
    static func blink(_ t: Double, period: Double, offset: Double) -> CGFloat {
        let f = frac(t, period: period, offset: offset)
        if f < 0.88 || f >= 0.94 { return 1 }
        if f < 0.91 { return CGFloat(1 - (f - 0.88) / 0.03 * 0.94) }
        return CGFloat(0.06 + (f - 0.91) / 0.03 * 0.94)
    }

    /// Piecewise-linear keyframes `(time 0...1, value)`.
    static func keys(_ f: Double, _ points: [(Double, Double)]) -> Double {
        guard let first = points.first else { return 0 }
        if f <= first.0 { return first.1 }
        for i in 1..<points.count {
            let (t0, v0) = points[i - 1]
            let (t1, v1) = points[i]
            if f <= t1 {
                let u = t1 > t0 ? (f - t0) / (t1 - t0) : 1
                return v0 + (v1 - v0) * u
            }
        }
        return points[points.count - 1].1
    }
}

/// One rising mote / ember. Positions are seeded so they keep their paths between frames.
struct DescentParticle {
    let x: CGFloat
    let y: CGFloat
    let r: CGFloat
    let duration: Double
    let offset: Double
    let dx: CGFloat
    let dy: CGFloat

    static func rising(seed: Int, count: Int, width: CGFloat, height: CGFloat, k: CGFloat,
                       spread: CGFloat, band: CGFloat, life: ClosedRange<Double>, rise: ClosedRange<CGFloat>) -> [DescentParticle] {
        var rnd = DescentRandom(seed: seed)
        return (0..<count).map { _ in
            let dur = life.lowerBound + Double(rnd.next()) * (life.upperBound - life.lowerBound)
            return DescentParticle(
                x: width / 2 + (rnd.next() - 0.5) * width * spread,
                y: height - rnd.next() * band,
                r: (1.6 + rnd.next() * 2.2) * k,
                duration: dur,
                offset: Double(rnd.next()) * dur,
                dx: (rnd.next() - 0.5) * 50 * k,
                dy: -(rise.lowerBound + rnd.next() * (rise.upperBound - rise.lowerBound)) * k
            )
        }
    }

    /// Position and opacity at time `t`.
    func state(_ t: Double, easeOut: Bool) -> (CGPoint, Double) {
        let p = DescentMotion.frac(t, period: duration, offset: offset)
        let e = easeOut ? 1 - (1 - p) * (1 - p) : p
        let o = DescentMotion.keys(p, [(0, 0), (0.15, 0.95), (0.8, 0.5), (1, 0)])
        return (CGPoint(x: x + dx * CGFloat(e), y: y + dy * CGFloat(e)), o)
    }
}

struct DescentParticleLayer: View {
    let particles: [DescentParticle]
    let t: Double
    let color: Color
    var easeOut = false

    var body: some View {
        ZStack {
            ForEach(Array(particles.enumerated()), id: \.offset) { _, p in
                let (pos, o) = p.state(t, easeOut: easeOut)
                Circle()
                    .fill(color)
                    .frame(width: p.r * 2, height: p.r * 2)
                    .position(pos)
                    .opacity(o)
            }
        }
        .blendMode(.screen)
    }
}

// MARK: - Floating numbers

struct DescentFloaterView: View {
    let floater: DescentFloater
    @State private var risen = false

    private var color: Color {
        switch floater.tone {
        case .damage: DarkFantasyTheme.textPrimary
        case .crit: DarkFantasyTheme.goldBright
        case .hurt: DarkFantasyTheme.textDanger
        case .heal: DarkFantasyTheme.textSuccess
        case .info: DarkFantasyTheme.textSecondary
        }
    }

    private var font: Font {
        switch floater.tone {
        case .crit: DarkFantasyTheme.combatCalloutLarge
        case .damage: DarkFantasyTheme.cinematicTitle
        default: DarkFantasyTheme.title
        }
    }

    var body: some View {
        Text(floater.text)
            .font(font)
            .foregroundStyle(color)
            .shadow(color: DarkFantasyTheme.bgAbyss.opacity(0.9), radius: 3, y: 2)
            .shadow(color: color.opacity(0.45), radius: 10)
            .offset(y: risen ? -64 : 0)
            .opacity(risen ? 0 : 1)
            // `.animation(value:)` (not withAnimation): the screen root nils transaction animations.
            .animation(.easeOut(duration: 1.1), value: risen)
            .onAppear { risen = true }
            .accessibilityHidden(true)
    }
}

struct DescentFloatersLayer: View {
    let floaters: [DescentFloater]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(floaters) { f in
                    DescentFloaterView(floater: f)
                        .position(position(f, geo.size))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func position(_ f: DescentFloater, _ size: CGSize) -> CGPoint {
        switch f.anchor {
        case .enemy: CGPoint(x: size.width * (0.5 + f.jitter * 0.16), y: size.height * 0.36)
        case .hero: CGPoint(x: size.width * (0.5 + f.jitter * 0.12), y: size.height * 0.8)
        case .scene: CGPoint(x: size.width * 0.5, y: size.height * 0.45)
        }
    }
}

// MARK: - Coin rain

/// Coins (and the odd ruby) tumbling down the scene when gold drops.
struct DescentCoinRain: View {
    let token: Int
    let count: Int
    @State private var startedAt: Date?

    var body: some View {
        GeometryReader { geo in
            if let start = startedAt {
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSince(start)
                    ZStack {
                        ForEach(0..<count, id: \.self) { i in
                            coin(i, t: t, size: geo.size)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: token) { _, _ in
            let now = Date()
            startedAt = now
            Task {
                try? await Task.sleep(for: .milliseconds(1900))
                if startedAt == now { startedAt = nil }
            }
        }
    }

    @ViewBuilder
    private func coin(_ i: Int, t: Double, size: CGSize) -> some View {
        var rnd = DescentRandom(seed: token &* 977 &+ i)
        let x = (0.08 + rnd.next() * 0.84) * size.width
        let delay = Double(rnd.next()) * 0.35
        let fall = 0.85 + Double(rnd.next()) * 0.45
        let side = 20 + rnd.next() * 12
        let spin = (rnd.next() - 0.5) * 900
        let pick = rnd.next()
        let p = max(0, min(1, (t - delay) / fall))
        let y = -40 + (size.height + 80) * CGFloat(p * p)
        let asset = pick < 0.1 ? "rush2-fx-ruby" : pick < 0.4 ? "rush2-fx-coin-tilt" : "rush2-fx-coin"
        if t >= delay && p < 1 {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .rotationEffect(.degrees(Double(spin) * t))
                .position(x: x, y: y)
                .opacity(p > 0.85 ? (1 - p) / 0.15 : 1)
        }
    }
}

// MARK: - Banner, flashes, shake

/// "Slain" / "Guardian slain" — stamped across the scene.
struct DescentBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DarkFantasyTheme.combatCalloutLarge)
            .tracking(4)
            .foregroundStyle(DarkFantasyTheme.goldBright)
            .shadow(color: DarkFantasyTheme.bgAbyss, radius: 2, y: 2)
            .shadow(color: DarkFantasyTheme.goldGlow, radius: 18)
            .rotationEffect(.degrees(-8))
            .transition(.opacity)
            .accessibilityLabel(text)
    }
}

/// Red edges when the hero is hurt, a white-gold blink on a critical hit.
struct DescentFlashLayer: View {
    let hurtToken: Int
    let critToken: Int

    var body: some View {
        ZStack {
            GeometryReader { geo in
                RadialGradient(
                    colors: [.clear, DarkFantasyTheme.danger.opacity(0.7)],
                    center: .center,
                    startRadius: min(geo.size.width, geo.size.height) * 0.25,
                    endRadius: max(geo.size.width, geo.size.height) * 0.75
                )
            }
            .keyframeAnimator(initialValue: 0.0, trigger: hurtToken) { view, v in
                view.opacity(v)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0.85, duration: 0.04)
                    LinearKeyframe(0, duration: 0.45)
                }
            }
            DescentStyle.core
                .keyframeAnimator(initialValue: 0.0, trigger: critToken) { view, v in
                    view.opacity(v)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(0.35, duration: 0.03)
                        LinearKeyframe(0, duration: 0.25)
                    }
                }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// A short horizontal shake each time `token` changes.
    func descentShake(_ token: Int) -> some View {
        keyframeAnimator(initialValue: CGFloat(0), trigger: token) { view, x in
            view.offset(x: x)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(-7, duration: 0.05)
                LinearKeyframe(7, duration: 0.07)
                LinearKeyframe(-5, duration: 0.07)
                LinearKeyframe(4, duration: 0.07)
                LinearKeyframe(0, duration: 0.08)
            }
        }
    }
}
