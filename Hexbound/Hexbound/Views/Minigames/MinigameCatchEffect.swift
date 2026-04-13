import SwiftUI

// MARK: - Catch Effect Model

/// Tracks an active catch visual effect (burst + floating text + coin-fly).
/// Spawned on each tap in the GoldMineMiniGameView and auto-removed after
/// its animation lifetime expires.
struct CatchEffect: Identifiable {
    let id: UUID = UUID()
    let position: CGPoint
    let kind: FallingDrop.Kind
    let isRare: Bool
    let spawnedAt: Date

    /// Total animation lifetime before removal (burst + float + fly).
    var lifetime: Double { isRare ? 0.9 : 0.6 }
}

// MARK: - Floating +N Text

/// Shows "+1", "+5", "+10", "+1 gem" floating upward from the catch point
/// and fading out. Rare catches (5+ gold, gems) get a larger, glowing variant.
struct FloatingValueView: View {
    let effect: CatchEffect
    @State private var isAnimating = false

    private var label: String {
        switch effect.kind {
        case .gold(let v): return "+\(v)"
        case .gem: return "+1"
        }
    }

    private var color: Color {
        switch effect.kind {
        case .gold: return DarkFantasyTheme.goldBright
        case .gem: return DarkFantasyTheme.cyan
        }
    }

    var body: some View {
        Text(label)
            .font(effect.isRare ? DarkFantasyTheme.section : DarkFantasyTheme.cardTitle)
            .foregroundStyle(color)
            .shadow(
                color: color.opacity(effect.isRare ? 0.8 : 0.5),
                radius: effect.isRare ? 12 : 6
            )
            .opacity(isAnimating ? 0 : 1)
            .offset(y: isAnimating ? -80 : 0)
            .position(effect.position)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: effect.isRare ? 0.7 : 0.5)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Catch Burst Overlay

/// Manages all active catch effects: burst particles, floating text, and
/// coin-fly arcs. Layered as an overlay on the play field.
struct MinigameCatchEffectOverlay: View {
    let effects: [CatchEffect]
    let goldCounterPosition: CGPoint

