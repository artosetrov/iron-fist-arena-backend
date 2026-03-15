import SwiftUI

// MARK: - Particle Shape

enum ParticleShape {
    case circle
    case line
    case triangle
    case ring
    case slash
    case star
}

// MARK: - Particle

struct VFXParticle {
    var pos: CGPoint
    var vel: CGPoint
    var acc: CGPoint
    var life: Double          // 1.0 → 0.0 (normalized remaining)
    var maxLife: Double       // total lifetime in seconds
    var elapsed: Double = 0
    var scale: CGFloat
    var rotation: Double
    var rotationSpeed: Double
    var color: Color
    var shape: ParticleShape
    var opacity: Double = 1.0
    var trailLength: CGFloat = 0

    var isAlive: Bool { life > 0 }

    mutating func update(dt: Double) {
        elapsed += dt
        life = max(0, 1.0 - elapsed / maxLife)

        vel.x += acc.x * dt
        vel.y += acc.y * dt
        pos.x += vel.x * dt
        pos.y += vel.y * dt
        rotation += rotationSpeed * dt

        // Fade out in last 40% of life
        if life < 0.4 {
            opacity = life / 0.4
        }
    }
}

// MARK: - Active Effect

struct ActiveVFXEffect: Identifiable {
    let id = UUID()
    let type: VFXEffectType
    let origin: CGPoint       // normalized (0-1) screen position
    var particles: [VFXParticle]
    var elapsed: Double = 0
    let duration: Double      // total effect duration in seconds
    var flashOpacity: Double = 0
    var flashColor: Color = .white
    var ringRadius: CGFloat = 0
    var ringMaxRadius: CGFloat = 0
    var ringColor: Color = .clear

    var isFinished: Bool { elapsed >= duration }

    mutating func update(dt: Double) {
        elapsed += dt

        // Update flash (peaks at 0.05s, gone by 0.2s)
        if elapsed < 0.05 {
            flashOpacity = elapsed / 0.05
        } else if elapsed < 0.2 {
            flashOpacity = max(0, 1.0 - (elapsed - 0.05) / 0.15)
        } else {
            flashOpacity = 0
        }

        // Update ring expansion
        if ringMaxRadius > 0 {
            let ringProgress = min(1.0, elapsed / (duration * 0.6))
            ringRadius = ringMaxRadius * ringProgress
        }

        // Update all particles
        for i in particles.indices {
            particles[i].update(dt: dt)
        }

        // Remove dead particles
        particles.removeAll { !$0.isAlive }
    }
}

// MARK: - VFX Effect Type

enum VFXEffectType: Equatable {
    case physicalHit, physicalCrit
    case magicalHit, magicalCrit
    case poisonHit, poisonCrit
    case trueHit, trueCrit
    case dodge, miss, block
    case heal
    case statusProc(String)

    static func from(_ turn: CombatLog) -> VFXEffectType {
        if turn.isDodge { return .dodge }
        if turn.isMiss { return .miss }
        if turn.isBlocked { return .block }

        let dmgType = turn.damageType?.lowercased() ?? "physical"

        if turn.isCrit {
            switch dmgType {
            case "magical":     return .magicalCrit
            case "poison":      return .poisonCrit
            case "true_damage": return .trueCrit
            default:            return .physicalCrit
            }
        } else {
            switch dmgType {
            case "magical":     return .magicalHit
            case "poison":      return .poisonHit
            case "true_damage": return .trueHit
            default:            return .physicalHit
            }
        }
    }

    var isCrit: Bool {
        switch self {
        case .physicalCrit, .magicalCrit, .poisonCrit, .trueCrit: true
        default: false
        }
    }

    var duration: Double {
        switch self {
        case .physicalHit, .magicalHit, .poisonHit, .trueHit: 0.7
        case .physicalCrit, .magicalCrit, .poisonCrit, .trueCrit: 0.85
        case .dodge: 0.5
        case .miss: 0.4
        case .block: 0.6
        case .heal: 0.8
        case .statusProc: 0.6
        }
    }

    var primaryColor: Color {
        switch self {
        case .physicalHit, .physicalCrit: DarkFantasyTheme.gold
        case .magicalHit, .magicalCrit:  DarkFantasyTheme.classMage
        case .poisonHit, .poisonCrit:    DarkFantasyTheme.success
        case .trueHit, .trueCrit:        .white
        case .dodge:                      DarkFantasyTheme.textSecondary
        case .miss:                       DarkFantasyTheme.textTertiary
        case .block:                      DarkFantasyTheme.info
        case .heal:                       DarkFantasyTheme.success
        case .statusProc(let s):
            switch s.lowercased() {
            case "bleed":  DarkFantasyTheme.danger
            case "burn":   DarkFantasyTheme.stamina
            case "poison": DarkFantasyTheme.success
            case "freeze": DarkFantasyTheme.info
            case "stun":   DarkFantasyTheme.goldBright
            default:       DarkFantasyTheme.textSecondary
            }
        }
    }

    var secondaryColor: Color {
        switch self {
        case .physicalHit, .physicalCrit: DarkFantasyTheme.goldBright
        case .magicalHit, .magicalCrit:  DarkFantasyTheme.purple
        case .poisonHit, .poisonCrit:    DarkFantasyTheme.vfxPoisonGlow
        case .trueHit, .trueCrit:        DarkFantasyTheme.goldBright
        case .dodge:                      DarkFantasyTheme.textTertiary
        case .miss:                       DarkFantasyTheme.textDisabled
        case .block:                      DarkFantasyTheme.cyan
        case .heal:                       DarkFantasyTheme.goldBright
        case .statusProc(let s):
            switch s.lowercased() {
            case "bleed":  DarkFantasyTheme.textDanger
            case "burn":   DarkFantasyTheme.vfxBurnGlow
            case "poison": DarkFantasyTheme.vfxPoisonGlow
            case "freeze": DarkFantasyTheme.cyan
            case "stun":   DarkFantasyTheme.vfxStunGlow
            default:       DarkFantasyTheme.textTertiary
            }
        }
    }
}
