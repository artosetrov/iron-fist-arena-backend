import SwiftUI

// MARK: - Lantern Glow Points (positioned relative to terrain)

struct LanternGlowLayer: View {
    let terrainSize: CGSize

    // Lantern positions (relative 0…1 on terrain) — matched to image
    private let lanterns: [(x: CGFloat, y: CGFloat, color: Color, radius: CGFloat)] = [
        // Gate torches (large, warm)
        (0.385, 0.52, DarkFantasyTheme.glowFire, 25),
        (0.435, 0.52, DarkFantasyTheme.glowFire, 25),
        // Left wall lanterns
        (0.22, 0.55, DarkFantasyTheme.glowWarm, 14),
        (0.30, 0.48, DarkFantasyTheme.glowWarm, 12),
        // Right wall lanterns
        (0.55, 0.50, DarkFantasyTheme.glowWarm, 14),
        (0.62, 0.48, DarkFantasyTheme.glowWarm, 12),
        // Far right lanterns
        (0.75, 0.55, DarkFantasyTheme.glowWarm, 14),
        (0.82, 0.48, DarkFantasyTheme.glowWarm, 10),
        // Tavern area warm glow
        (0.65, 0.58, DarkFantasyTheme.glowEmber, 20),
        // Arena entrance lights
        (0.70, 0.35, DarkFantasyTheme.glowTreasure, 16),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<lanterns.count, id: \.self) { i in
                LanternGlow(
                    color: lanterns[i].color,
                    radius: lanterns[i].radius
                )
                .position(
                    x: lanterns[i].x * terrainSize.width,
                    y: lanterns[i].y * terrainSize.height
                )
            }
        }
        .frame(width: terrainSize.width, height: terrainSize.height)
        .allowsHitTesting(false)
    }
}

struct LanternGlow: View {
    let color: Color
    let radius: CGFloat
    @State private var pulse: CGFloat = 0.5
    @State private var isVisible = false

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color.opacity(pulse), color.opacity(pulse * 0.4), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: radius
                )
            )
            .frame(width: radius * 2.5, height: radius * 2.5)
            .blendMode(.screen)
            .onAppear {
                isVisible = true
                // Very slow breathing — 15-25 second full cycle
                withAnimation(
                    .easeInOut(duration: Double.random(in: 15.0...25.0))
                    .repeatForever(autoreverses: true)
                ) {
                    pulse = CGFloat.random(in: 0.4...0.6)
                }
            }
            .onDisappear {
                isVisible = false
                pulse = 0.5
            }
    }
}

// MARK: - Fog Layer (bottom, barely drifting)

struct FogLayer: View {
    let width: CGFloat
    let height: CGFloat
    @State private var drift: CGFloat = 0

