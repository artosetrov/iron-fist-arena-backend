import SwiftUI

// MARK: - Ambient Storm

/// A living storm over title-screen art: mist drifting along the ground,
/// embers rising off the fires, ash coming down and, every few seconds,
/// lightning in the clouds.
///
/// One `Canvas` on a `TimelineView` capped at 30 fps (20 fps in Low Power
/// Mode). Nothing is stored between frames: every ember, wisp and strike is a
/// pure function of the time since the view appeared, so the layer costs one
/// draw pass per frame and stops completely when it is off screen (pushed
/// under another screen in a NavigationStack), when the app is not active, or
/// when Reduce Motion is on. With Reduce Motion it is a single still frame,
/// with no lightning.
///
/// Drawn entirely in code: ART_STYLE_GUIDE keeps glow and particles out of
/// PNGs. Title screens are a deliberate exception to "no persistent
/// particles" (Hexbound/CLAUDE.md, Motion System), because nothing there is
/// read through them.
///
/// Lightning flashes at most twice in a second; WCAG 2.3.1 allows three.
/// Each strike is followed by `.thunderRumble` (turn off with `thunder: false`).
///
/// Put it directly above the screen's background art and below its content:
///
///     ZStack {
///         AuthBackground()
///         AmbientStormView().ignoresSafeArea()
///         content
///     }
struct AmbientStormView: View {
    /// Which parts of the storm to draw.
    var layers: StormLayers = .all
    /// How far down the screen a bolt may reach, as a fraction of the height.
    /// Keep it above the screen's controls.
    var skyDepth: Double = 0.40
    /// Play `.thunderRumble` after each strike. Goes through `SFXManager`, so
    /// the effects volume and mute apply.
    var thunder: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var origin = Date()
    @State private var isVisible = false

