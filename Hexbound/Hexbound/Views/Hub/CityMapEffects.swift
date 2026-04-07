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
    @State private var pulse: CGFloat = 0.55
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
                // Slow, gentle breathing — like a real flame (~6-10s cycle)
                withAnimation(
                    .easeInOut(duration: Double.random(in: 6.0...10.0))
                    .repeatForever(autoreverses: true)
                ) {
                    pulse = CGFloat.random(in: 0.4...0.7)
                }
            }
            .onDisappear {
                isVisible = false
                pulse = 0.55
            }
    }
}

// MARK: - Fog Layer (bottom, drifting)

struct FogLayer: View {
    let width: CGFloat
    let height: CGFloat
    @State private var drift: CGFloat = 0

    var body: some View {
        ZStack {
            // Two fog strips that drift in opposite directions
            fogStrip(opacity: 0.25, yOffset: 0, driftAmount: drift)
            fogStrip(opacity: 0.15, yOffset: -15, driftAmount: -drift * 0.6)
        }
        .frame(width: width, height: height * 0.25)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
                drift = 40
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

// MARK: - Wind Particles (slow, atmospheric gusts)

struct WindParticlesLayer: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Glacial gust cycle (~5 min, matches leaves)
                let gustCycle = sin(time * 0.02) * 0.5 + 0.5
                let gustMultiplier = 0.3 + gustCycle * 0.5

                for i in 0..<20 {
                    let seed = Double(i) * 137.508
                    let baseSpeed = 3.0 + (seed.truncatingRemainder(dividingBy: 5))
                    let speed = baseSpeed * gustMultiplier
                    let yBase = (seed.truncatingRemainder(dividingBy: size.height))
                    let xProgress = ((time * speed + seed * 3).truncatingRemainder(dividingBy: (size.width + 120))) - 60

                    // Very gentle wobble
                    let wobbleAmp = 4.0 * (1.1 - gustCycle * 0.3)
                    let yWobble = sin(time * 0.08 + seed) * wobbleAmp

                    let length: CGFloat = CGFloat(8 + (seed.truncatingRemainder(dividingBy: 14))) * CGFloat(0.7 + gustCycle * 0.5)
                    let alpha = (0.03 + (seed.truncatingRemainder(dividingBy: 0.05))) * (0.5 + gustCycle * 0.5)

                    var path = Path()
                    path.move(to: CGPoint(x: xProgress, y: yBase + yWobble))
                    path.addLine(to: CGPoint(x: xProgress + length, y: yBase + yWobble - 1.5))

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
// Two depth planes + embers:
//   far  — many small leaves, subtle, gentle curves
//   near — few large leaves, bright, slow wind-swirl trajectory, size changes mid-flight
//
// Every leaf follows a wind-swirl path (Lissajous-like curves)
// and changes scale during flight to simulate depth shifting.

struct FallingLeavesLayer: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Glacially slow gust cycle (~5 minutes full period)
                let gustCycle = sin(time * 0.02) * 0.5 + 0.5
                let windDrift = 0.3 + gustCycle * 0.5

                drawFarLeaves(context: &context, size: size, time: time, windDrift: windDrift)
                drawEmbers(context: &context, size: size, time: time, windDrift: windDrift)
                drawNearLeaves(context: &context, size: size, time: time, windDrift: windDrift, gustCycle: gustCycle)
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    // MARK: - Far leaves (10 pcs, 4–8px, background dust)

    private func drawFarLeaves(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double,
        windDrift: Double
    ) {
        for i in 0..<10 {
            let seed = Double(i) * 137.508

            // Extremely slow fall: 0.15–0.3 px/s (~20-45 min to cross screen)
            let fallSpeed = 0.15 + seed.truncatingRemainder(dividingBy: 0.15)
            let yProgress = (time * fallSpeed + seed * 5).truncatingRemainder(dividingBy: Double(size.height + 80)) - 40

            // Very gentle S-curve (full wave ~3-5 min)
            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
            let curve1 = sin(time * 0.008 + seed * 0.4) * 12.0
            let curve2 = sin(time * 0.013 + seed * 0.9) * 6.0
            let xWind = (time * windDrift * 0.01 + seed).truncatingRemainder(dividingBy: Double(size.width))
            let xPos = (xBase + curve1 + curve2 + xWind).truncatingRemainder(dividingBy: Double(size.width))

            // Barely rotating (~1 full turn per 10 min)
            let rotation = Angle.degrees(time * 0.06 + seed * 20).radians

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

    // MARK: - Near leaves (3 pcs, 16–28px, wind-swirl, size breathes)

    private func drawNearLeaves(
        context: inout GraphicsContext,
        size: CGSize,
        time: Double,
        windDrift: Double,
        gustCycle: Double
    ) {
        for i in 0..<3 {
            let seed = (Double(i) + 3000) * 137.508

            // Glacially slow fall: 0.05–0.1 px/s (a near leaf takes ~1-2 HOURS to cross)
            let fallSpeed = 0.05 + seed.truncatingRemainder(dividingBy: 0.05)
            let yProgress = (time * fallSpeed + seed * 3).truncatingRemainder(dividingBy: Double(size.height + 100)) - 50

            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))

            // Primary wind curve — full wave ~4 minutes
            let windCurve = sin(time * 0.004 + seed * 0.5) * 45.0

            // Swirl overlay — full wave ~2.5 minutes (golden ratio offset)
            let swirlX = sin(time * 0.007 + seed * 0.7) * 20.0
            let swirlY = cos(time * 0.011 + seed * 0.7) * 14.0

            // Micro-turbulence — very subtle, full wave ~40s
            let turbX = sin(time * 0.025 + seed * 2.1) * (2.0 + gustCycle * 3.0)
            let turbY = cos(time * 0.02 + seed * 1.7) * 1.5

            let xWind = (time * windDrift * 0.01 + seed).truncatingRemainder(dividingBy: Double(size.width))
            let xPos = (xBase + windCurve + swirlX + turbX + xWind).truncatingRemainder(dividingBy: Double(size.width))
            let yOffset = swirlY + turbY

            // Barely tumbling: ~1 full turn per 6 minutes
            let tumble = time * 0.06 + seed * 20
            // Very slow wobble (~90s cycle)
            let wobble = sin(time * 0.011 + seed) * 30.0
            let rotation = Angle.degrees(tumble + wobble).radians

            // === SIZE BREATHES — cycle ~2.5 minutes ===
            let depthPulse = sin(time * 0.007 + seed * 1.3)
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

            // Almost hovering: 0.08–0.15 px/s
            let riseSpeed = 0.08 + seed.truncatingRemainder(dividingBy: 0.07)
            let yProgress = Double(size.height) - (time * riseSpeed + seed * 4).truncatingRemainder(dividingBy: Double(size.height + 60))

            let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
            let xSwirl = sin(time * 0.009 + seed * 0.7) * 16.0
            let xWind = (time * windDrift * 0.008 + seed).truncatingRemainder(dividingBy: Double(size.width))
            let xPos = (xBase + xSwirl + xWind).truncatingRemainder(dividingBy: Double(size.width))

            let yNorm = yProgress / Double(size.height)
            let alpha = min((1.0 - yNorm) * 3.0, 1.0) * min(yNorm * 4.0, 1.0)

            // Very slow pulse (~0.06 Hz, full cycle ~16s)
            let glowPulse = sin(time * 0.06 + seed) * 0.3 + 0.7
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

// MARK: - Chimney Smoke (rising wisps — slow, dreamy)

struct ChimneySmokeLayer: View {
    let terrainSize: CGSize

    private let chimneys: [(x: CGFloat, y: CGFloat)] = [
        (0.275, 0.38),   // Tavern
        (0.645, 0.30),   // Forge / Blacksmith
        (0.475, 0.33),   // Guild Hall
    ]

    private let particlesPerChimney = 5

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for (ci, chimney) in chimneys.enumerated() {
                    let baseX = Double(chimney.x) * Double(size.width)
                    let baseY = Double(chimney.y) * Double(size.height)

                    for i in 0..<particlesPerChimney {
                        let seed = Double(ci * 10 + i) * 137.508

                        // Barely rising: 0.4-1.0 px/s
                        let riseSpeed = 0.4 + seed.truncatingRemainder(dividingBy: 0.6)
                        let maxRise: Double = 55.0 + seed.truncatingRemainder(dividingBy: 30.0)
                        let cycleTime = maxRise / riseSpeed
                        let phase = (time + seed * 0.7).truncatingRemainder(dividingBy: cycleTime)
                        let progress = phase / cycleTime // 0…1

                        let yOffset = -progress * maxRise
                        // Very gentle horizontal drift
                        let xDrift = sin(time * 0.02 + seed) * 5.0 + progress * 3.0

                        // Size grows as smoke expands
                        let smokeSize = CGFloat(4.0 + progress * 8.0)
                        // Smooth fade out
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

// MARK: - Color(hex:) extension (if not already defined)

// Already defined in DarkFantasyTheme — using that
