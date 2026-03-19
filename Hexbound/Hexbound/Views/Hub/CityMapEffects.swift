import SwiftUI

// MARK: - Lantern Glow Points (positioned relative to terrain)

struct LanternGlowLayer: View {
    let terrainSize: CGSize

    // Lantern positions (relative 0…1 on terrain) — matched to image
    private let lanterns: [(x: CGFloat, y: CGFloat, color: Color, radius: CGFloat)] = [
        // Gate torches (large, warm)
        (0.385, 0.52, Color(hex: 0xFF6600), 25),
        (0.435, 0.52, Color(hex: 0xFF6600), 25),
        // Left wall lanterns
        (0.22, 0.55, Color(hex: 0xFFAA33), 14),
        (0.30, 0.48, Color(hex: 0xFFAA33), 12),
        // Right wall lanterns
        (0.55, 0.50, Color(hex: 0xFFAA33), 14),
        (0.62, 0.48, Color(hex: 0xFFAA33), 12),
        // Far right lanterns
        (0.75, 0.55, Color(hex: 0xFFAA33), 14),
        (0.82, 0.48, Color(hex: 0xFFAA33), 10),
        // Tavern area warm glow
        (0.65, 0.58, Color(hex: 0xFF8833), 20),
        // Arena entrance lights
        (0.70, 0.35, Color(hex: 0xFFCC44), 16),
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
                withAnimation(
                    .easeInOut(duration: Double.random(in: 1.5...3.0))
                    .repeatForever(autoreverses: true)
                ) {
                    pulse = CGFloat.random(in: 0.35...0.8)
                }
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
    }

    @ViewBuilder
    private func fogStrip(opacity: Double, yOffset: CGFloat, driftAmount: CGFloat) -> some View {
        LinearGradient(
            colors: [
                .clear,
                Color(hex: 0x2A2A3A).opacity(opacity),
                Color(hex: 0x1A1A2A).opacity(opacity * 1.5),
                Color(hex: 0x0A0A15).opacity(opacity * 2),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .offset(x: driftAmount, y: yOffset)
    }
}

// MARK: - Cloud Layer (top, drifting slowly)

struct CloudLayer: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            DriftingCloud(relX: 0.15, relY: 0.05, cloudWidth: 120, opacity: 0.12, speed: 35)
            DriftingCloud(relX: 0.45, relY: 0.08, cloudWidth: 180, opacity: 0.08, speed: 50)
            DriftingCloud(relX: 0.75, relY: 0.03, cloudWidth: 140, opacity: 0.10, speed: 40)
            DriftingCloud(relX: 0.30, relY: 0.12, cloudWidth: 100, opacity: 0.06, speed: 60)
            DriftingCloud(relX: 0.85, relY: 0.10, cloudWidth: 160, opacity: 0.09, speed: 45)
        }
        .frame(width: width, height: height * 0.25)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }
}

struct DriftingCloud: View {
    let relX: CGFloat
    let relY: CGFloat
    let cloudWidth: CGFloat
    let opacity: Double
    let speed: Double
    @State private var drift: CGFloat = 0

    var body: some View {
        Ellipse()
            .fill(Color.gray.opacity(opacity))
            .frame(width: cloudWidth, height: cloudWidth * 0.3)
            .blur(radius: 20)
            .offset(x: drift)
            .position(x: relX * 1000, y: relY * 400) // relative to cloud layer frame
            .onAppear {
                // Start at random offset
                drift = CGFloat.random(in: -30...30)
                withAnimation(.linear(duration: speed).repeatForever(autoreverses: true)) {
                    drift = CGFloat.random(in: -60...60)
                }
            }
    }
}

// MARK: - Moon with Shimmer + Parallax

struct MoonView: View {
    let scrollProgress: CGFloat // 0…1
    let viewWidth: CGFloat
    let viewHeight: CGFloat

    @State private var shimmer: CGFloat = 0.7

    // Parallax: moon moves slower than scroll (opposite direction creates depth)
    private var moonX: CGFloat {
        let center = viewWidth * 0.5
        let parallaxRange: CGFloat = viewWidth * 0.15
        return center + (scrollProgress - 0.5) * parallaxRange
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xCCCCDD).opacity(shimmer * 0.15),
                            Color(hex: 0x8888AA).opacity(shimmer * 0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blendMode(.screen)

            // Moon disc
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0xE8E0D0).opacity(shimmer),
                            Color(hex: 0xBBB8A8).opacity(shimmer * 0.8),
                            Color(hex: 0x999080).opacity(shimmer * 0.4),
                        ],
                        center: UnitPoint(x: 0.4, y: 0.35),
                        startRadius: 2,
                        endRadius: 18
                    )
                )
                .frame(width: 28, height: 28)

            // Crescent shadow overlay
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 28, height: 28)
                .offset(x: 6, y: -2)
                .mask(
                    Circle().frame(width: 28, height: 28)
                )
        }
        .position(x: moonX, y: viewHeight * 0.08)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                shimmer = 0.95
            }
        }
    }
}

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
                        with: .color(Color.white.opacity(alpha)),
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
