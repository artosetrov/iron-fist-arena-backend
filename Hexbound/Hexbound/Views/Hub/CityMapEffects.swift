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

// MARK: - Wind Particles

struct WindParticlesLayer: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for i in 0..<20 {
                    let seed = Double(i) * 137.5
                    let speed = 30.0 + (seed.truncatingRemainder(dividingBy: 40))
                    let yBase = (seed.truncatingRemainder(dividingBy: size.height))
                    let xProgress = ((time * speed + seed * 3).truncatingRemainder(dividingBy: (size.width + 100))) - 50
                    let yWobble = sin(time * 2 + seed) * 8

                    let length: CGFloat = CGFloat(8 + (seed.truncatingRemainder(dividingBy: 12)))
                    let alpha = 0.06 + (seed.truncatingRemainder(dividingBy: 0.08))

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

// MARK: - Color(hex:) extension (if not already defined)

// Already defined in DarkFantasyTheme — using that