    var body: some View {
        ZStack {
            fogStrip(opacity: 0.25, yOffset: 0, driftAmount: drift)
            fogStrip(opacity: 0.15, yOffset: -15, driftAmount: -drift * 0.6)
        }
        .frame(width: width, height: height * 0.25)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
        .onAppear {
            // Very slow drift: 120 seconds to sway 25px
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: true)) {
                drift = 25
            }
        }
        .onDisappear {
            drift = 0
        }
    }

    @ViewBuilder
    private func fogStrip(opacity: Double, yOffset: CGFloat, driftAmount: CGFloat) -> some View {
        LinearGradient(
            colors: [
                .clear,
                DarkFantasyTheme.fogLight.opacity(opacity),
                DarkFantasyTheme.fogMid.opacity(opacity * 1.5),
                DarkFantasyTheme.fogDark.opacity(opacity * 2),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .offset(x: driftAmount, y: yOffset)
    }
}

// MARK: - Cloud Layer (top, drifting slowly)

// MARK: - Wind Particles (barely perceptible atmospheric streaks)

struct WindParticlesLayer: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        // Low update rate — these move so slowly that 6fps is enough
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Glacial gust cycle (~10 min full period)
                let gustCycle = sin(time * 0.01) * 0.5 + 0.5
                let gustMultiplier = 0.2 + gustCycle * 0.4

                for i in 0..<15 {
                    let seed = Double(i) * 137.508
                    let baseSpeed = 0.8 + (seed.truncatingRemainder(dividingBy: 1.5))
                    let speed = baseSpeed * gustMultiplier
                    let yBase = (seed.truncatingRemainder(dividingBy: size.height))
                    let xProgress = ((time * speed + seed * 3).truncatingRemainder(dividingBy: (size.width + 120))) - 60

                    // Imperceptible wobble
                    let yWobble = sin(time * 0.015 + seed) * 3.0

                    let length: CGFloat = CGFloat(10 + (seed.truncatingRemainder(dividingBy: 16))) * CGFloat(0.7 + gustCycle * 0.4)
                    let alpha = (0.02 + (seed.truncatingRemainder(dividingBy: 0.03))) * (0.4 + gustCycle * 0.4)

                    var path = Path()
                    path.move(to: CGPoint(x: xProgress, y: yBase + yWobble))
                    path.addLine(to: CGPoint(x: xProgress + length, y: yBase + yWobble - 1))

                    context.stroke(
                        path,
                        with: .color(DarkFantasyTheme.textPrimary.opacity(alpha)),
                        lineWidth: 0.5
                    )
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

// MARK: - Falling Leaves / Embers (atmospheric depth particles)
//
// Two depth planes + embers. Everything moves GLACIALLY slow.
// A near leaf barely drifts — you have to stare to notice movement.
// Far leaves are subtle background texture.

struct FallingLeavesLayer: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        // Low update rate — slow particles don't need 20fps
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Glacial gust cycle (~10 min full period)
                let gustCycle = sin(time * 0.01) * 0.5 + 0.5
                let windDrift = 0.1 + gustCycle * 0.15

                drawFarLeaves(context: &context, size: size, time: time, windDrift: windDrift)
                drawEmbers(context: &context, size: size, time: time, windDrift: windDrift)
                drawNearLeaves(context: &context, size: size, time: time, windDrift: windDrift, gustCycle: gustCycle)
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    // MARK: - Far leaves (10 pcs, 4–8px)

    private func drawFarLeaves(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double,
        windDrift: Double
    ) {
        for i in 0..<10 {
            let seed = Double(i) * 137.508

            // ~0.04 px/s fall — takes ~3 hours to cross screen
            let fallSpeed = 0.03 + seed.truncatingRemainder(dividingBy: 0.03)
            let yProgress = (time * fallSpeed + seed * 5).truncatingRemainder(dividingBy: Double(size.height + 80)) - 40

            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
            // Full S-curve wave ~10-13 minutes
            let curve1 = sin(time * 0.0016 + seed * 0.4) * 14.0
            let curve2 = sin(time * 0.0025 + seed * 0.9) * 7.0
            let xWind = (time * windDrift * 0.003 + seed).truncatingRemainder(dividingBy: Double(size.width))
            let xPos = (xBase + curve1 + curve2 + xWind).truncatingRemainder(dividingBy: Double(size.width))

            // ~1 full turn per 100 minutes
            let rotation = Angle.degrees(time * 0.006 + seed * 20).radians

            let yNorm = yProgress / Double(size.height)
            let alpha = min(yNorm * 4.0, 1.0) * min((1.0 - yNorm) * 3.0, 1.0) * 0.15

            let leafW: CGFloat = CGFloat(4.0 + seed.truncatingRemainder(dividingBy: 4.0))
            let leafH = leafW * 0.45

            let leafColor: Color = (i % 3 == 0)
                ? DarkFantasyTheme.goldDim
                : (i % 3 == 1) ? DarkFantasyTheme.borderOrnament : DarkFantasyTheme.gold.opacity(0.5)

            context.drawLayer { ctx in
                ctx.translateBy(x: xPos, y: yProgress)
                ctx.rotate(by: Angle(radians: rotation))
                ctx.fill(
                    Ellipse().path(in: CGRect(x: -Double(leafW / 2), y: -Double(leafH / 2), width: Double(leafW), height: Double(leafH))),
                    with: .color(leafColor.opacity(alpha))
                )
            }
        }
    }

    // MARK: - Near leaves (3 pcs, 16–28px, swirl trajectory, size breathes)

    private func drawNearLeaves(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double,
        windDrift: Double,
        gustCycle: Double
    ) {
        for i in 0..<3 {
            let seed = (Double(i) + 3000) * 137.508

            // 0.01 px/s — a near leaf takes ~8+ HOURS to cross the screen
            let fallSpeed = 0.008 + seed.truncatingRemainder(dividingBy: 0.008)
            let yProgress = (time * fallSpeed + seed * 3).truncatingRemainder(dividingBy: Double(size.height + 100)) - 50

            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))

            // Primary wind curve — full wave ~25 minutes
            let windCurve = sin(time * 0.0007 + seed * 0.5) * 50.0

            // Swirl — full wave ~15 minutes
            let swirlX = sin(time * 0.0011 + seed * 0.7) * 25.0
            let swirlY = cos(time * 0.0018 + seed * 0.7) * 16.0

            // Micro-turbulence — full wave ~4 minutes, very subtle
            let turbX = sin(time * 0.004 + seed * 2.1) * (1.5 + gustCycle * 2.0)
            let turbY = cos(time * 0.003 + seed * 1.7) * 1.0

            let xWind = (time * windDrift * 0.002 + seed).truncatingRemainder(dividingBy: Double(size.width))
            let xPos = (xBase + windCurve + swirlX + turbX + xWind).truncatingRemainder(dividingBy: Double(size.width))
            let yOffset = swirlY + turbY

            // ~1 full turn per 100 minutes
            let tumble = time * 0.006 + seed * 20
            // Very slow wobble (~10 min cycle)
            let wobble = sin(time * 0.0017 + seed) * 35.0
            let rotation = Angle.degrees(tumble + wobble).radians

            // Size breathes — cycle ~15 minutes
            let depthPulse = sin(time * 0.0011 + seed * 1.3)
            let baseSize: CGFloat = CGFloat(16.0 + seed.truncatingRemainder(dividingBy: 12.0))
            let scaleFactor = CGFloat(1.0 + depthPulse * 0.3) // 0.7…1.3
            let leafW = baseSize * scaleFactor
            let leafH = leafW * 0.45

            // Alpha tracks depth
            let yNorm = (yProgress + yOffset) / Double(size.height)
            let fadeIn = min(yNorm * 2.5, 1.0)
            let fadeOut = min((1.0 - yNorm) * 1.5, 1.0)
            let depthAlpha = 0.35 + depthPulse * 0.15
            let alpha = fadeIn * fadeOut * depthAlpha

            let leafColor: Color = (i == 0)
                ? DarkFantasyTheme.goldDim
                : (i == 1) ? DarkFantasyTheme.borderOrnament : DarkFantasyTheme.gold.opacity(0.7)

            context.drawLayer { ctx in
                ctx.translateBy(x: xPos, y: yProgress + yOffset)
                ctx.rotate(by: Angle(radians: rotation))
                ctx.fill(
                    Ellipse().path(in: CGRect(x: -Double(leafW / 2), y: -Double(leafH / 2), width: Double(leafW), height: Double(leafH))),
                    with: .color(leafColor.opacity(alpha))
                )
            }
        }
    }

    // MARK: - Embers (4 pcs, barely drifting upward)

    private func drawEmbers(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double,
        windDrift: Double
    ) {
        for i in 0..<4 {
            let seed = (Double(i) + 5000) * 137.508

            // Almost frozen: 0.015–0.03 px/s
            let riseSpeed = 0.015 + seed.truncatingRemainder(dividingBy: 0.015)
            let yProgress = Double(size.height) - (time * riseSpeed + seed * 4).truncatingRemainder(dividingBy: Double(size.height + 60))

            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
            let xSwirl = sin(time * 0.0015 + seed * 0.7) * 18.0
            let xWind = (time * windDrift * 0.001 + seed).truncatingRemainder(dividingBy: Double(size.width))
            let xPos = (xBase + xSwirl + xWind).truncatingRemainder(dividingBy: Double(size.width))

            let yNorm = yProgress / Double(size.height)
            let alpha = min((1.0 - yNorm) * 3.0, 1.0) * min(yNorm * 4.0, 1.0)

            // Very slow pulse (~2 min full cycle)
            let glowPulse = sin(time * 0.009 + seed) * 0.3 + 0.7
            let emberSize: CGFloat = CGFloat(3.0 + seed.truncatingRemainder(dividingBy: 3.5))

            // Glow halo
            context.fill(
                Circle().path(in: CGRect(
                    x: xPos - Double(emberSize * 3), y: yProgress - Double(emberSize * 3),
                    width: Double(emberSize * 6), height: Double(emberSize * 6)
                )),
                with: .color(DarkFantasyTheme.glowEmber.opacity(alpha * glowPulse * 0.1))
            )
            // Core
            context.fill(
                Circle().path(in: CGRect(
                    x: xPos - Double(emberSize / 2), y: yProgress - Double(emberSize / 2),
                    width: Double(emberSize), height: Double(emberSize)
                )),
                with: .color(DarkFantasyTheme.glowFire.opacity(alpha * glowPulse * 0.45))
            )
        }
    }
}

