import SwiftUI

// MARK: - Coin Fly Animation (see docs/07_ui_ux/MOTION_AND_JUICE_AUDIT.md §3.10)
// Particles fly from source to currency counter in an arc trajectory.
// Usage: Overlay on screen, trigger with .coinFly(isActive:) or programmatically.

struct CoinFlyAnimationView: View {
    let style: CoinStyle
    let count: Int
    let sourcePoint: CGPoint
    let targetPoint: CGPoint
    let onComplete: (() -> Void)?

    @State private var coins: [FlyingCoin] = []
    @State private var isAnimating = false

    init(
        style: CoinStyle = .gold,
        count: Int = MotionConstants.particlesCoinFly,
        sourcePoint: CGPoint,
        targetPoint: CGPoint,
        onComplete: (() -> Void)? = nil
    ) {
        self.style = style
        self.count = count
        self.sourcePoint = sourcePoint
        self.targetPoint = targetPoint
        self.onComplete = onComplete
    }

    var body: some View {
        ZStack {
            ForEach(coins) { coin in
                Circle()
                    .fill(coin.color)
                    .frame(width: coin.size, height: coin.size)
                    .shadow(color: coin.color.opacity(0.5), radius: 4)
                    .position(
                        x: isAnimating ? targetPoint.x + coin.endOffset.width : sourcePoint.x + coin.startOffset.width,
                        y: isAnimating ? targetPoint.y + coin.endOffset.height : sourcePoint.y + coin.startOffset.height
                    )
                    .scaleEffect(isAnimating ? 0.3 : 1.0)
                    .opacity(isAnimating ? 0.4 : 1.0)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            coins = generateCoins()
            // Staggered launch
            for (index, _) in coins.enumerated() {
                let delay = Double(index) * 0.06
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeIn(duration: 0.4 + Double.random(in: 0...0.15))) {
                        isAnimating = true
                    }
                }
            }
            // Haptic
            HapticManager.coinCascade(count: min(count, 6))
            // Completion callback
            let totalDuration = 0.4 + Double(count) * 0.06 + 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                onComplete?()
            }
        }
    }

    private func generateCoins() -> [FlyingCoin] {
        (0..<count).map { _ in
            FlyingCoin(
                startOffset: CGSize(
                    width: CGFloat.random(in: -20...20),
                    height: CGFloat.random(in: -20...20)
                ),
                endOffset: CGSize(
                    width: CGFloat.random(in: -8...8),
                    height: CGFloat.random(in: -8...8)
                ),
                size: CGFloat.random(in: style.sizeRange),
                color: style.colors.randomElement() ?? DarkFantasyTheme.gold
            )
        }
    }
}

// MARK: - Coin Style

enum CoinStyle {
    case gold
    case gems
    case xp

    var colors: [Color] {
        switch self {
        case .gold:
            return [
                DarkFantasyTheme.goldBright,
                DarkFantasyTheme.gold,
                DarkFantasyTheme.goldDim
            ]
        case .gems:
            return [
                DarkFantasyTheme.cyan,
                DarkFantasyTheme.cyan.opacity(0.8),
                DarkFantasyTheme.info
            ]
        case .xp:
            return [
                DarkFantasyTheme.purple,
                DarkFantasyTheme.purple.opacity(0.8),
                DarkFantasyTheme.cyan.opacity(0.6)
            ]
        }
    }

    var sizeRange: ClosedRange<CGFloat> {
        switch self {
        case .gold: return 6...12
        case .gems: return 5...10
        case .xp: return 4...8
        }
    }
}

// MARK: - Flying Coin Model

private struct FlyingCoin: Identifiable {
    let id = UUID()
    let startOffset: CGSize
    let endOffset: CGSize
    let size: CGFloat
    let color: Color
}

// MARK: - View Modifier for Triggered Coin Fly

struct CoinFlyModifier: ViewModifier {
    let isActive: Bool
    let style: CoinStyle
    let count: Int
    let sourcePoint: CGPoint
    let targetPoint: CGPoint
    let onComplete: (() -> Void)?

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                CoinFlyAnimationView(
                    style: style,
                    count: count,
                    sourcePoint: sourcePoint,
                    targetPoint: targetPoint,
                    onComplete: onComplete
                )
            }
        }
    }
}

extension View {
    /// Overlay coin fly particles when active.
    func coinFly(
        isActive: Bool,
        style: CoinStyle = .gold,
        count: Int = MotionConstants.particlesCoinFly,
        from source: CGPoint,
        to target: CGPoint,
        onComplete: (() -> Void)? = nil
    ) -> some View {
        modifier(CoinFlyModifier(
            isActive: isActive,
            style: style,
            count: count,
            sourcePoint: source,
            targetPoint: target,
            onComplete: onComplete
        ))
    }
}
