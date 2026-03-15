import SwiftUI
import func Darwin.cos
import func Darwin.sin

/// Factory for heal VFX effects
enum HealEffects {

    // MARK: - Heal (green/gold rising sparkles + soft glow)

    static func heal(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.success
        let secondary = DarkFantasyTheme.goldBright
        let dur = 0.8

        var particles: [VFXParticle] = []

        // Rising sparkle particles — float upward with gentle sway
        for _ in 0..<14 {
            let x = CGFloat.random(in: -25...25)
            let y = CGFloat.random(in: -10...10)
            particles.append(VFXParticle(
                pos: CGPoint(x: x, y: y),
                vel: CGPoint(
                    x: CGFloat.random(in: -20...20),
                    y: CGFloat.random(in: -120 ... -60)  // upward
                ),
                acc: CGPoint(x: CGFloat.random(in: -10...10), y: CGFloat(-15)), // gentle upward + sway
                life: 1.0,
                maxLife: Double.random(in: 0.5...0.8),
                scale: CGFloat.random(in: 2...4.5),
                rotation: Double.random(in: 0...(2 * .pi)),
                rotationSpeed: Double.random(in: 1...3),
                color: Bool.random() ? primary : secondary,
                shape: Bool.random() ? .circle : .star
            ))
        }

        // Soft glow cloud — large, fading
        for _ in 0..<3 {
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -5...5)),
                vel: CGPoint(x: 0, y: CGFloat.random(in: -25 ... -10)),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.5...0.7),
                scale: CGFloat.random(in: 18...28),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(0.12),
                shape: .circle
            ))
        }

        // Small golden plus/cross shapes (rendered as double lines)
        for _ in 0..<4 {
            let x = CGFloat.random(in: -20...20)
            let y = CGFloat.random(in: -15...5)
            particles.append(VFXParticle(
                pos: CGPoint(x: x, y: y),
                vel: CGPoint(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -80 ... -40)),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.6),
                scale: CGFloat.random(in: 3...5),
                rotation: 0,
                rotationSpeed: Double.random(in: 0.5...1.5),
                color: secondary,
                shape: .star
            ))
        }

        return ActiveVFXEffect(
            type: .heal,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary.opacity(0.4),
            ringMaxRadius: 0,
            ringColor: .clear
        )
    }
}
