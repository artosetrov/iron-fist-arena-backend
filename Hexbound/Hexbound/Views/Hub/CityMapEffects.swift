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
    @State private var pulse: CGFloat = 0.6
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
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.5...3.0))
                    .repeatForever(autoreverses: true)
                ) {
                    pulse = CGFloat.random(in: 0.35...0.8)
                }
            }
            .onDisappear {
                isVisible = false
                // Reset to static value to stop animation driver
                pulse = 0.6
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

// MARK: - Wind Particles (with gust dynamics)

struct WindParticlesLayer: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Gust cycle: wind speed oscillates between calm and strong
                let gustCycle = sin(time * 0.3) * 0.5 + 0.5 // 0…1 over ~21s
                let gustMultiplier = 0.6 + gustCycle * 0.8   // 0.6…1.4x speed

                for i in 0..<25 {
                    let seed = Double(i) * 137.508
                    let baseSpeed = 30.0 + (seed.truncatingRemainder(dividingBy: 45))
                    let speed = baseSpeed * gustMultiplier
                    let yBase = (seed.truncatingRemainder(dividingBy: size.height))
                    let xProgress = ((time * speed + seed * 3).truncatingRemainder(dividingBy: (size.width + 120))) - 60

                    // Wobble affected by gusts — stronger wind = less wobble
                    let wobbleAmp = 8.0 * (1.3 - gustCycle * 0.5)
                    let yWobble = sin(time * 2.2 + seed) * wobbleAmp

                    // Longer streaks during gusts
                    let length: CGFloat = CGFloat(8 + (seed.truncatingRemainder(dividingBy: 14))) * CGFloat(0.8 + gustCycle * 0.5)
                    let alpha = (0.05 + (seed.truncatingRemainder(dividingBy: 0.09))) * (0.7 + gustCycle * 0.5)

                    var path = Path()
                    path.move(to: CGPoint(x: xProgress, y: yBase + yWobble))
                    path.addLine(to: CGPoint(x: xProgress + length, y: yBase + yWobble - 2))

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

// MARK: - Falling Leaves / Embers (ambient atmospheric particles)

struct FallingLeavesLayer: View {
    let width: CGFloat
    let height: CGFloat

    private let particleCount = 18

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                // Shared gust factor (matches wind layer)
                let gustCycle = sin(time * 0.3) * 0.5 + 0.5
                let windDrift = 15.0 + gustCycle * 25.0 // horizontal drift speed

                for i in 0..<particleCount {
                    let seed = Double(i) * 137.508
                    let isEmber = i % 3 == 0 // every 3rd particle is a glowing ember

                    // Vertical fall: 12-30 px/s (leaves slower, embers faster)
                    let fallSpeed = isEmber ? (20.0 + seed.truncatingRemainder(dividingBy: 15)) : (12.0 + seed.truncatingRemainder(dividingBy: 12))

                    // Y position loops over height
                    let yProgress = (time * fallSpeed + seed * 7).truncatingRemainder(dividingBy: Double(size.height + 40)) - 20

                    // X: base position + wind drift + sinusoidal sway
                    let xBase = seed.truncatingRemainder(dividingBy: Double(size.width))
                    let swayAmp = isEmber ? 6.0 : 15.0
                    let swayFreq = isEmber ? 1.8 : 0.8
                    let xSway = sin(time * swayFreq + seed * 0.5) * swayAmp
                    let xDrift = (time * windDrift * (isEmber ? 0.4 : 0.25) + seed * 2).truncatingRemainder(dividingBy: Double(size.width))
                    let xPos = (xBase + xSway + xDrift).truncatingRemainder(dividingBy: Double(size.width))

                    // Rotation (leaves tumble, embers don't)
                    let rotation = isEmber ? 0 : Angle.degrees(time * 40 + seed * 20).radians

                    // Fade based on y position (fade in at top, fade out near bottom)
                    let yNorm = yProgress / Double(size.height)
                    let fadeIn = min(yNorm * 5.0, 1.0)
                    let fadeOut = min((1.0 - yNorm) * 3.0, 1.0)
                    let alpha = fadeIn * fadeOut

                    if isEmber {
                        // Glowing ember: small circle with warm color
                        let glowPulse = sin(time * 3.0 + seed) * 0.3 + 0.7
                        let emberSize: CGFloat = CGFloat(2.0 + seed.truncatingRemainder(dividingBy: 2.5))

                        // Glow halo
                        let glowRect = CGRect(
                            x: xPos - Double(emberSize * 2),
                            y: yProgress - Double(emberSize * 2),
                            width: Double(emberSize * 4),
                            height: Double(emberSize * 4)
                        )
                        context.fill(
                            Circle().path(in: glowRect),
                            with: .color(DarkFantasyTheme.glowEmber.opacity(alpha * glowPulse * 0.15))
                        )

                        // Core
                        let coreRect = CGRect(
                            x: xPos - Double(emberSize / 2),
                            y: yProgress - Double(emberSize / 2),
                            width: Double(emberSize),
                            height: Double(emberSize)
                        )
                        context.fill(
                            Circle().path(in: coreRect),
                            with: .color(DarkFantasyTheme.glowFire.opacity(alpha * glowPulse * 0.6))
                        )
                    } else {
                        // Leaf: small rotated ellipse in muted autumnal tones
                        let leafW: CGFloat = CGFloat(4.0 + seed.truncatingRemainder(dividingBy: 5.0))
                        let leafH: CGFloat = leafW * 0.5

                        context.drawLayer { ctx in
                            let center = CGPoint(x: xPos, y: yProgress)
                            ctx.translateBy(x: center.x, y: center.y)
                            ctx.rotate(by: Angle(radians: rotation))

                            let leafRect = CGRect(x: -Double(leafW / 2), y: -Double(leafH / 2), width: Double(leafW), height: Double(leafH))
                            // Alternate leaf colors based on seed
                            let leafColor: Color = (i % 2 == 0)
                                ? DarkFantasyTheme.goldDim
                                : DarkFantasyTheme.borderOrnament
                            ctx.fill(
                                Ellipse().path(in: leafRect),
                                with: .color(leafColor.opacity(alpha * 0.35))
                            )
                        }
                    }
                }
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

// MARK: - Chimney Smoke (rising wisps from building positions)

struct ChimneySmokeLayer: View {
    let terrainSize: CGSize

    // Chimney positions (relative to terrain) — aligned with buildings that have chimneys
    private let chimneys: [(x: CGFloat, y: CGFloat)] = [
        (0.275, 0.38),   // Tavern
        (0.645, 0.30),   // Forge / Blacksmith
        (0.475, 0.33),   // Guild Hall
    ]

    private let particlesPerChimney = 6

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.06)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for (ci, chimney) in chimneys.enumerated() {
                    let baseX = Double(chimney.x) * Double(size.width)
                    let baseY = Double(chimney.y) * Double(size.height)

                    for i in 0..<particlesPerChimney {
                        let seed = Double(ci * 10 + i) * 137.508

                        // Rise speed: 8-16 px/s
                        let riseSpeed = 8.0 + seed.truncatingRemainder(dividingBy: 8.0)
                        // Lifecycle: each particle rises then fades over ~60px
                        let maxRise: Double = 45.0 + seed.truncatingRemainder(dividingBy: 25.0)
                        let cycleTime = maxRise / riseSpeed
                        let phase = (time + seed * 0.7).truncatingRemainder(dividingBy: cycleTime)
                        let progress = phase / cycleTime // 0…1

                        let yOffset = -progress * maxRise
                        // Horizontal drift: slight wind push
                        let xDrift = sin(time * 0.5 + seed) * 4.0 + progress * 6.0

                        // Size grows as smoke expands
                        let smokeSize = CGFloat(3.0 + progress * 6.0)
                        // Fade: start visible, fade out as rises
                        let alpha = (1.0 - progress) * 0.12

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
