import SwiftUI
import func Darwin.cos
import func Darwin.sin

/// Factory for damage hit VFX effects (physical, magical, poison, true damage)
enum DamageHitEffects {

    // MARK: - Physical Hit (Gold/Amber burst + sparks + debris)

    static func physical(origin: CGPoint, isCrit: Bool) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.gold
        let secondary = DarkFantasyTheme.goldBright
        let count = isCrit ? 24 : 14
        let dur = isCrit ? 0.85 : 0.7

        var particles: [VFXParticle] = []

        // Main burst particles — radial explosion
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 120...280) * (isCrit ? 1.3 : 1.0)
            let size = CGFloat.random(in: 2.5...5.0) * (isCrit ? 1.2 : 1.0)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed),
                acc: CGPoint(x: 0, y: 80), // gravity
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.7),
                scale: size,
                rotation: angle,
                rotationSpeed: Double.random(in: -4...4),
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        // Debris chunks — triangles with gravity
        let debrisCount = isCrit ? 6 : 3
        for _ in 0..<debrisCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 80...180)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed - 60),
                acc: CGPoint(x: 0, y: 200), // heavy gravity
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.6),
                scale: CGFloat.random(in: 4...7),
                rotation: Double.random(in: 0...(2 * .pi)),
                rotationSpeed: Double.random(in: -8...8),
                color: primary.opacity(0.8),
                shape: .triangle
            ))
        }

        // Spark lines — fast, thin
        let sparkCount = isCrit ? 8 : 4
        for _ in 0..<sparkCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 200...400)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.2...0.35),
                scale: CGFloat.random(in: 2...3.5),
                rotation: angle,
                rotationSpeed: 0,
                color: secondary,
                shape: .line
            ))
        }

        return ActiveVFXEffect(
            type: isCrit ? .physicalCrit : .physicalHit,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: secondary,
            ringMaxRadius: isCrit ? 70 : 45,
            ringColor: primary
        )
    }

    // MARK: - Magical Hit (Blue/Purple spiral + shimmer rings)

    static func magical(origin: CGPoint, isCrit: Bool) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.classMage
        let secondary = DarkFantasyTheme.purple
        let count = isCrit ? 22 : 12
        let dur = isCrit ? 0.85 : 0.7

        var particles: [VFXParticle] = []

        // Main particles — upward spiral
        for i in 0..<count {
            let baseAngle = Double(i) / Double(count) * 2 * .pi
            let speed = CGFloat.random(in: 100...220) * (isCrit ? 1.3 : 1.0)
            let size = CGFloat.random(in: 2.5...5.0) * (isCrit ? 1.2 : 1.0)
            // Spiral: add perpendicular velocity component
            let radialX = CGFloat(cos(baseAngle)) * speed
            let radialY = CGFloat(sin(baseAngle)) * speed
            let tangentX = CGFloat(-sin(baseAngle)) * speed * 0.3
            let tangentY = CGFloat(cos(baseAngle)) * speed * 0.3

            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: radialX + tangentX, y: radialY + tangentY - 40),
                acc: CGPoint(x: 0, y: CGFloat(-30)), // slight upward drift
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.7),
                scale: size,
                rotation: baseAngle,
                rotationSpeed: Double.random(in: -3...3),
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        // Shimmer rings — expanding circles
        let ringCount = isCrit ? 4 : 2
        for i in 0..<ringCount {
            let delay = Double(i) * 0.08
            let speed = CGFloat.random(in: 40...80)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: 0, y: 0),
                acc: CGPoint(x: speed, y: speed), // abusing acc as expansion rate
                life: 1.0,
                maxLife: 0.5 + delay,
                scale: CGFloat(8 + i * 6),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(0.4),
                shape: .ring
            ))
        }

        // Small star sparkles
        let starCount = isCrit ? 6 : 3
        for _ in 0..<starCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 15...40)
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat(cos(angle)) * dist, y: CGFloat(sin(angle)) * dist),
                vel: CGPoint(x: CGFloat(cos(angle)) * 30, y: CGFloat(sin(angle)) * 30 - 20),
                acc: .zero,
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.6),
                scale: CGFloat.random(in: 3...6),
                rotation: Double.random(in: 0...(2 * .pi)),
                rotationSpeed: Double.random(in: 1...3),
                color: secondary,
                shape: .star
            ))
        }

        return ActiveVFXEffect(
            type: isCrit ? .magicalCrit : .magicalHit,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary,
            ringMaxRadius: isCrit ? 65 : 40,
            ringColor: secondary
        )
    }

    // MARK: - Poison Hit (Green mist + spiral + drips)

    static func poison(origin: CGPoint, isCrit: Bool) -> ActiveVFXEffect {
        let primary = DarkFantasyTheme.success
        let secondary = DarkFantasyTheme.vfxPoisonGlow
        let count = isCrit ? 20 : 10
        let dur = isCrit ? 0.85 : 0.7

        var particles: [VFXParticle] = []

        // Mist clouds — large, slow, expanding
        let mistCount = isCrit ? 6 : 3
        for _ in 0..<mistCount {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 20...60)
            particles.append(VFXParticle(
                pos: CGPoint(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: -10...10)),
                vel: CGPoint(x: CGFloat(cos(angle)) * speed, y: CGFloat(sin(angle)) * speed),
                acc: CGPoint(x: 0, y: CGFloat(-15)), // float up
                life: 1.0,
                maxLife: Double.random(in: 0.5...0.8),
                scale: CGFloat.random(in: 12...22),
                rotation: 0,
                rotationSpeed: 0,
                color: primary.opacity(0.25),
                shape: .circle
            ))
        }

        // Toxic particles — slow spiral
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 60...150) * (isCrit ? 1.2 : 1.0)
            let tangent = CGFloat.random(in: 30...80)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(
                    x: CGFloat(cos(angle)) * speed + CGFloat(-sin(angle)) * tangent,
                    y: CGFloat(sin(angle)) * speed + CGFloat(cos(angle)) * tangent
                ),
                acc: CGPoint(x: 0, y: CGFloat(-20)),
                life: 1.0,
                maxLife: Double.random(in: 0.4...0.7),
                scale: CGFloat.random(in: 2...4.5) * (isCrit ? 1.2 : 1.0),
                rotation: angle,
                rotationSpeed: Double.random(in: -2...2),
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        // Drip lines — falling down
        let dripCount = isCrit ? 5 : 2
        for _ in 0..<dripCount {
            let x = CGFloat.random(in: -20...20)
            particles.append(VFXParticle(
                pos: CGPoint(x: x, y: 0),
                vel: CGPoint(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: 60...120)),
                acc: CGPoint(x: 0, y: 100),
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.5),
                scale: CGFloat.random(in: 2...3),
                rotation: .pi / 2,
                rotationSpeed: 0,
                color: primary,
                shape: .line
            ))
        }

        return ActiveVFXEffect(
            type: isCrit ? .poisonCrit : .poisonHit,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary,
            ringMaxRadius: isCrit ? 55 : 35,
            ringColor: secondary
        )
    }

    // MARK: - True Damage (White/Gold divine burst + rays)

    static func trueDamage(origin: CGPoint, isCrit: Bool) -> ActiveVFXEffect {
        let primary = Color.white
        let secondary = DarkFantasyTheme.goldBright
        let count = isCrit ? 26 : 16
        let dur = isCrit ? 0.85 : 0.7

        var particles: [VFXParticle] = []

        // Main burst — fast vertical emphasis
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            // Bias upward
            let biasY: CGFloat = -40
            let speed = CGFloat.random(in: 150...320) * (isCrit ? 1.3 : 1.0)
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * speed * 0.6, y: CGFloat(sin(angle)) * speed + biasY),
                acc: CGPoint(x: 0, y: 40),
                life: 1.0,
                maxLife: Double.random(in: 0.3...0.6),
                scale: CGFloat.random(in: 2...4.5) * (isCrit ? 1.2 : 1.0),
                rotation: angle,
                rotationSpeed: Double.random(in: -3...3),
                color: Bool.random() ? primary : secondary,
                shape: .circle
            ))
        }

        // Light rays — radial lines from center
        let rayCount = isCrit ? 10 : 6
        for i in 0..<rayCount {
            let angle = Double(i) / Double(rayCount) * 2 * .pi
            particles.append(VFXParticle(
                pos: .zero,
                vel: CGPoint(x: CGFloat(cos(angle)) * 250, y: CGFloat(sin(angle)) * 250),
                acc: .zero,
                life: 1.0,
                maxLife: 0.3,
                scale: CGFloat.random(in: 3...5),
                rotation: angle,
                rotationSpeed: 0,
                color: primary.opacity(0.7),
                shape: .line
            ))
        }

        // Golden stars
        if isCrit {
            for _ in 0..<5 {
                let angle = Double.random(in: 0...(2 * .pi))
                let dist = CGFloat.random(in: 20...50)
                particles.append(VFXParticle(
                    pos: CGPoint(x: CGFloat(cos(angle)) * dist, y: CGFloat(sin(angle)) * dist),
                    vel: CGPoint(x: CGFloat(cos(angle)) * 40, y: CGFloat(sin(angle)) * 40 - 30),
                    acc: .zero,
                    life: 1.0,
                    maxLife: Double.random(in: 0.4...0.7),
                    scale: CGFloat.random(in: 4...7),
                    rotation: Double.random(in: 0...(2 * .pi)),
                    rotationSpeed: Double.random(in: 1...4),
                    color: secondary,
                    shape: .star
                ))
            }
        }

        return ActiveVFXEffect(
            type: isCrit ? .trueCrit : .trueHit,
            origin: origin,
            particles: particles,
            duration: dur,
            flashColor: primary,
            ringMaxRadius: isCrit ? 80 : 50,
            ringColor: secondary
        )
    }
}