// MARK: - Chimney Smoke (rising wisps — glacially slow)

struct ChimneySmokeLayer: View {
    let terrainSize: CGSize

    private let chimneys: [(x: CGFloat, y: CGFloat)] = [
        (0.275, 0.38),   // Tavern
        (0.645, 0.30),   // Forge / Blacksmith
        (0.475, 0.33),   // Guild Hall
    ]

    private let particlesPerChimney = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for (ci, chimney) in chimneys.enumerated() {
                    let baseX = Double(chimney.x) * Double(size.width)
                    let baseY = Double(chimney.y) * Double(size.height)

                    for i in 0..<particlesPerChimney {
                        let seed = Double(ci * 10 + i) * 137.508

                        // Very slow rise: 0.1-0.25 px/s
                        let riseSpeed = 0.1 + seed.truncatingRemainder(dividingBy: 0.15)
                        let maxRise: Double = 55.0 + seed.truncatingRemainder(dividingBy: 30.0)
                        let cycleTime = maxRise / riseSpeed
                        let phase = (time + seed * 0.7).truncatingRemainder(dividingBy: cycleTime)
                        let progress = phase / cycleTime // 0…1

                        let yOffset = -progress * maxRise
                        // Almost imperceptible horizontal drift
                        let xDrift = sin(time * 0.003 + seed) * 4.0 + progress * 2.0

                        let smokeSize = CGFloat(4.0 + progress * 8.0)
                        let alpha = (1.0 - progress * progress) * 0.10

                        let rect = CGRect(
                            x: baseX + xDrift - Double(smokeSize / 2),
                            y: baseY + yOffset - Double(smokeSize / 2),
                            width: Double(smokeSize),
                            height: Double(smokeSize)
                        )
                        context.fill(
                            Circle().path(in: rect),
                            with: .color(DarkFantasyTheme.fogLight.opacity(alpha))
                        )
                    }
                }
            }
        }
        .frame(width: terrainSize.width, height: terrainSize.height)
        .allowsHitTesting(false)
    }
}

