import SwiftUI
import func Darwin.cos
import func Darwin.sin

@MainActor @Observable
final class CombatVFXManager {

    // MARK: - State
    // ObservationIgnored: these are mutated every frame by Canvas/TimelineView,
    // so we don't want them to trigger @Observable view rebuilds.
    // TimelineView already drives 60fps redraws.
    @ObservationIgnored var activeEffects: [ActiveVFXEffect] = []
    @ObservationIgnored private var lastFrameTime: Date?

    // MARK: - Trigger

    func trigger(_ type: VFXEffectType, at normalizedPos: CGPoint, speed: Double) {
        let effect = buildEffect(type: type, origin: normalizedPos, speed: speed)
        activeEffects.append(effect)
    }

    func clearAll() {
        activeEffects.removeAll()
        lastFrameTime = nil
    }

    // MARK: - Frame Update

    func update(now: Date, speed: Double) {
        guard let last = lastFrameTime else {
            lastFrameTime = now
            return
        }

        let rawDt = now.timeIntervalSince(last)
        let dt = min(rawDt, 1.0 / 30.0) / speed // scale by speed (0.5 = 2x faster)
        lastFrameTime = now

        for i in activeEffects.indices {
            activeEffects[i].update(dt: dt)
        }

        activeEffects.removeAll { $0.isFinished }
    }

    // MARK: - Render

    func render(in context: inout GraphicsContext, size: CGSize) {
        for effect in activeEffects {
            renderEffect(effect, in: &context, size: size)
        }
    }

    // MARK: - Render Single Effect