    var body: some View {
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        let still = reduceMotion
        let drawn = still ? layers.subtracting(.lightning) : layers
        let density = lowPower ? 0.6 : 1.0
        let depth = skyDepth
        let start = origin
        let paused = still || !isVisible || scenePhase != .active
        let thunderOn = thunder && drawn.contains(.lightning) && !paused

        TimelineView(.animation(minimumInterval: lowPower ? 1.0 / 20.0 : 1.0 / 30.0, paused: paused)) { timeline in
            let t: Double = still ? 0 : max(0, timeline.date.timeIntervalSince(start))
            Canvas { context, size in
                StormPainter.paint(&context, size: size, time: t,
                                   layers: drawn, density: density, skyDepth: depth)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .task(id: thunderOn) {
            guard thunderOn else { return }
            await StormThunder.run(origin: start)
        }
    }
}

/// The parts of an `AmbientStormView`.
struct StormLayers: OptionSet, Sendable {
    let rawValue: Int

    static let fog = StormLayers(rawValue: 1 << 0)
    static let embers = StormLayers(rawValue: 1 << 1)
    static let ash = StormLayers(rawValue: 1 << 2)
    static let lightning = StormLayers(rawValue: 1 << 3)

    static let all: StormLayers = [.fog, .embers, .ash, .lightning]
}

// MARK: - Painter

private enum StormPainter {

    // Palette — DarkFantasyTheme tokens only.
    static let fogColor = DarkFantasyTheme.vfxStormFog
    static let ashColor = DarkFantasyTheme.vfxAsh
    static let emberDeep = DarkFantasyTheme.glowEmber
    static let emberWarm = DarkFantasyTheme.glowWarm
    static let emberHot = DarkFantasyTheme.goldBright
    static let boltGlow = DarkFantasyTheme.vfxLightningGlow
    static let boltCore = DarkFantasyTheme.vfxLightningCore

    static func paint(_ ctx: inout GraphicsContext, size: CGSize, time t: Double,
                      layers: StormLayers, density: Double, skyDepth: Double) {
        let w = Double(size.width)
        let h = Double(size.height)
        guard w > 0, h > 0 else { return }

        // Back to front: lit sky and the bolt, mist, ash, embers.
        var flash = 0.0
        if layers.contains(.lightning), let hit = StormSchedule.strike(at: t) {
            let light = StormSchedule.envelope(age: hit.age, doubleFlash: hit.strike.doubleFlash)
            flash = light.sky
            drawSkyFlash(ctx, w: w, h: h, strike: hit.strike, intensity: light.sky)
            if hit.strike.hasBolt && light.bolt > 0.02 {
                drawBolt(ctx, w: w, h: h, strike: hit.strike, intensity: light.bolt, skyDepth: skyDepth)
            }
        }
        if layers.contains(.fog) { drawFog(ctx, w: w, h: h, t: t, flash: flash) }
        if layers.contains(.ash) { drawAsh(ctx, w: w, h: h, t: t, density: density) }
        if layers.contains(.embers) { drawEmbers(ctx, w: w, h: h, t: t, density: density) }
    }

    // MARK: Fog

    private struct Wisp {
        let y: Double        // centre line, fraction of height
        let radius: Double   // fraction of width
        let squash: Double   // vertical scale of the ellipse
        let speed: Double    // points per second; the sign is the direction
        let offset: Double   // 0…1, where along its loop it starts
        let alpha: Double
        let bob: Double      // points
        let bobRate: Double  // radians per second
        let phase: Double
    }

    private static let wisps: [Wisp] = {
        var rng = StormRandom(seed: 0x5EED_F065)
        var out: [Wisp] = []
        // Ground mist: wide and slow, drifting right along the bottom.
        for _ in 0..<7 {
            out.append(Wisp(y: rng.range(0.62, 0.95), radius: rng.range(0.55, 0.9),
                            squash: rng.range(0.22, 0.34), speed: rng.range(5, 11),
                            offset: rng.unit(), alpha: rng.range(0.13, 0.2),
                            bob: rng.range(3, 8), bobRate: rng.range(0.15, 0.35),
                            phase: rng.range(0, 6.28)))
        }
        // Wisps around the gate: thinner, drifting left, for parallax.
        for _ in 0..<4 {
            out.append(Wisp(y: rng.range(0.4, 0.62), radius: rng.range(0.35, 0.6),
                            squash: rng.range(0.22, 0.32), speed: -rng.range(3, 7),
                            offset: rng.unit(), alpha: rng.range(0.08, 0.13),
                            bob: rng.range(2, 6), bobRate: rng.range(0.2, 0.4),
                            phase: rng.range(0, 6.28)))
        }
        // Clouds: barely there until lightning lights them up.
        for _ in 0..<3 {
            out.append(Wisp(y: rng.range(0.05, 0.22), radius: rng.range(0.45, 0.65),
                            squash: rng.range(0.3, 0.42), speed: rng.range(2, 4),
                            offset: rng.unit(), alpha: rng.range(0.05, 0.08),
                            bob: rng.range(1, 3), bobRate: rng.range(0.1, 0.2),
                            phase: rng.range(0, 6.28)))
        }
        return out
    }()

    private static func drawFog(_ ctx: GraphicsContext, w: Double, h: Double, t: Double, flash: Double) {
        for wisp in wisps {
            let r = wisp.radius * w
            let span = w + 2 * r
            var x = (wisp.offset * span + wisp.speed * t).truncatingRemainder(dividingBy: span)
            if x < 0 { x += span }
            x -= r
            let y = wisp.y * h + sin(t * wisp.bobRate + wisp.phase) * wisp.bob
            let breathe = 0.8 + 0.2 * sin(t * 0.23 + wisp.phase * 1.7)
            let lit = wisp.y < 0.3 ? flash * 0.12 : flash * 0.03
            let a = wisp.alpha * breathe + lit

            var c = ctx
            c.translateBy(x: x, y: y)
            c.scaleBy(x: 1, y: wisp.squash)
            let gradient = Gradient(stops: [
                .init(color: fogColor.opacity(a), location: 0),
                .init(color: fogColor.opacity(a * 0.5), location: 0.5),
                .init(color: fogColor.opacity(0), location: 1)
            ])
            c.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r)),
                   with: .radialGradient(gradient, center: .zero, startRadius: 0, endRadius: r))
        }
    }

    // MARK: Embers

    private struct Ember {
        let x: Double         // spawn column, fraction of width
        let life: Double      // seconds from the ground to burnt out
        let phase: Double     // seconds into its first life at t = 0
        let rise: Double      // fraction of height climbed over a life
        let swayAmp: Double   // points
        let swayRate: Double  // radians per second
        let drift: Double     // points of wind over a life
        let size: Double      // core radius, points
        let flickerRate: Double
        let heat: Double      // 0 = dull red, 1 = gold
    }

    private static let embers: [Ember] = {
        var rng = StormRandom(seed: 0xE3BE_7500)
        return (0..<44).map { _ -> Ember in
            // Most rise off the fires at the edges of the art, some anywhere.
            let column = rng.unit()
            let x: Double
            if column < 0.35 {
                x = rng.range(0.0, 0.25)
            } else if column < 0.6 {
                x = rng.range(0.75, 1.0)
            } else {
                x = rng.range(0.1, 0.9)
            }
            let life = rng.range(6, 11)
            // One in five is close to the camera: bigger and quicker.
            let near = rng.unit() < 0.2
            return Ember(x: x, life: near ? life * 0.7 : life, phase: rng.range(0, life),
                         rise: rng.range(0.3, 0.9),
                         swayAmp: rng.range(6, 18), swayRate: rng.range(0.6, 1.6),
                         drift: rng.range(10, 45),
                         size: near ? rng.range(2.2, 3.2) : rng.range(0.9, 2.0),
                         flickerRate: rng.range(5, 11), heat: rng.unit())
        }
    }()

    private static func drawEmbers(_ ctx: GraphicsContext, w: Double, h: Double, t: Double, density: Double) {
        var g = ctx
        g.blendMode = .plusLighter
        let count = Int((Double(embers.count) * density).rounded())
        for e in embers.prefix(count) {
            let age = (t + e.phase).truncatingRemainder(dividingBy: e.life)
            let u = age / e.life
            let sway = sin(t * e.swayRate + e.phase) * e.swayAmp
            let x = e.x * w + sway + e.drift * u
            let y = h * (1.03 - e.rise * u)
            let fade = min(u / 0.12, 1) * min((1 - u) / 0.4, 1)
            let flicker = 0.65 + 0.35 * sin(t * e.flickerRate + e.phase * 2.3)
            let a = fade * flicker
            if a < 0.02 { continue }

            let r = e.size * (1 - 0.45 * u)
            let heat = e.heat * (1 - u)          // it cools as it climbs
            let halo = heat > 0.45 ? emberWarm : emberDeep
            let core = heat > 0.55 ? emberHot : emberWarm
            let haloR = r * 5
            let haloGradient = Gradient(colors: [halo.opacity(0.38 * a), halo.opacity(0)])
            g.fill(Path(ellipseIn: CGRect(x: x - haloR, y: y - haloR, width: haloR * 2, height: haloR * 2)),
                   with: .radialGradient(haloGradient, center: CGPoint(x: x, y: y),
                                         startRadius: 0, endRadius: haloR))
            g.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                   with: .color(core.opacity(a)))
        }
    }

    // MARK: Ash

    private struct Flake {
        let x: Double
        let life: Double      // seconds to fall the height of the screen
        let phase: Double
        let swayAmp: Double
        let swayRate: Double
        let drift: Double
        let size: Double
        let spin: Double      // radians per second
        let alpha: Double
    }

    private static let flakes: [Flake] = {
        var rng = StormRandom(seed: 0xA5_F1A4E)
        return (0..<20).map { _ -> Flake in
            let life = rng.range(14, 24)
            return Flake(x: rng.range(-0.05, 0.95), life: life, phase: rng.range(0, life),
                         swayAmp: rng.range(10, 26), swayRate: rng.range(0.25, 0.6),
                         drift: rng.range(15, 50), size: rng.range(0.8, 1.7),
                         spin: rng.range(-2, 2), alpha: rng.range(0.18, 0.38))
        }
    }()

    private static func drawAsh(_ ctx: GraphicsContext, w: Double, h: Double, t: Double, density: Double) {
        let count = Int((Double(flakes.count) * density).rounded())
        for f in flakes.prefix(count) {
            let age = (t + f.phase).truncatingRemainder(dividingBy: f.life)
            let u = age / f.life
            let x = f.x * w + sin(t * f.swayRate + f.phase) * f.swayAmp + f.drift * u
            let y = h * (-0.04 + 1.08 * u)
            let a = min(u / 0.1, 1) * min((1 - u) / 0.25, 1) * f.alpha
            if a < 0.02 { continue }

            var c = ctx
            c.translateBy(x: x, y: y)
            c.rotate(by: .radians(t * f.spin + f.phase))
            let s = f.size
            c.fill(Path(ellipseIn: CGRect(x: -s, y: -s * 0.5, width: s * 2, height: s)),
                   with: .color(ashColor.opacity(a)))
        }
    }

    // MARK: Lightning

    private static func drawSkyFlash(_ ctx: GraphicsContext, w: Double, h: Double,
                                     strike: StormSchedule.Strike, intensity k: Double) {
        var g = ctx
        g.blendMode = .plusLighter

        // The whole sky lifts…
        let skyHeight = h * 0.7
        let sky = Gradient(colors: [boltGlow.opacity(0.18 * k), boltGlow.opacity(0)])
        g.fill(Path(CGRect(x: 0, y: 0, width: w, height: skyHeight)),
               with: .linearGradient(sky, startPoint: CGPoint(x: 0, y: 0),
                                     endPoint: CGPoint(x: 0, y: skyHeight)))

        // …and the clouds around the strike light up.
        let cx = strike.x * w
        let cy = h * 0.04
        let r = w * 0.65
        let cloud = Gradient(colors: [boltGlow.opacity(0.34 * k), boltGlow.opacity(0)])
        g.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r)),
               with: .radialGradient(cloud, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r))
    }

    private static func drawBolt(_ ctx: GraphicsContext, w: Double, h: Double,
                                 strike: StormSchedule.Strike, intensity k: Double, skyDepth: Double) {
        // Seeded per strike, so both flashes of one strike draw the same bolt.
        var rng = StormRandom(seed: strike.seed)
        let startX = strike.x * w
        let endX = min(max(startX + rng.range(-0.14, 0.14) * w, 0.03 * w), 0.97 * w)
        let endY = skyDepth * strike.reach * h
        let main = BoltShape.points(from: CGPoint(x: startX, y: -6), to: CGPoint(x: endX, y: endY),
                                    roughness: 0.22, levels: 6, rng: &rng)

        var strokes: [(path: Path, weight: Double)] = [(BoltShape.path(main), 1)]
        let branchCount = 1 + Int(rng.unit() * 3)
        for _ in 0..<branchCount {
            let index = Int(rng.range(0.2, 0.65) * Double(main.count - 1))
            let from = main[index]
            let length = rng.range(0.22, 0.42) * (endY + 6)
            let side: Double = rng.unit() < 0.5 ? -1 : 1
            let angle = rng.range(0.45, 0.95) * side          // radians off vertical
            let to = CGPoint(x: Double(from.x) + sin(angle) * length,
                             y: Double(from.y) + cos(angle) * length)
            let branch = BoltShape.points(from: from, to: to, roughness: 0.28, levels: 4, rng: &rng)
            strokes.append((BoltShape.path(branch), 0.55))
        }

        var g = ctx
        g.blendMode = .plusLighter
        for line in strokes {
            let wt = line.weight
            g.stroke(line.path, with: .color(boltGlow.opacity(0.18 * k * wt)), style: roundStroke(13 * wt))
            g.stroke(line.path, with: .color(boltGlow.opacity(0.5 * k * wt)), style: roundStroke(4.2 * wt))
            g.stroke(line.path, with: .color(boltCore.opacity(min(1, 1.15 * k) * wt)),
                     style: roundStroke(max(1.0, 1.8 * wt)))
        }
    }

    private static func roundStroke(_ width: Double) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}