// MARK: - Storm Effect (periodic rain + lightning, ~30s burst every ~2 min)
//
// Lifecycle:  idle 90-150s → ramp-in 3s → full storm 24s → ramp-out 3s → idle
// Rain:       Canvas-drawn diagonal streaks, ~80 drops
// Lightning:  2-3 quick white flashes (opacity overlay) with terrain brightening
// Performance: Canvas at 20fps during storm, 0fps during idle (no timeline tick)

struct StormEffectLayer: View {
    let width: CGFloat
    let height: CGFloat

    // Storm state machine
    @State private var stormActive = false
    @State private var stormOpacity: Double = 0       // master opacity for entire effect
    @State private var lightningFlash: Double = 0     // 0…1 flash intensity
    @State private var stormStartTime: Date = .now

    // Timers
    @State private var idleTimer: Timer?
    @State private var lightningTask: Task<Void, Never>?

    // Storm timing constants
    private let idleMin: Double = 90     // minimum seconds between storms
    private let idleMax: Double = 150    // maximum seconds between storms
    private let stormDuration: Double = 24
    private let rampDuration: Double = 3

    var body: some View {
        ZStack {
            // Lightning flash overlay — full-screen white burst
            if lightningFlash > 0 {
                Color.white
                    .opacity(lightningFlash * 0.12)
                    .blendMode(.screen)
            }

            // Rain particles — only rendered during storm
            if stormActive {
                TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                    Canvas { context, size in
                        let time = timeline.date.timeIntervalSince(stormStartTime)
                        drawRain(context: &context, size: size, time: time)
                    }
                }
                .opacity(stormOpacity)
            }

            // Terrain brightness boost during lightning
            if lightningFlash > 0 {
                Color.white
                    .opacity(lightningFlash * 0.06)
                    .blendMode(.softLight)
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
        .onAppear { scheduleNextStorm() }
        .onDisappear { cleanup() }
    }

    // MARK: - Rain Rendering (3-layer depth system)

    private func drawRain(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double
    ) {
        let flashBoost = 1.0 + lightningFlash * 2.0

        // === Far rain (background mist — many tiny faint drops) ===
        for i in 0..<50 {
            let seed = Double(i) * 53.71
            let speed = 140.0 + seed.truncatingRemainder(dividingBy: 80.0)
            let windX = 20.0
            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
            let xOff = (time * windX + seed * 2.3).truncatingRemainder(dividingBy: Double(size.width + 60))
            let x = (xBase + xOff).truncatingRemainder(dividingBy: Double(size.width))
            let y = (time * speed + seed * 31.0).truncatingRemainder(dividingBy: Double(size.height + 20)) - 10
            let length = 4.0 + seed.truncatingRemainder(dividingBy: 5.0)
            let alpha = (0.03 + seed.truncatingRemainder(dividingBy: 0.04)) * flashBoost

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + windX * length / speed, y: y + length))
            context.stroke(path, with: .color(DarkFantasyTheme.textSecondary.opacity(alpha)), lineWidth: 0.4)
        }