    private func renderEffect(_ effect: ActiveVFXEffect, in context: inout GraphicsContext, size: CGSize) {
        let ox = effect.origin.x * size.width
        let oy = effect.origin.y * size.height

        // Impact flash overlay
        if effect.flashOpacity > 0 {
            let flashRect = CGRect(
                x: ox - 60, y: oy - 60,
                width: 120, height: 120
            )
            context.opacity = effect.flashOpacity * 0.6
            context.fill(
                Circle().path(in: flashRect),
                with: .color(effect.flashColor)
            )
            context.opacity = 1.0

            // Larger glow
            let glowRect = CGRect(
                x: ox - 100, y: oy - 100,
                width: 200, height: 200
            )
            context.opacity = effect.flashOpacity * 0.2
            context.fill(
                Circle().path(in: glowRect),
                with: .color(effect.flashColor)
            )
            context.opacity = 1.0
        }

        // Shockwave ring
        if effect.ringRadius > 0 && effect.ringMaxRadius > 0 {
            let ringProgress = effect.ringRadius / effect.ringMaxRadius
            let ringOpacity = max(0, 1.0 - ringProgress)
            let r = effect.ringRadius
            let ringRect = CGRect(x: ox - r, y: oy - r, width: r * 2, height: r * 2)

            context.opacity = ringOpacity * 0.5
            context.stroke(
                Circle().path(in: ringRect),
                with: .color(effect.ringColor),
                lineWidth: max(1, 3 * (1 - ringProgress))
            )
            context.opacity = 1.0
        }

        // Particles
        for particle in effect.particles {
            guard particle.isAlive else { continue }
            let px = ox + particle.pos.x
            let py = oy + particle.pos.y
            let s = particle.scale * (0.5 + particle.life * 0.5) // shrink as dying

            context.opacity = particle.opacity

            switch particle.shape {
            case .circle:
                let rect = CGRect(x: px - s, y: py - s, width: s * 2, height: s * 2)
                context.fill(Circle().path(in: rect), with: .color(particle.color))
                // Glow
                let glowR = s * 2.5
                let glowRect = CGRect(x: px - glowR, y: py - glowR, width: glowR * 2, height: glowR * 2)
                context.opacity = particle.opacity * 0.2
                context.fill(Circle().path(in: glowRect), with: .color(particle.color))

            case .line:
                let len = s * 3
                var path = Path()
                let dx = CGFloat(cos(particle.rotation))
                let dy = CGFloat(sin(particle.rotation))
                path.move(to: CGPoint(x: px - dx * len, y: py - dy * len))
                path.addLine(to: CGPoint(x: px + dx * len, y: py + dy * len))
                context.stroke(path, with: .color(particle.color), lineWidth: max(1, s * 0.4))

            case .triangle:
                let sz = s * 1.5
                var path = Path()
                path.move(to: CGPoint(x: px, y: py - sz))
                path.addLine(to: CGPoint(x: px - sz * 0.866, y: py + sz * 0.5))
                path.addLine(to: CGPoint(x: px + sz * 0.866, y: py + sz * 0.5))
                path.closeSubpath()

                var rotated = context
                rotated.translateBy(x: px, y: py)
                rotated.rotate(by: .radians(particle.rotation))
                rotated.translateBy(x: -px, y: -py)
                rotated.fill(path, with: .color(particle.color))

            case .ring:
                let rect = CGRect(x: px - s * 2, y: py - s * 2, width: s * 4, height: s * 4)
                context.stroke(Circle().path(in: rect), with: .color(particle.color), lineWidth: max(1, s * 0.3))

            case .slash:
                let len = s * 4
                var path = Path()
                let startAngle = particle.rotation - 0.4
                let endAngle = particle.rotation + 0.4
                path.addArc(
                    center: CGPoint(x: px, y: py),
                    radius: len,
                    startAngle: .radians(startAngle),
                    endAngle: .radians(endAngle),
                    clockwise: false
                )
                context.stroke(path, with: .color(particle.color), lineWidth: max(1, s * 0.6))

            case .star:
                let sz = s * 1.2
                var path = Path()
                for i in 0..<5 {
                    let outerAngle = Double(i) * (2 * .pi / 5) - .pi / 2 + particle.rotation
                    let innerAngle = outerAngle + .pi / 5
                    let outerPt = CGPoint(x: px + CGFloat(cos(outerAngle)) * sz, y: py + CGFloat(sin(outerAngle)) * sz)
                    let innerPt = CGPoint(x: px + CGFloat(cos(innerAngle)) * sz * 0.4, y: py + CGFloat(sin(innerAngle)) * sz * 0.4)
                    if i == 0 { path.move(to: outerPt) }
                    else { path.addLine(to: outerPt) }
                    path.addLine(to: innerPt)
                }
                path.closeSubpath()
                context.fill(path, with: .color(particle.color))
            }

            context.opacity = 1.0
        }
    }

    // MARK: - Effect Factory

    private func buildEffect(type: VFXEffectType, origin: CGPoint, speed: Double) -> ActiveVFXEffect {
        switch type {
        case .physicalHit:   return DamageHitEffects.physical(origin: origin, isCrit: false)
        case .physicalCrit:  return DamageHitEffects.physical(origin: origin, isCrit: true)
        case .magicalHit:    return DamageHitEffects.magical(origin: origin, isCrit: false)
        case .magicalCrit:   return DamageHitEffects.magical(origin: origin, isCrit: true)
        case .poisonHit:     return DamageHitEffects.poison(origin: origin, isCrit: false)
        case .poisonCrit:    return DamageHitEffects.poison(origin: origin, isCrit: true)
        case .trueHit:       return DamageHitEffects.trueDamage(origin: origin, isCrit: false)
        case .trueCrit:      return DamageHitEffects.trueDamage(origin: origin, isCrit: true)
        case .dodge:         return DodgeMissBlockEffects.dodge(origin: origin)
        case .miss:          return DodgeMissBlockEffects.miss(origin: origin)
        case .block:         return DodgeMissBlockEffects.block(origin: origin)
        case .heal:          return HealEffects.heal(origin: origin)
        case .statusProc(let status): return StatusVFXEffects.statusProc(status, origin: origin)
        }
    }
}