// MARK: - Lightning schedule

/// When lightning strikes, where, and how bright it is at a given moment.
/// A fixed, seeded timetable that loops: the first strike lands about two
/// seconds after the screen opens, then one every 5–11 s.
private enum StormSchedule {

    struct Strike {
        let time: Double       // seconds into the loop
        let seed: UInt64
        let x: Double          // where it leaves the clouds, fraction of width
        let reach: Double      // fraction of skyDepth the bolt reaches
        let hasBolt: Bool      // false: a flash inside the clouds only
        let doubleFlash: Bool
    }

    struct Hit {
        let strike: Strike
        let age: Double        // seconds since it struck
    }

    static let strikes: [Strike] = {
        var rng = StormRandom(seed: 0xB01D_FACE)
        var out: [Strike] = []
        var time = 2.4
        for i in 0..<32 {
            // To the left or right of the logo, so the bolt is not hidden by it.
            let left = rng.unit() < 0.5
            let x = left ? rng.range(0.08, 0.34) : rng.range(0.66, 0.92)
            let seed = rng.next()
            let reach = rng.range(0.6, 1.0)
            let hasBolt = i == 0 || rng.unit() < 0.7
            let doubleFlash = rng.unit() < 0.6
            out.append(Strike(time: time, seed: seed, x: x, reach: reach,
                              hasBolt: hasBolt, doubleFlash: doubleFlash))
            time += rng.range(5, 11)
        }
        return out
    }()

