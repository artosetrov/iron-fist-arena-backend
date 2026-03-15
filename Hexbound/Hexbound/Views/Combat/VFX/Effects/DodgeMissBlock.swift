import SwiftUI
import func Darwin.cos
import func Darwin.sin

/// Factory for dodge, miss, and block VFX effects
enum DodgeMissBlockEffects {

    // MARK: - Dodge (speed lines sweeping sideways + afterimage)

    static func dodge(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.textSecondary
        let secondary = DarkFantasyTheme.textTertiary
        let dur = 0.5

        var particles: [VFXParticle] = []

        // Speed lines — horizontal sweep left
        for _ in 0..<8 {
            let y = CGFloat.random(in: -30...30)
            particles.append(VFXParticle(
                pos: CGPoint(x: 20, y: y),
                vel: CGPoint(x: CGFloat.random(in: -350 ... -150), y: CGFloat.random(in: -10...10)),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.2...0.4),
                scale: CGFloat.random(in: 2...4),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(Double.random(in: 0.3...0.7)),
                shape: .line
            ))
        }

        // Afterimage ghost particles — semitransparent circles drifting left
        for _ in 0..<4 {
            let y = CGFloat.random(in: -15...15)
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat.random(in: 5...15), y: y),
                vel: CGPoint(x: CGFloat.random(in: -80 ... -40), y: 0),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.5),
                scale: CGFloat.random(in: 8...15),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(0.15),
                shape: .circle
            ))
        }

        // Wind swoosh arcs
        for i in 0..<3 {
            let baseAngle = Double.random(in: -0.3...0.3)
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat(i) * 8, y: 0),
                vel: CGPoint(x: -200, y: CGFloat.random(in: -20...20)),
                acc: .zero,
                life: 1.0,
                maxLife: 0.25,
                scale: CGFloat.random(in: 5...8),
                rotation: baseAngle,
                rotationSpeed: 0,
                color: secondary.opacity(0.5),
                shape: .slash
            ))
        }

        return ActiveVFXEffect(
            type: .dodge,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: .clear,
            ringMaxRadius: 0,
            ringColor: .clear
        )
    }

    // MARK: - Miss (faded whoosh dissipating)

    static func miss(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.textTertiary
        let secondary = DarkFantasyTheme.textDisabled
        let dur = 0.4

        var particles: [VFXParticle] = []

        // Light gray scattered particles — dissipating outward weakly
        for _ in 0..<6 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 30...80)
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: -5...5)),
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed),
                acc: CGPoint(x: 0, y: CGFloat(-10)),
                life: 1.0,
                maxLife: Double.random(in: 0.2...0.35),
                scale: CGFloat.random(in: 1.5...3),
                rotation: angle,
                rotationSpeed: Double.random(in: -1...1),
                color: primary.opacity(0.4),
                shape: .circle
            ))
        }

        // A couple thin lines
        for _ in 0..<3 {
            let angle = Double.random(in: 0...(2 * .pi))
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * 100, y: CGFloat(sin(angle)) * 100),
                acc: .zero,
                life: 1.0,
                maxLife: 0.2,
                scale: CGFloat.random(in: 1.5...2.5),
                rotation: angle,
                rotationSpeed: 0,
                color: secondary.opacity(0.3),
                shape: .line
            ))
        }

        return ActiveVFXEffect(
            type: .miss,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: .clear,
            ringMaxRadius: 0,
            ringColor: .clear
        )
    }

    // MARK: - Block (shield flash + concentric defense rings)

    static func block(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.info
        let secondary = DarkFantasyTheme.cyan
        let dur = 0.6

        var particles: [VFXParticle] = []

        // Shield impact sparks — diagonal spray
        for _ in 0..<10 {
            let angle = Double.random(in: -Double.pi * 0.4...Double.pi * 0.4) - .pi // leftward bias
            let speed = CGFloat.random(in: 100...200)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed),
                acc: CGPoint(x: 0, y: CGFloat(50)),
                life: 1.0,
                maxLife: Double.random(in: 0.25...0.45),
                scale: CGFloat.random(in: 2...4),
                rotation: angle,
                rotationSpeed: Double.random(in: -4...4),
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        // Concentric shield rings — staggered expanding
        for i in 0..<3 {
            particles.append(VFXParticle(
                pos: .zero,
                vel: .zero,
                acc: .zero,
                life: 1.0,
                maxLife: 0.4 + Double(i) * 0.1,
                scale: CGFloat(10 + i * 12),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(0.4 - Double(i) * 0.1),
                shape: .ring
            ))
        }

        // Shield shape — large semitransparent arc
        particles.append(VFXParticle(
            pos: .zero,
            vel: .zero,
            acc: .zero,
            life: 1.0,
            maxLife: 0.5,
            scale: 18,
            rotation: -.pi / 2,
            rotationSpeed: 0,
            color: primary.opacity(0.4),
            shape: .slash
        ))

        return ActiveVFXEffect(
            type: .block,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary,
            ringMaxRadius: 55,
            ringColor: secondary
        )
    }
}
