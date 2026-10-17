import SwiftUI

// MARK: - Fork scene
//
// The painting supplies the doorways; code supplies the light. Chosen direction
// (canvas "Подсветка двери — варианты", B): no frames, no icon slabs — each
// room betrays itself by what lives in the dark: eyes for monsters, glints for
// treasure, violet mist for a mystery, firelight for a camp, a swaying lantern
// for the merchant. The chosen door also lights the stone around it.

struct DescentForkScene: View {
    let snapshot: DescentSnapshot
    let fork: DescentFork
    let selectedId: String?
    let revealedId: String?
    let revealToken: Int
    let isActive: Bool
    let onSelect: (DescentForkOption) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealAt: Date?

    private var count: Int { max(1, min(3, fork.options.count)) }
    private var asset: String { "rush2-fork-\(snapshot.depthKey)-\(count)" }

    var body: some View {
        GeometryReader { geo in
            let map = DescentSceneMapper(size: geo.size)
            let arches = DescentGeometry.arches(depthKey: snapshot.depthKey, count: count)
            ZStack {
                DescentBackdrop(asset: asset, dim: fork.isBossGate ? 0.34 : 0.18)

                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    ZStack {
                        torches(map: map, arches: arches, t: t)
                        ForEach(Array(fork.options.prefix(count).enumerated()), id: \.element.id) { i, option in
                            DescentDoorFX(
                                rect: map.rect(arches[i]),
                                k: map.k,
                                type: option.known ? option.roomType : nil,
                                selected: option.id == selectedId,
                                seed: i &* 31 &+ snapshot.depth &* 7 &+ 3,
                                t: t,
                                revealAge: revealAge(for: option, now: ctx.date)
                            )
                        }
                    }
                }
                .allowsHitTesting(false)

                DescentVignette()

                ForEach(Array(fork.options.prefix(count).enumerated()), id: \.element.id) { i, option in
                    let r = map.rect(arches[i]).insetBy(dx: -14 * map.k, dy: -20 * map.k)
                    Button {
                        onSelect(option)
                    } label: {
                        Color.clear
                            .frame(width: r.width, height: r.height + 50 * map.k)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(x: r.midX, y: r.midY + 25 * map.k)
                    .accessibilityLabel(accessibilityLabel(option))
                    .accessibilityAddTraits(option.id == selectedId ? .isSelected : [])
                }
            }
        }
        .onChange(of: revealToken) { _, _ in
            revealAt = Date()
        }
    }

    private func revealAge(for option: DescentForkOption, now: Date) -> Double? {
        guard option.id == revealedId, let at = revealAt else { return nil }
        return now.timeIntervalSince(at)
    }

    private func accessibilityLabel(_ option: DescentForkOption) -> String {
        let what = option.known ? (option.typeName ?? "Passage") : "Darkness"
        return "\(option.side) passage: \(what). \(option.cue)"
    }

    /// Wall torches between the doorways (and either side of a lone one).
    @ViewBuilder
    private func torches(map: DescentSceneMapper, arches: [DescentArch], t: Double) -> some View {
        let points: [CGPoint] = {
            if arches.count == 1, let a = arches.first {
                let y = a.y0 + (a.y1 - a.y0) * 0.3
                return [CGPoint(x: a.x0 - 0.13, y: y), CGPoint(x: a.x1 + 0.13, y: y)]
            }
            return zip(arches, arches.dropFirst()).map { a, b in
                CGPoint(x: (a.x1 + b.x0) / 2, y: a.y0 + (a.y1 - a.y0) * 0.3)
            }
        }()
        ForEach(Array(points.enumerated()), id: \.offset) { i, p in
            DescentTorchGlow(center: map.point(p), radius: 240 * map.k, t: t, phase: Double(i) * 0.6)
        }
    }
}

// MARK: - One doorway

struct DescentDoorFX: View {
    let rect: CGRect
    let k: CGFloat
    /// Nil while the passage is dark.
    let type: DescentRoomType?
    let selected: Bool
    let seed: Int
    let t: Double
    let revealAge: Double?

    private var glow: Color { DescentStyle.glow(type) }
    private var w: CGFloat { rect.width }
    private var h: CGFloat { rect.height }