    static let cycle: Double = (strikes.last?.time ?? 0) + 9

    /// The rumble trails the flash: a bolt by a moment, a flash deep in the
    /// clouds by longer, as it would from further away.
    static func thunderDelay(for strike: Strike) -> Double {
        strike.hasBolt ? 0.2 : 0.9
    }

    /// The first moment after `t` (seconds since the view appeared) at which a
    /// strike's thunder starts.
    static func nextThunder(after t: Double) -> Double? {
        guard !strikes.isEmpty, cycle > 0 else { return nil }
        let loops = max(0, (t / cycle).rounded(.down))
        for pass in 0...1 {
            let base = (loops + Double(pass)) * cycle
            for s in strikes {
                let at = base + s.time + thunderDelay(for: s)
                if at > t { return at }
            }
        }
        return nil
    }

    static func strike(at t: Double) -> Hit? {
        guard t >= 0 else { return nil }
        let local = t.truncatingRemainder(dividingBy: cycle)
        var current: Strike?
        for s in strikes {
            if s.time > local { break }
            current = s
        }
        guard let s = current else { return nil }
        let age = local - s.time
        return age < 1.5 ? Hit(strike: s, age: age) : nil
    }

    /// Brightness of the bolt and of the sky, 0…1. A strike is one flash, or
    /// two 0.14 s apart, then a fading afterglow in the clouds.
    static func envelope(age: Double, doubleFlash: Bool) -> (bolt: Double, sky: Double) {
        let first = exp(-age / 0.05)
        let second = (doubleFlash && age >= 0.14) ? 0.75 * exp(-(age - 0.14) / 0.07) : 0
        let bolt = max(first, second)
        let afterglow = 0.22 * exp(-age / 0.5)
        return (bolt, max(bolt, afterglow))
    }
}