        // === Mid rain (main visible layer — varied drops) ===
        for i in 0..<60 {
            let seed = Double(i) * 73.137
            let speed = 300.0 + seed.truncatingRemainder(dividingBy: 200.0)
            let windX = 50.0 + sin(time * 0.3 + seed) * 12.0 // wind gusts

            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
            let xOff = (time * windX + seed * 3.7).truncatingRemainder(dividingBy: Double(size.width + 120))
            let x = (xBase + xOff).truncatingRemainder(dividingBy: Double(size.width))
            let y = (time * speed + seed * 47.3).truncatingRemainder(dividingBy: Double(size.height + 40)) - 20

            let length = 10.0 + seed.truncatingRemainder(dividingBy: 14.0)
            let alpha = (0.06 + seed.truncatingRemainder(dividingBy: 0.08)) * flashBoost

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + windX * length / speed, y: y + length))
            context.stroke(path, with: .color(DarkFantasyTheme.textPrimary.opacity(alpha)), lineWidth: 0.7)

            // Splash at bottom — tiny expanding circle when drop "hits ground"
            let splashZone = Double(size.height) * 0.85
            if y > splashZone {
                let splashProgress = (y - splashZone) / (Double(size.height) - splashZone)
                let splashRadius = 1.5 + splashProgress * 2.5
                let splashAlpha = (1.0 - splashProgress) * 0.06 * flashBoost
                context.fill(
                    Circle().path(in: CGRect(
                        x: x - splashRadius, y: y + length - splashRadius,
                        width: splashRadius * 2, height: splashRadius * 2
                    )),
                    with: .color(DarkFantasyTheme.textPrimary.opacity(splashAlpha))
                )
            }
        }

        // === Near rain (foreground — few big bright streaks for depth) ===
        for i in 0..<8 {
            let seed = Double(i) * 197.53
            let speed = 500.0 + seed.truncatingRemainder(dividingBy: 150.0)
            let windX = 65.0

            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
            let xOff = (time * windX + seed * 5.1).truncatingRemainder(dividingBy: Double(size.width + 200))
            let x = (xBase + xOff).truncatingRemainder(dividingBy: Double(size.width))
            let y = (time * speed + seed * 61.0).truncatingRemainder(dividingBy: Double(size.height + 60)) - 30

            let length = 20.0 + seed.truncatingRemainder(dividingBy: 12.0)
            let alpha = (0.10 + seed.truncatingRemainder(dividingBy: 0.06)) * flashBoost

            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + windX * length / speed, y: y + length))
            context.stroke(path, with: .color(DarkFantasyTheme.textPrimary.opacity(alpha)), lineWidth: 1.2)
        }
    }

    // MARK: - Storm Lifecycle

    private func scheduleNextStorm() {
        let delay = Double.random(in: idleMin...idleMax)
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            Task { @MainActor in
                startStorm()
            }
        }
    }

    private func startStorm() {
        stormStartTime = .now
        stormActive = true

        // Play ambient rain loop for the storm duration
        SFXManager.shared.play(.rainAmbient)

        // Ramp in
        withAnimation(.easeIn(duration: rampDuration)) {
            stormOpacity = 1.0
        }

        // Schedule lightning strikes
        lightningTask?.cancel()
        lightningTask = Task { @MainActor in
            // 2-3 lightning strikes during the storm
            let strikeCount = Int.random(in: 2...3)
            for s in 0..<strikeCount {
                // Spread strikes across the storm duration
                let strikeDelay = rampDuration + Double(s) * (stormDuration / Double(strikeCount)) + Double.random(in: 0...3)
                try? await Task.sleep(for: .seconds(strikeDelay))
                if Task.isCancelled { return }
                await fireLightning()
            }
        }

        // Schedule ramp out → idle
        DispatchQueue.main.asyncAfter(deadline: .now() + rampDuration + stormDuration) {
            withAnimation(.easeOut(duration: rampDuration)) {
                stormOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + rampDuration) {
                stormActive = false
                scheduleNextStorm()
            }
        }
    }

    /// Fire a single lightning strike — 2-3 rapid flashes + thunder SFX
    @MainActor
    private func fireLightning() async {
        // Play thunder rumble SFX with the flash
        SFXManager.shared.play(.thunderRumble)

        let subFlashes = Int.random(in: 2...3)
        for f in 0..<subFlashes {
            // Flash ON — instant
            withAnimation(.easeIn(duration: 0.05)) {
                lightningFlash = f == 0 ? 1.0 : Double.random(in: 0.4...0.7)
            }
            try? await Task.sleep(for: .milliseconds(Int.random(in: 60...120)))
            // Flash OFF — quick fade
            withAnimation(.easeOut(duration: 0.15)) {
                lightningFlash = 0
            }
            if f < subFlashes - 1 {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 80...200)))
            }
        }
    }

    private func cleanup() {
        idleTimer?.invalidate()
        idleTimer = nil
        lightningTask?.cancel()
        lightningTask = nil
        stormActive = false
        stormOpacity = 0
        lightningFlash = 0
    }
}

// MARK: - Color(hex:) extension (if not already defined)

// Already defined in DarkFantasyTheme — using that