    var body: some View {
        ZStack {
            if selected {
                aura
                pool
            }
            tells
                .frame(width: w, height: h)
                .clipShape(DescentArchShape())
                .opacity(selected ? 1 : 0.6)
                .position(x: rect.midX, y: rect.midY)
            if let age = revealAge, age < 1.4 {
                revealFlash(age)
            }
        }
    }

    // MARK: Selection light

    /// Light spilling from the chosen doorway onto the stone — never into the void.
    private var aura: some View {
        let breath = 0.55 + 0.45 * DescentMotion.wave(t, period: 2.8)
        let color = DescentStyle.aura(type)
        let near = rect.insetBy(dx: -6 * k, dy: -6 * k)
        let far = rect.insetBy(dx: -30 * k, dy: -30 * k)
        return ZStack {
            DescentArchOutline()
                .stroke(color, lineWidth: 64 * k)
                .frame(width: near.width, height: near.height)
                .blur(radius: 28 * k)
                .opacity(0.4)
                .position(x: near.midX, y: near.midY)
            DescentArchOutline()
                .stroke(color, lineWidth: 130 * k)
                .frame(width: far.width, height: far.height)
                .blur(radius: 44 * k)
                .opacity(0.2)
                .position(x: far.midX, y: far.midY)
        }
        .mask {
            DescentOutsideArch(arch: rect).fill(style: FillStyle(eoFill: true))
        }
        .opacity(breath)
        .blendMode(.screen)
    }

    private var pool: some View {
        Ellipse()
            .fill(EllipticalGradient(
                colors: [DescentStyle.core.opacity(0.75), glow.opacity(0.35), glow.opacity(0)],
                center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
            ))
            .frame(width: w * 1.9, height: 72 * k)
            .blur(radius: 5 * k)
            .opacity(0.85)
            .blendMode(.screen)
            .position(x: rect.midX, y: rect.maxY + 10 * k)
    }

    private func revealFlash(_ age: Double) -> some View {
        let o = max(0, 1 - age / 1.4)
        return DescentArchShape()
            .fill(DescentStyle.core)
            .frame(width: w, height: h)
            .blur(radius: 10 * k)
            .opacity(0.85 * o)
            .blendMode(.screen)
            .position(x: rect.midX, y: rect.midY)
    }

    // MARK: What lives behind the door

    @ViewBuilder
    private var tells: some View {
        switch type {
        case .combat, .elite, .boss:
            eyes(big: type != .combat, boss: type == .boss)
        case .treasure:
            treasure
        case .event:
            mist(color: glow, strength: 0.55, motes: true)
        case .camp:
            campfire
        case .merchant:
            lantern
        case nil:
            mist(color: DarkFantasyTheme.vfxStormFog, strength: 0.24, motes: false)
        }
    }

    private func eyes(big: Bool, boss: Bool) -> some View {
        let sep: CGFloat = (boss ? 36 : big ? 30 : 24) * k
        let ew: CGFloat = (boss ? 25 : big ? 21 : 17) * k
        let eh: CGFloat = (boss ? 10 : big ? 8.5 : 7) * k
        let drift = CGFloat(DescentMotion.wave(t, period: big ? 8.2 : 7, phase: Double(seed) * 0.13) - 0.5) * 17 * k
        let hazeX = CGFloat(DescentMotion.wave(t, period: 4.2, phase: Double(seed) * 0.07) - 0.5) * 20 * k
        let haze = 0.3 + 0.3 * DescentMotion.wave(t, period: 4.2, phase: Double(seed) * 0.07)
        let open = DescentMotion.blink(t, period: big ? 6.3 : 5.4, offset: Double(seed) * 1.7)
        let center = CGPoint(x: w / 2 + drift, y: h * (big ? 0.4 : 0.44))
        let frameW = (sep + ew) * 2 + 12 * k
        let frameH = eh * 3.5
        let embers = big ? DescentParticle.rising(seed: seed &+ 11, count: boss ? 9 : 7, width: w, height: h, k: k,
                                                 spread: 0.8, band: 40 * k, life: 2.6...5.0, rise: 160...300) : []
        return ZStack {
            Ellipse()
                .fill(glow)
                .frame(width: w * 0.96, height: 68 * k)
                .blur(radius: 12 * k)
                .opacity(haze)
                .blendMode(.screen)
                .position(x: w / 2 + hazeX, y: h - 26 * k)
            Ellipse()
                .fill(glow)
                .frame(width: sep * 5.2, height: sep * 2.6)
                .blur(radius: 12 * k)
                .opacity(0.22)
                .blendMode(.screen)
                .position(center)
            ZStack {
                ForEach([CGFloat(-1), CGFloat(1)], id: \.self) { side in
                    DescentEyeShape(side: side, sep: sep, width: ew, height: eh, open: open)
                        .fill(glow)
                        .blur(radius: 5 * k)
                        .opacity(0.95)
                        .blendMode(.screen)
                    DescentEyeShape(side: side, sep: sep, width: ew, height: eh, open: open)
                        .fill(RadialGradient(
                            colors: [DescentStyle.core, DarkFantasyTheme.goldBright, DarkFantasyTheme.btnOrangeBright],
                            center: UnitPoint(x: 0.5 + side * (sep + ew * 0.2) / frameW, y: 0.5),
                            startRadius: 0, endRadius: ew
                        ))
                }
            }
            .frame(width: frameW, height: frameH)
            .position(center)
            if !embers.isEmpty {
                DescentParticleLayer(particles: embers, t: t, color: DarkFantasyTheme.btnOrangeBright, easeOut: true)
            }
        }
        .frame(width: w, height: h)
    }

