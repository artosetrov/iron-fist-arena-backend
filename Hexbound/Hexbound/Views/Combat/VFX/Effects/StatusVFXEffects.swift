import SwiftUI
import func Darwin.cos
import func Darwin.sin

/// Factory for status effect proc VFX (bleed, burn, poison, freeze, stun)
enum StatusVFXEffects {

    static func statusProc(_ status: String, origin: CGPoint) -> ActiveVFXEffect {
        switch status.lowercased() {
        case "bleed":  return bleed(origin: origin)
        case "burn":   return burn(origin: origin)
        case "poison": return poisonStatus(origin: origin)
        case "freeze": return freeze(origin: origin)
        case "stun":   return stun(origin: origin)
        default:       return generic(status, origin: origin)
        }
    }

    // MARK: - Bleed (red droplets falling)

    private static func bleed(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.danger
        let secondary = DarkFantasyTheme.textDanger
        let dur = 0.6

        var particles: [VFXParticle] = []

        // Blood droplets falling
        for _ in 0..<8 {
            let x = CGFloat.random(in: -18...18)
            particles.append(VFXParticle(
                pos: CGPoint(x: x, y: CGFloat.random(in: -5...5)),
                vel: CGPoint(x: CGFloat.random(in: -15...15), y: CGFloat.random(in: 40...100)),
                acc: CGPoint(x: 0, y: 120),
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.5),
                scale: CGFloat.random(in: 2...4),
                rotation: 0,
                rotationSpeed: 0,
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        // Small splash at center
        for _ in 0..<4 {
            let angle = Double.random(in: 0...(2 * .pi))
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * 60, y: CGFloat(sin(angle)) * 60),
                acc: .zero,
                life: 1.0,
                maxLife: 0.2,
                scale: CGFloat.random(in: 1.5...2.5),
                rotation: angle,
                rotationSpeed: 0,
                color: primary,
                shape: .line
            ))
        }