// MARK: - Thunder

/// Plays `.thunderRumble` on the lightning timetable for as long as the task
/// that runs it lives — `AmbientStormView` cancels it when the storm stops.
@MainActor
private enum StormThunder {
    static func run(origin: Date) async {
        while !Task.isCancelled {
            let now = Date().timeIntervalSince(origin)
            guard let at = StormSchedule.nextThunder(after: now) else { return }
            try? await Task.sleep(for: .seconds(at - now))
            guard !Task.isCancelled else { return }
            SFXManager.shared.play(.thunderRumble)
        }
    }
}

// MARK: - Bolt geometry

private enum BoltShape {

    /// A jagged line from `a` to `b`, by midpoint displacement: every pass
    /// splits each segment and pushes the midpoint sideways, half as far as
    /// the pass before.
    static func points(from a: CGPoint, to b: CGPoint, roughness: Double, levels: Int,
                       rng: inout StormRandom) -> [CGPoint] {
        var pts = [a, b]
        let dx0 = Double(b.x - a.x)
        let dy0 = Double(b.y - a.y)
        var spread = (dx0 * dx0 + dy0 * dy0).squareRoot() * roughness
        for _ in 0..<levels {
            var next: [CGPoint] = [pts[0]]
            next.reserveCapacity(pts.count * 2)
            for i in 1..<pts.count {
                let p = pts[i - 1]
                let q = pts[i]
                let dx = Double(q.x - p.x)
                let dy = Double(q.y - p.y)
                let length = max((dx * dx + dy * dy).squareRoot(), 0.001)
                let shift = rng.range(-1, 1) * spread
                let midX = Double(p.x + q.x) / 2 - dy / length * shift
                let midY = Double(p.y + q.y) / 2 + dx / length * shift
                next.append(CGPoint(x: midX, y: midY))
                next.append(q)
            }
            pts = next
            spread *= 0.5
        }
        return pts
    }

    static func path(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        for p in pts.dropFirst() {
            path.addLine(to: p)
        }
        return path
    }
}

// MARK: - Seeded random

/// SplitMix64 — tiny, fast, and the same sequence on every device, so the
/// storm looks the same on every launch.
private struct StormRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// Uniform in [0, 1).
    mutating func unit() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    mutating func range(_ lo: Double, _ hi: Double) -> Double {
        lo + (hi - lo) * unit()
    }
}