    private var treasure: some View {
        var rnd = DescentRandom(seed: seed &+ 5)
        let glints: [(CGPoint, CGFloat, Double, Double)] = (0..<7).map { _ in
            let p = CGPoint(x: w / 2 + (rnd.next() - 0.5) * w * 0.72, y: h - 16 * k - rnd.next() * h * 0.32)
            let size = (24 + rnd.next() * 24) * k
            let dur = 2.2 + Double(rnd.next()) * 1.8
            return (p, size, dur, Double(rnd.next()) * dur)
        }
        let breath = 0.7 + 0.3 * DescentMotion.wave(t, period: 2.8)
        return ZStack {
            Ellipse()
                .fill(EllipticalGradient(
                    colors: [DescentStyle.core.opacity(0.95), glow.opacity(0.55), glow.opacity(0.12), glow.opacity(0)],
                    center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
                ))
                .frame(width: w, height: h * 0.4)
                .blur(radius: 12 * k)
                .opacity(breath)
                .blendMode(.screen)
                .position(x: w / 2, y: h - 34 * k)
            ForEach(0..<glints.count, id: \.self) { i in
                let g = glints[i]
                let f = DescentMotion.frac(t, period: g.2, offset: g.3)
                DescentStarShape()
                    .fill(DescentStyle.core)
                    .frame(width: g.1, height: g.1)
                    .scaleEffect(CGFloat(DescentMotion.keys(f, [(0, 0.2), (0.45, 1), (0.6, 0.4), (1, 0.2)])))
                    .rotationEffect(.degrees(DescentMotion.keys(f, [(0, 0), (0.45, 45), (0.6, 70), (1, 90)])))
                    .opacity(DescentMotion.keys(f, [(0, 0), (0.45, 1), (0.6, 0.2), (1, 0)]))
                    .blendMode(.screen)
                    .position(g.0)
            }
        }
        .frame(width: w, height: h)
    }

