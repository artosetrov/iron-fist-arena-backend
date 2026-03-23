import SwiftUI

// MARK: - Reward Burst Effect (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §3.8, §4.1)
// Radial particle explosion for claim/reward/celebration moments.
// Usage: RewardBurstView(style: .gold, isActive: $showBurst)

struct RewardBurstView: View {
    let style: BurstStyle
    @Binding var isActive: Bool
    var particleCount: Int? = nil
    var onComplete: (() -> Void)? = nil

    @State private var particles: [BurstParticle] = []
    @State private var isAnimating = false

    private var effectiveCount: Int {
        particleCount ?? style.defaultCount
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                particle.shape
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(
                        x: isAnimating ? particle.endX : particle.startX,
                        y: isAnimating ? particle.endY : particle.startY
                    )
                    .scaleEffect(isAnimating ? 0.1 : 1.0)
                    .opacity(isAnimating ? 0 : particle.opacity)
                    .rotationEffect(.degrees(isAnimating ? particle.rotationEnd : 0))
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                triggerBurst()
            }
        }
        .onAppear {
            if isActive {
                triggerBurst()
            }
        }
    }

    private func triggerBurst() {
        particles = generateParticles()
        isAnimating = false

        // Haptic
        switch style {
        case .gold, .claim:
            HapticManager.medium()
        case .legendary:
            HapticManager.legendaryReveal()
        case .epic:
            HapticManager.heavy()
        case .rare:
            HapticManager.medium()
        case .victory:
            HapticManager.victory()
        case .levelUp:
            HapticManager.rankUp()
        case .stamp:
            HapticManager.stamp()
        }

        withAnimation(.easeOut(duration: style.duration)) {
            isAnimating = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + style.duration + 0.1) {
            isActive = false
            particles = []
            isAnimating = false
            onComplete?()
        }
    }

    private func generateParticles() -> [BurstParticle] {
        (0..<effectiveCount).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let radius = CGFloat.random(in: style.radiusRange)
            let size = CGFloat.random(in: style.sizeRange)

            return BurstParticle(
                startX: 0,
                startY: 0,
                endX: cos(angle) * radius,
                endY: sin(angle) * radius,
                size: size,
                color: style.colors.randomElement()!,
                opacity: Double.random(in: 0.6...1.0),
                rotationEnd: Double.random(in: 90...360),
                shape: style.shapes.randomElement()!
            )
        }
    }
}

// MARK: - Burst Style

enum BurstStyle {
    case gold       // Standard gold claim (achievements, quests, daily login)
    case claim      // Same as gold but lighter
    case rare       // Blue burst
    case epic       // Purple burst
    case legendary  // Full gold explosion
    case victory    // Victory celebration
    case levelUp    // Level up celebration (gold + white starburst)
    case stamp      // Quick decisive burst

    var colors: [Color] {
        switch self {
        case .gold, .claim:
            return [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold, DarkFantasyTheme.goldDim, .textPrimary.opacity(0.7)]
        case .rare:
            return [DarkFantasyTheme.info, DarkFantasyTheme.info.opacity(0.7), DarkFantasyTheme.cyan.opacity(0.5)]
        case .epic:
            return [DarkFantasyTheme.purple, DarkFantasyTheme.purple.opacity(0.7), DarkFantasyTheme.cyan.opacity(0.4)]
        case .legendary:
            return [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold, .textPrimary.opacity(0.8), DarkFantasyTheme.goldDim]
        case .victory:
            return [DarkFantasyTheme.goldBright, DarkFantasyTheme.gold, DarkFantasyTheme.success.opacity(0.5), .textPrimary.opacity(0.6)]
        case .levelUp:
            return [DarkFantasyTheme.goldBright, .textPrimary.opacity(0.9), DarkFantasyTheme.gold, DarkFantasyTheme.goldDim]
        case .stamp:
            return [DarkFantasyTheme.gold, DarkFantasyTheme.goldDim]
        }
    }

    var defaultCount: Int {
        switch self {
        case .gold, .claim: return MotionConstants.particlesClaim
        case .rare: return MotionConstants.particlesRare
        case .epic: return MotionConstants.particlesEpic
        case .legendary: return MotionConstants.particlesLegendary
        case .victory: return 35
        case .levelUp: return 30
        case .stamp: return 10
        }
    }

    var duration: Double {
        switch self {
        case .gold, .claim, .stamp: return 0.5
        case .rare: return 0.6
        case .epic: return 0.7
        case .legendary: return 0.9
        case .victory: return 0.8
        case .levelUp: return 0.85
        }
    }

    var radiusRange: ClosedRange<CGFloat> {
        switch self {
        case .stamp: return 20...50
        case .gold, .claim: return 30...80
        case .rare: return 35...90
        case .epic: return 40...100
        case .legendary: return 50...130
        case .victory: return 40...120
        case .levelUp: return 45...120
        }
    }

    var sizeRange: ClosedRange<CGFloat> {
        switch self {
        case .stamp: return 2...5
        case .gold, .claim: return 3...7
        case .rare, .epic: return 3...8
        case .legendary: return 4...10
        case .victory: return 3...9
        case .levelUp: return 4...9
        }
    }

    var shapes: [AnyShapeStyle_Wrapper] {
        [.circle, .rectangle, .roundedRect]
    }
}

// MARK: - Burst Particle

private struct BurstParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let color: Color
    let opacity: Double
    let rotationEnd: Double
    let shape: AnyShapeStyle_Wrapper
}

// MARK: - Shape Wrapper (avoiding AnyView for particles)

enum AnyShapeStyle_Wrapper {
    case circle
    case rectangle
    case roundedRect

    @ViewBuilder
    func fill(_ color: Color) -> some View {
        switch self {
        case .circle: Circle().foregroundStyle(color)
        case .rectangle: Rectangle().foregroundStyle(color)
        case .roundedRect: RoundedRectangle(cornerRadius: LayoutConstants.radiusXS).foregroundStyle(color)
        }
    }
}


// MARK: - Convenience View Modifier

extension View {
    /// Overlay a reward burst effect centered on this view.
    func rewardBurst(
        isActive: Binding<Bool>,
        style: BurstStyle = .gold,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        overlay {
            GeometryReader { geo in
                RewardBurstView(
                    style: style,
                    isActive: isActive,
                    onComplete: onComplete
                )
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}