    var body: some View {
        ZStack {
            ForEach(effects) { effect in
                // Floating +N text
                FloatingValueView(effect: effect)

                // Inline burst particles (lightweight — no RewardBurstView
                // binding overhead for rapid-fire catches)
                MiniBurstView(
                    position: effect.position,
                    isGem: effect.kind.isGem,
                    isRare: effect.isRare
                )

                // Coin-fly to counter (only for gold, not gems — gems
                // don't have a visible counter in the HUD)
                if !effect.kind.isGem {
                    CoinFlyAnimationView(
                        style: .gold,
                        count: effect.isRare ? 6 : 3,
                        sourcePoint: effect.position,
                        targetPoint: goldCounterPosition
                    )
                } else {
                    CoinFlyAnimationView(
                        style: .gems,
                        count: 3,
                        sourcePoint: effect.position,
                        targetPoint: goldCounterPosition
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Lightweight Mini Burst

/// A minimal radial burst optimized for rapid-fire usage inside the minigame.
/// Uses Canvas + TimelineView instead of per-particle views to avoid creating
/// hundreds of SwiftUI views during a 60-second session.
struct MiniBurstView: View {
    let position: CGPoint
    let isGem: Bool
    let isRare: Bool

    @State private var progress: CGFloat = 0

    private var particleCount: Int { isRare ? 16 : 10 }
    private var maxRadius: CGFloat { isRare ? 50 : 30 }
    private var duration: Double { isRare ? 0.45 : 0.3 }

    var body: some View {
        Canvas { context, _ in
            let resolvedRadius: CGFloat = maxRadius * progress
            let alpha: CGFloat = 1.0 - progress

            for i in 0..<particleCount {
                let angle: Double = (Double(i) / Double(particleCount)) * 2 * .pi + Double(i) * 0.3
                var rng1 = SeededRNG(seed: UInt64(i))
                let r: CGFloat = resolvedRadius * CGFloat.random(in: 0.6...1.0, using: &rng1)
                let px: CGFloat = position.x + cos(angle) * r
                let py: CGFloat = position.y + sin(angle) * r
                var rng2 = SeededRNG(seed: UInt64(i + 100))
                let size: CGFloat = CGFloat.random(in: 2...5, using: &rng2)

                let baseColor: Color
                if isGem {
                    baseColor = i % 2 == 0 ? DarkFantasyTheme.cyan : DarkFantasyTheme.info
                } else {
                    baseColor = i % 3 == 0 ? DarkFantasyTheme.goldBright : DarkFantasyTheme.gold
                }

                let rect = CGRect(x: px - size / 2, y: py - size / 2, width: size, height: size)
                let path = Circle().path(in: rect)
                context.fill(path, with: .color(baseColor.opacity(alpha * 0.8)))
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: duration)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Seeded RNG (deterministic per-particle randomness inside Canvas)

/// Minimal xorshift64 for deterministic per-particle randomness in Canvas
/// draw calls. Avoids calling `CGFloat.random(in:)` which would change
/// every frame.
private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Near-Miss Flash

/// A brief red flash at the bottom edge when a drop is missed.
struct NearMissFlashView: View {
    @Binding var showFlash: Bool

    var body: some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [
                    DarkFantasyTheme.danger.opacity(0.4),
                    DarkFantasyTheme.danger.opacity(0),
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 60)
            .opacity(showFlash ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: showFlash)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: showFlash) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showFlash = false
                }
            }
        }
    }
}

// MARK: - Combo Banner

/// Shows "x3 COMBO", "x5 COMBO" etc. when the player catches consecutive
/// drops without a miss. Fades in at combo 3+, gets brighter at 5+.
struct ComboBannerView: View {
    let combo: Int

    private var shouldShow: Bool { combo >= 3 }

    private var label: String {
        if combo >= 10 { return "x\(combo) FRENZY!" }
        if combo >= 5 { return "x\(combo) COMBO!" }
        return "x\(combo) COMBO"
    }

    private var glowColor: Color {
        if combo >= 10 { return DarkFantasyTheme.goldBright }
        if combo >= 5 { return DarkFantasyTheme.gold }
        return DarkFantasyTheme.gold.opacity(0.6)
    }

    var body: some View {
        if shouldShow {
            Text(label)
                .font(DarkFantasyTheme.section)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(2)
                .shadow(color: glowColor, radius: combo >= 5 ? 16 : 8)
                .padding(.horizontal, LayoutConstants.spaceMD)
                .padding(.vertical, LayoutConstants.spaceXS)
                .background(
                    RoundedRectangle(cornerRadius: LayoutConstants.radiusMD)
                        .fill(DarkFantasyTheme.bgPrimary.opacity(0.6))
                )
                .transition(.opacity)
                .id("combo-\(combo)")
        }
    }
}

// MARK: - Wave Banner

/// Brief banner announcing a wave change: "GOLD RUSH!", "FINAL FRENZY!".
struct WaveBannerView: View {
    let text: String
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            Text(text)
                .font(DarkFantasyTheme.title)
                .foregroundStyle(DarkFantasyTheme.goldBright)
                .tracking(3)
                .shadow(color: DarkFantasyTheme.gold, radius: 20)
                .transition(.opacity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(MotionConstants.smooth) {
                            isVisible = false
                        }
                    }
                }
        }
    }
}

// MARK: - Screen Edge Vignette Flash

/// Brief golden vignette flash on rare catches.
struct RareCatchFlashView: View {
    @Binding var showFlash: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 0)
            .strokeBorder(
                RadialGradient(
                    colors: [
                        DarkFantasyTheme.goldBright.opacity(0.5),
                        Color.clear,
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 300
                ),
                lineWidth: 80
            )
            .opacity(showFlash ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: showFlash)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .onChange(of: showFlash) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showFlash = false
                    }
                }
            }
    }
}

// MARK: - Kind Helpers

extension FallingDrop.Kind {
    var isGem: Bool {
        if case .gem = self { return true }
        return false
    }
}