    private func mist(color: Color, strength: Double, motes: Bool) -> some View {
        let clouds: [(CGPoint, CGSize, CGSize, Double)] = motes
            ? [
                (CGPoint(x: w * 0.32, y: h * 0.45), CGSize(width: -14, height: 0), CGSize(width: 16, height: -18), 9),
                (CGPoint(x: w * 0.5, y: h * 0.59), CGSize(width: 12, height: 6), CGSize(width: -18, height: -10), 11),
                (CGPoint(x: w * 0.68, y: h * 0.73), CGSize(width: 0, height: 0), CGSize(width: 14, height: -22), 13),
            ]
            : [
                (CGPoint(x: w / 2 - 20 * k, y: h * 0.62), CGSize(width: -14, height: 0), CGSize(width: 16, height: -18), 9),
                (CGPoint(x: w / 2 + 24 * k, y: h * 0.8), CGSize(width: 0, height: 0), CGSize(width: 14, height: -22), 13),
            ]
        let particles = motes ? DescentParticle.rising(seed: seed &+ 71, count: 7, width: w, height: h, k: k,
                                                       spread: 0.9, band: h * 0.45, life: 4...8, rise: 80...240) : []
        return ZStack {
            ForEach(0..<clouds.count, id: \.self) { i in
                let c = clouds[i]
                let u = CGFloat(DescentMotion.wave(t, period: c.3))
                Ellipse()
                    .fill(color)
                    .frame(width: w * (motes ? 0.68 : 0.7), height: h * (motes ? 0.22 : 0.18))
                    .blur(radius: 18 * k)
                    .opacity(strength * (i == 0 ? 1 : 0.8))
                    .blendMode(.screen)
                    .position(
                        x: c.0.x + (c.1.width + (c.2.width - c.1.width) * u) * k,
                        y: c.0.y + (c.1.height + (c.2.height - c.1.height) * u) * k
                    )
            }
            if !particles.isEmpty {
                DescentParticleLayer(particles: particles, t: t, color: DescentStyle.core)
            }
        }
        .frame(width: w, height: h)
    }

    private var campfire: some View {
        let sparks = DescentParticle.rising(seed: seed &+ 29, count: 6, width: w, height: h - 10 * k, k: k,
                                            spread: 0.6, band: 20 * k, life: 2.2...4.2, rise: 120...240)
        return ZStack {
            Ellipse()
                .fill(EllipticalGradient(
                    colors: [DescentStyle.core.opacity(0.95), glow.opacity(0.6), glow.opacity(0.15), glow.opacity(0)],
                    center: .center, startRadiusFraction: 0, endRadiusFraction: 0.5
                ))
                .frame(width: w, height: h * 0.5)
                .blur(radius: 12 * k)
                .opacity(0.6 + 0.4 * DescentMotion.flicker(t, period: 1.1))
                .blendMode(.screen)
                .position(x: w / 2, y: h - 20 * k)
            ForEach([CGFloat(-4), w + 4], id: \.self) { x in
                Ellipse()
                    .fill(glow)
                    .frame(width: 60 * k, height: h * 0.52)
                    .blur(radius: 18 * k)
                    .opacity(0.3 * (0.5 + 0.5 * DescentMotion.flicker(t + Double(x) * 0.01, period: x < 0 ? 0.9 : 1.3)))
                    .blendMode(.screen)
                    .position(x: x < 0 ? -4 * k : w + 4 * k, y: h - h * 0.26)
            }
            DescentParticleLayer(particles: sparks, t: t, color: DarkFantasyTheme.glowEmber, easeOut: true)
        }
        .frame(width: w, height: h)
    }

    private var lantern: some View {
        let theta = 11 * (DescentMotion.wave(t, period: 6.8) * 2 - 1) * .pi / 180
        let pivot = CGPoint(x: w / 2, y: 24 * k)
        let length = h * 0.36 - 24 * k
        let pos = CGPoint(x: pivot.x - length * CGFloat(sin(theta)), y: pivot.y + length * CGFloat(cos(theta)))
        return ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [DescentStyle.core.opacity(0.85), DarkFantasyTheme.goldBright.opacity(0.35), glow.opacity(0.14), glow.opacity(0)],
                    center: .center, startRadius: 0, endRadius: w * 0.42
                ))
                .frame(width: w * 0.84, height: w * 0.84)
                .blendMode(.screen)
                .position(pos)
            Circle()
                .fill(DarkFantasyTheme.goldBright)
                .frame(width: 28 * k, height: 28 * k)
                .blur(radius: 5 * k)
                .blendMode(.screen)
                .position(pos)
            Circle()
                .fill(DescentStyle.core)
                .frame(width: 12 * k, height: 12 * k)
                .position(pos)
            Ellipse()
                .fill(glow)
                .frame(width: w * 0.9, height: 44 * k)
                .blur(radius: 8 * k)
                .opacity(0.25 + 0.15 * DescentMotion.wave(t, period: 2.8))
                .blendMode(.screen)
                .position(x: w / 2 + (pos.x - pivot.x) * 0.4, y: h - 12 * k)
        }
        .frame(width: w, height: h)
    }
}