        return ActiveVFXEffect(
            type: .statusProc("bleed"),
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary.opacity(0.3),
            ringMaxRadius: 0,
            ringColor: .clear
        )
    }

    // MARK: - Burn (orange ember particles rising with rotation)

    private static func burn(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.stamina
        let secondary = DarkFantasyTheme.vfxBurnGlow
        let dur = 0.6

        var particles: [VFXParticle] = []

        // Flames rising
        for _ in 0..<10 {
            let x = CGFloat.random(in: -15...15)
            particles.append(VFXParticle(
                pos: CGPoint(x: x, y: CGFloat.random(in: 0...10)),
                vel: CGPoint(
                    x: CGFloat.random(in: -25...25),
                    y: CGFloat.random(in: -140 ... -60)
                ),
                acc: CGPoint(x: CGFloat.random(in: -8...8), y: CGFloat(-20)),
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.6),
                scale: CGFloat.random(in: 2.5...5),
                rotation: Double.random(in: 0...(2 * .pi)),
                rotationSpeed: Double.random(in: -3...3),
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        // Ember trails
        for _ in 0..<4 {
            let x = CGFloat.random(in: -12...12)
            particles.append(VFXParticle(
                pos: CGPoint(x: x, y: 5),
                vel: CGPoint(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: -100 ... -50)),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.2...0.4),
                scale: CGFloat.random(in: 1.5...2.5),
                rotation: -.pi / 2,
                rotationSpeed: 0,
                color: DarkFantasyTheme.goldBright.opacity(0.6),
                shape: .line
            ))
        }

        return ActiveVFXEffect(
            type: .statusProc("burn"),
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary.opacity(0.25),
            ringMaxRadius: 0,
            ringColor: .clear
        )
    }

    // MARK: - Poison Status (green gas cloud)

    private static func poisonStatus(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.success
        let secondary = DarkFantasyTheme.vfxPoisonGlow
        let dur = 0.6

        var particles: [VFXParticle] = []

        // Gas cloud — large semitransparent blobs
        for _ in 0..<5 {
            let angle = Double.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 5...20)
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat(cos(angle)) * dist, y: CGFloat(sin(angle)) * dist),
                vel: CGPoint(x: CGFloat(cos(angle)) * 15, y: -CGFloat.random(in: 15...30)),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.6),
                scale: CGFloat.random(in: 14...22),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(0.18),
                shape: .circle
            ))
        }

        // Small toxic droplets
        for _ in 0..<6 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 40...80)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed - 20),
                acc: CGPoint(x: 0, y: CGFloat(-10)),
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.5),
                scale: CGFloat.random(in: 1.5...3),
                rotation: 0,
                rotationSpeed: 0,
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        return ActiveVFXEffect(
            type: .statusProc("poison"),
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: .clear,
            ringMaxRadius: 30,
            ringColor: primary
        )
    }

    // MARK: - Freeze (ice crystal particles with shimmer)

    private static func freeze(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.info
        let secondary = DarkFantasyTheme.cyan
        let dur = 0.6

        var particles: [VFXParticle] = []

        // Ice crystals — stars rotating slowly
        for _ in 0..<8 {
            let angle = Double.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 10...35)
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat(cos(angle)) * dist, y: CGFloat(sin(angle)) * dist),
                vel: CGPoint(x: CGFloat(cos(angle)) * 20, y: CGFloat(sin(angle)) * 20),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.6),
                scale: CGFloat.random(in: 3...6),
                rotation: Double.random(in: 0...(2 * .pi)),
                rotationSpeed: Double.random(in: 0.3...1.5),
                color: Bool.random() ? primary : secondary,
                shape: .star
            ))
        }

        // Frost shimmer lines
        for _ in 0..<5 {
            let angle = Double.random(in: 0...(2 * .pi))
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * 80, y: CGFloat(sin(angle)) * 80),
                acc: .zero,
                life: 1.0,
                maxLife: 0.25,
                scale: CGFloat.random(in: 2...3.5),
                rotation: angle,
                rotationSpeed: 0,
                color: secondary.opacity(0.5),
                shape: .line
            ))
        }

        // Cold mist
        for _ in 0..<3 {
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: -5...5)),
                vel: CGPoint(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: -15 ... -5)),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.6),
                scale: CGFloat.random(in: 16...24),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(0.1),
                shape: .circle
            ))
        }

        return ActiveVFXEffect(
            type: .statusProc("freeze"),
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: secondary.opacity(0.2),
            ringMaxRadius: 40,
            ringColor: primary
        )
    }

    // MARK: - Stun (gold stars spiraling upward)

    private static func stun(origin: CGPoint) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.goldBright
        let secondary = DarkFantasyTheme.vfxStunGlow
        let dur = 0.6

        var particles: [VFXParticle] = []

        // Spiraling stars
        for i in 0..<6 {
            let baseAngle = Double(i) / 6.0 * 2 * .pi
            let dist: CGFloat = 20
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat(cos(baseAngle)) * dist, y: CGFloat(sin(baseAngle)) * dist),
                vel: CGPoint(
                    x: CGFloat(-sin(baseAngle)) * 60, // tangent motion = spiral
                    y: CGFloat(cos(baseAngle)) * 60 - 40 // upward bias
                ),
                acc: CGPoint(x: 0, y: CGFloat(-20)),
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.6),
                scale: CGFloat.random(in: 4...7),
                rotation: baseAngle,
                rotationSpeed: Double.random(in: 2...5),
                color: Bool.random() ? primary : secondary,
                shape: .star
            ))
        }

        // Central flash ring
        particles.append(VFXParticle(
            pos: .zero,
            vel: .zero,
            acc: .zero,
            life: 1.0,
            maxLife: 0.4,
            scale: 15,
            rotation: 0,
            rotationSpeed: 0,
            color: primary.opacity(0.3),
            shape: .ring
        ))

        return ActiveVFXEffect(
            type: .statusProc("stun"),
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary.opacity(0.3),
            ringMaxRadius: 35,
            ringColor: primary
        )
    }

    // MARK: - Generic Status

    private static func generic(_ status: String, origin: CGPoint) -> ActiveVFXEffect {
        let color = DarkFantasyTheme.textSecondary
        let dur = 0.5

        var particles: [VFXParticle] = []

        for _ in 0..<6 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...100)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.5),
                scale: CGFloat.random(in: 2...4),
                rotation: angle,
                rotationSpeed: 0,
                color: color,
                shape: .circle
            ))
        }

        return ActiveVFXEffect(
            type: .statusProc(status),
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: .clear,
            ringMaxRadius: 0,
            ringColor: .clear
        )
    }
}
