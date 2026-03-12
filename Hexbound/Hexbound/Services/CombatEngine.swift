import Foundation

// =============================================================================
// CombatEngine.swift — Client-side deterministic combat simulation
// Mirrors backend combat.ts exactly. Given the same seed and stats, produces
// identical results on both client and server.
// =============================================================================

// MARK: - Seeded PRNG (Mulberry32 — identical to backend)

struct SeededRng {
    private var state: UInt32

    init(seed: Int) {
        state = UInt32(bitPattern: Int32(truncatingIfNeeded: seed))
    }

    mutating func next() -> Double {
        state = state &+ 0x6D2B79F5
        var t = Self.imul(state ^ (state >> 15), 1 | state)
        t = (t &+ Self.imul(t ^ (t >> 7), 61 | t)) ^ t
        return Double(t ^ (t >> 14)) / 4294967296.0
    }

    /// Replicates JavaScript's Math.imul (32-bit integer multiply)
    private static func imul(_ a: UInt32, _ b: UInt32) -> UInt32 {
        let result = Int64(Int32(bitPattern: a)) &* Int64(Int32(bitPattern: b))
        return UInt32(bitPattern: Int32(truncatingIfNeeded: result))
    }
}

// MARK: - Combat Config (from server)

struct CombatConfig {
    let maxTurns: Int
    let minDamage: Int
    let critMultiplier: Double
    let maxCritChance: Double
    let maxDodgeChance: Double
    let rogueDodgeBonus: Double
    let tankDamageReduction: Double
    let damageVariance: Double
    let poisonArmorPenetration: Double
    let critPerLuk: Double
    let critPerAgi: Double
    let dodgePerAgi: Double
    let dodgePerLuk: Double
    let chaIntimidationPerPoint: Double
    let chaIntimidationCap: Double

    /// Default config matching backend balance.ts
    static let `default` = CombatConfig(
        maxTurns: 15,
        minDamage: 1,
        critMultiplier: 1.5,
        maxCritChance: 50,
        maxDodgeChance: 30,
        rogueDodgeBonus: 3,
        tankDamageReduction: 0.85,
        damageVariance: 0.10,
        poisonArmorPenetration: 0.3,
        critPerLuk: 0.7,
        critPerAgi: 0.15,
        dodgePerAgi: 0.2,
        dodgePerLuk: 0.1,
        chaIntimidationPerPoint: 0.15,
        chaIntimidationCap: 15
    )

    init(from dict: [String: Any]) {
        maxTurns = dict["max_turns"] as? Int ?? 15
        minDamage = dict["min_damage"] as? Int ?? 1
        critMultiplier = dict["crit_multiplier"] as? Double ?? 1.5
        maxCritChance = dict["max_crit_chance"] as? Double ?? 50
        maxDodgeChance = dict["max_dodge_chance"] as? Double ?? 30
        rogueDodgeBonus = dict["rogue_dodge_bonus"] as? Double ?? 3
        tankDamageReduction = dict["tank_damage_reduction"] as? Double ?? 0.85
        damageVariance = dict["damage_variance"] as? Double ?? 0.10
        poisonArmorPenetration = dict["poison_armor_penetration"] as? Double ?? 0.3
        critPerLuk = dict["crit_per_luk"] as? Double ?? 0.7
        critPerAgi = dict["crit_per_agi"] as? Double ?? 0.15
        dodgePerAgi = dict["dodge_per_agi"] as? Double ?? 0.2
        dodgePerLuk = dict["dodge_per_luk"] as? Double ?? 0.1
        chaIntimidationPerPoint = dict["cha_intimidation_per_point"] as? Double ?? 0.15
        chaIntimidationCap = dict["cha_intimidation_cap"] as? Double ?? 15
    }

    init(maxTurns: Int, minDamage: Int, critMultiplier: Double, maxCritChance: Double,
         maxDodgeChance: Double, rogueDodgeBonus: Double, tankDamageReduction: Double,
         damageVariance: Double, poisonArmorPenetration: Double,
         critPerLuk: Double, critPerAgi: Double, dodgePerAgi: Double, dodgePerLuk: Double,
         chaIntimidationPerPoint: Double, chaIntimidationCap: Double) {
        self.maxTurns = maxTurns
        self.minDamage = minDamage
        self.critMultiplier = critMultiplier
        self.maxCritChance = maxCritChance
        self.maxDodgeChance = maxDodgeChance
        self.rogueDodgeBonus = rogueDodgeBonus
        self.tankDamageReduction = tankDamageReduction
        self.damageVariance = damageVariance
        self.poisonArmorPenetration = poisonArmorPenetration
        self.critPerLuk = critPerLuk
        self.critPerAgi = critPerAgi
        self.dodgePerAgi = dodgePerAgi
        self.dodgePerLuk = dodgePerLuk
        self.chaIntimidationPerPoint = chaIntimidationPerPoint
        self.chaIntimidationCap = chaIntimidationCap
    }
}

// MARK: - Fighter Stats (from /prepare response)

struct FighterStats {
    let id: String
    let name: String
    let characterClass: String
    let level: Int
    let str: Int
    let agi: Int
    let vit: Int
    let end: Int
    let int: Int
    let wis: Int
    let luk: Int
    let cha: Int
    let maxHp: Int
    let armor: Int
    let magicResist: Int
    let avatar: String?
    let combatStance: [String: Any]?
    let equippedSkills: [[String: Any]]
    let passiveBonuses: PassiveBonus

    init(from dict: [String: Any]) {
        id = dict["id"] as? String ?? ""
        name = dict["name"] as? String ?? ""
        characterClass = dict["class"] as? String ?? "warrior"
        level = dict["level"] as? Int ?? 1
        str = dict["str"] as? Int ?? 10
        agi = dict["agi"] as? Int ?? 10
        vit = dict["vit"] as? Int ?? 10
        end = dict["end"] as? Int ?? 10
        int = dict["int"] as? Int ?? 10
        wis = dict["wis"] as? Int ?? 10
        luk = dict["luk"] as? Int ?? 10
        cha = dict["cha"] as? Int ?? 10
        maxHp = dict["max_hp"] as? Int ?? 100
        armor = dict["armor"] as? Int ?? 0
        magicResist = dict["magic_resist"] as? Int ?? 0
        avatar = dict["avatar"] as? String
        combatStance = dict["combat_stance"] as? [String: Any]
        equippedSkills = dict["equipped_skills"] as? [[String: Any]] ?? []
        passiveBonuses = PassiveBonus(from: dict["passive_bonuses"] as? [String: Any] ?? [:])
    }
}

struct PassiveBonus {
    let flatDamage: Double
    let percentDamage: Double
    let flatCritChance: Double
    let flatDodgeChance: Double
    let lifesteal: Double
    let damageReduction: Double

    init(from dict: [String: Any]) {
        flatDamage = dict["flat_damage"] as? Double ?? 0
        percentDamage = dict["percent_damage"] as? Double ?? 0
        flatCritChance = dict["flat_crit_chance"] as? Double ?? 0
        flatDodgeChance = dict["flat_dodge_chance"] as? Double ?? 0
        lifesteal = dict["lifesteal"] as? Double ?? 0
        damageReduction = dict["damage_reduction"] as? Double ?? 0
    }
}

// MARK: - Stance

struct StanceModifiers {
    let offense: Double
    let defense: Double
    let crit: Double
    let dodge: Double

    static let `default` = StanceModifiers(offense: 0, defense: 0, crit: 0, dodge: 0)

    init(offense: Double, defense: Double, crit: Double, dodge: Double) {
        self.offense = offense
        self.defense = defense
        self.crit = crit
        self.dodge = dodge
    }

    /// Compute zone-aware stance modifiers given own stance and opponent's stance
    static func fromZones(myStance: ParsedZoneStance, opponentStance: ParsedZoneStance) -> StanceModifiers {
        let atkBonus = ZoneStanceConfig.attackZones[myStance.attack]
            ?? (offense: 5.0, crit: 0.0)
        let defBonus = ZoneStanceConfig.defenseZones[myStance.defense]
            ?? (defense: 10.0, dodge: 0.0)

        let offenseMismatch = myStance.attack != opponentStance.defense
            ? ZoneStanceConfig.mismatchOffenseBonus : 0.0
        let defenseMatch = opponentStance.attack == myStance.defense
            ? ZoneStanceConfig.matchDefenseBonus : 0.0

        return StanceModifiers(
            offense: atkBonus.offense + offenseMismatch,
            defense: defBonus.defense + defenseMatch,
            crit: atkBonus.crit,
            dodge: defBonus.dodge
        )
    }
}

// MARK: - Zone-Based Stance

struct ParsedZoneStance {
    let attack: String
    let defense: String

    static let `default` = ParsedZoneStance(attack: "chest", defense: "chest")

    init(attack: String, defense: String) {
        self.attack = attack
        self.defense = defense
    }

    init(from dict: [String: Any]?) {
        let validZones = ["head", "chest", "legs"]
        guard let dict = dict,
              let atk = dict["attack"] as? String,
              let def = dict["defense"] as? String,
              validZones.contains(atk),
              validZones.contains(def)
        else {
            self = .default
            return
        }
        self.attack = atk
        self.defense = def
    }
}

enum ZoneStanceConfig {
    static let attackZones: [String: (offense: Double, crit: Double)] = [
        "head":  (offense: 10, crit: 5),
        "chest": (offense: 5,  crit: 0),
        "legs":  (offense: 0,  crit: -3),
    ]

    static let defenseZones: [String: (defense: Double, dodge: Double)] = [
        "head":  (defense: 0,  dodge: 8),
        "chest": (defense: 10, dodge: 0),
        "legs":  (defense: 5,  dodge: 3),
    ]

    static let mismatchOffenseBonus: Double = 5
    static let matchDefenseBonus: Double = 15
}

// MARK: - Skill Cooldown State

typealias SkillCooldownState = [String: Int]

// MARK: - Combat Engine

final class CombatEngine {
    private var rng: SeededRng
    private let config: CombatConfig

    init(seed: Int, config: CombatConfig = .default) {
        self.rng = SeededRng(seed: seed)
        self.config = config
    }

    /// Run full combat simulation. Returns CombatData that the UI can play back.
    func simulate(player: FighterStats, enemy: FighterStats) -> CombatData {
        let hpA = player.maxHp
        let hpD = enemy.maxHp

        let zoneA = ParsedZoneStance(from: player.combatStance)
        let zoneD = ParsedZoneStance(from: enemy.combatStance)
        let stanceA = StanceModifiers.fromZones(myStance: zoneA, opponentStance: zoneD)
        let stanceD = StanceModifiers.fromZones(myStance: zoneD, opponentStance: zoneA)
        let passivesA = player.passiveBonuses
        let passivesD = enemy.passiveBonuses

        var cooldownA: SkillCooldownState = [:]
        var cooldownD: SkillCooldownState = [:]

        // Determine turn order by AGI
        let first: FighterStats
        let second: FighterStats
        let stanceFirst: StanceModifiers
        let stanceSecond: StanceModifiers
        let passivesFirst: PassiveBonus
        let passivesSecond: PassiveBonus
        var hpFirst: Int
        var hpSecond: Int
        let maxHpFirst: Int
        let maxHpSecond: Int
        let zoneFirst: ParsedZoneStance
        let zoneSecond: ParsedZoneStance

        if enemy.agi > player.agi {
            first = enemy; second = player
            stanceFirst = stanceD; stanceSecond = stanceA
            passivesFirst = passivesD; passivesSecond = passivesA
            hpFirst = hpD; hpSecond = hpA
            maxHpFirst = enemy.maxHp; maxHpSecond = player.maxHp
            zoneFirst = zoneD; zoneSecond = zoneA
        } else {
            first = player; second = enemy
            stanceFirst = stanceA; stanceSecond = stanceD
            passivesFirst = passivesA; passivesSecond = passivesD
            hpFirst = hpA; hpSecond = hpD
            maxHpFirst = player.maxHp; maxHpSecond = enemy.maxHp
            zoneFirst = zoneA; zoneSecond = zoneD
        }

        // Cooldowns must follow the same AGI-based ordering as other variables.
        // cooldownA tracks player's skills, cooldownD tracks enemy's skills.
        // "first"/"second" reference whoever acts in that order, not A/D identity.
        let cooldownFirstIsA = !(enemy.agi > player.agi)

        var turns: [CombatLog] = []

        for t in 1...config.maxTurns {
            // First attacks second
            let r1: (turn: CombatLog, newDefenderHp: Int, healAmount: Int)
            if cooldownFirstIsA {
                r1 = resolveAttack(
                    turnNumber: t, attacker: first, defender: second,
                    defenderHp: hpSecond, stanceAtk: stanceFirst, stanceDef: stanceSecond,
                    passivesAtk: passivesFirst, passivesDef: passivesSecond,
                    cooldownState: &cooldownA,
                    attackerZone: zoneFirst.attack, defenderZone: zoneSecond.defense
                )
            } else {
                r1 = resolveAttack(
                    turnNumber: t, attacker: first, defender: second,
                    defenderHp: hpSecond, stanceAtk: stanceFirst, stanceDef: stanceSecond,
                    passivesAtk: passivesFirst, passivesDef: passivesSecond,
                    cooldownState: &cooldownD,
                    attackerZone: zoneFirst.attack, defenderZone: zoneSecond.defense
                )
            }
            turns.append(r1.turn)
            hpSecond = r1.newDefenderHp
            if r1.healAmount > 0 { hpFirst = min(hpFirst + r1.healAmount, maxHpFirst) }
            if hpSecond <= 0 {
                return buildResult(winnerId: first.id, loserId: second.id, turns: turns, player: player, enemy: enemy)
            }

            // Second attacks first
            let r2: (turn: CombatLog, newDefenderHp: Int, healAmount: Int)
            if cooldownFirstIsA {
                r2 = resolveAttack(
                    turnNumber: t, attacker: second, defender: first,
                    defenderHp: hpFirst, stanceAtk: stanceSecond, stanceDef: stanceFirst,
                    passivesAtk: passivesSecond, passivesDef: passivesFirst,
                    cooldownState: &cooldownD,
                    attackerZone: zoneSecond.attack, defenderZone: zoneFirst.defense
                )
            } else {
                r2 = resolveAttack(
                    turnNumber: t, attacker: second, defender: first,
                    defenderHp: hpFirst, stanceAtk: stanceSecond, stanceDef: stanceFirst,
                    passivesAtk: passivesSecond, passivesDef: passivesFirst,
                    cooldownState: &cooldownA,
                    attackerZone: zoneSecond.attack, defenderZone: zoneFirst.defense
                )
            }
            turns.append(r2.turn)
            hpFirst = r2.newDefenderHp
            if r2.healAmount > 0 { hpSecond = min(hpSecond + r2.healAmount, maxHpSecond) }
            if hpFirst <= 0 {
                return buildResult(winnerId: second.id, loserId: first.id, turns: turns, player: player, enemy: enemy)
            }

            // Tick cooldowns
            tickCooldowns(&cooldownA)
            tickCooldowns(&cooldownD)
        }

        // Timeout — higher HP% wins
        let pctFirst = Double(hpFirst) / Double(maxHpFirst)
        let pctSecond = Double(hpSecond) / Double(maxHpSecond)

        if pctFirst >= pctSecond {
            return buildResult(winnerId: first.id, loserId: second.id, turns: turns, player: player, enemy: enemy)
        } else {
            return buildResult(winnerId: second.id, loserId: first.id, turns: turns, player: player, enemy: enemy)
        }
    }

    // MARK: - Resolve Attack

    private func resolveAttack(
        turnNumber: Int, attacker: FighterStats, defender: FighterStats,
        defenderHp: Int, stanceAtk: StanceModifiers, stanceDef: StanceModifiers,
        passivesAtk: PassiveBonus, passivesDef: PassiveBonus,
        cooldownState: inout SkillCooldownState,
        attackerZone: String? = nil, defenderZone: String? = nil
    ) -> (turn: CombatLog, newDefenderHp: Int, healAmount: Int) {

        // Dodge check
        let totalDodge = dodgeChance(defender: defender, stanceMod: stanceDef) + passivesDef.flatDodgeChance
        let isDodge = rollPercent() < min(totalDodge, config.maxDodgeChance)

        if isDodge {
            let turn = CombatLog(
                attackerId: attacker.id, action: "dodge", targetZone: attackerZone, defendZone: defenderZone,
                damage: 0, isCrit: false, isMiss: false, isDodge: true, isBlocked: false,
                statusApplied: nil, heal: nil, damageType: nil, skillUsed: nil
            )
            return (turn, defenderHp, 0)
        }

        // Try to use a skill
        let skill = selectSkill(skills: attacker.equippedSkills, cooldowns: cooldownState)
        var raw: Double
        var dmgType: String
        var skillName: String?

        if let skill = skill {
            putOnCooldown(cooldowns: &cooldownState, skill: skill)

            // Self-buff — no damage
            if (skill["target_type"] as? String) == "self_buff" {
                var selfHeal = 0
                if let effect = skill["effect_json"] as? [String: Any],
                   let heal = effect["heal"] as? Int { selfHeal = heal }

                let turn = CombatLog(
                    attackerId: attacker.id, action: "skill", targetZone: attackerZone, defendZone: defenderZone,
                    damage: 0, isCrit: false, isMiss: false, isDodge: false, isBlocked: false,
                    statusApplied: nil, heal: selfHeal > 0 ? selfHeal : nil,
                    damageType: skill["damage_type"] as? String,
                    skillUsed: skill["name"] as? String
                )
                return (turn, defenderHp, selfHeal)
            }

            let result = calculateSkillDamage(skill: skill, attacker: attacker)
            raw = applyVariance(result.rawDamage)
            dmgType = result.damageType
            skillName = result.skillName
        } else {
            raw = applyVariance(baseDamage(attacker))
            dmgType = autoAttackDamageType(attacker.characterClass)
        }

        // Passive bonuses
        raw += passivesAtk.flatDamage
        raw *= 1 + passivesAtk.percentDamage / 100

        // Resistance reduction
        let reduced = reduceDamageByType(raw: raw, defender: defender, damageType: dmgType)
        let withClass = applyClassReduction(damage: reduced, defenderClass: defender.characterClass)

        // Crit check
        let totalCrit = critChance(attacker: attacker, stanceMod: stanceAtk) + passivesAtk.flatCritChance
        let isCrit = rollPercent() < min(totalCrit, config.maxCritChance)
        var dmg = isCrit ? withClass * config.critMultiplier : withClass

        // Stance modifiers
        dmg = dmg * (1 + stanceAtk.offense / 100)
        dmg = dmg * (1 - stanceDef.defense / 100)

        // CHA intimidation: defender's CHA reduces attacker's damage
        let intimReduction = chaIntimidation(defenderCha: defender.cha)
        if intimReduction > 0 {
            dmg *= 1 - intimReduction
        }

        // Defender's passive damage reduction
        if passivesDef.damageReduction > 0 {
            dmg *= 1 - min(passivesDef.damageReduction, 50) / 100
        }

        let finalDmg = max(Int(dmg), config.minDamage)
        let newDefenderHp = max(defenderHp - finalDmg, 0)

        var healAmount = 0
        if passivesAtk.lifesteal > 0 {
            healAmount = Int(Double(finalDmg) * passivesAtk.lifesteal / 100)
        }

        let turn = CombatLog(
            attackerId: attacker.id,
            action: skillName != nil ? "skill" : "attack",
            targetZone: attackerZone, defendZone: defenderZone,
            damage: finalDmg, isCrit: isCrit, isMiss: false, isDodge: false, isBlocked: false,
            statusApplied: nil,
            heal: healAmount > 0 ? healAmount : nil,
            damageType: dmgType,
            skillUsed: skillName
        )
        return (turn, newDefenderHp, healAmount)
    }

    // MARK: - Helpers

    private func baseDamage(_ c: FighterStats) -> Double {
        switch c.characterClass {
        case "warrior": return Double(c.str) * 1.5 + Double(c.level) * 2
        case "tank":    return Double(c.str) * 1.3 + Double(c.vit) * 0.3 + Double(c.level) * 2
        case "rogue":   return Double(c.agi) * 1.5 + Double(c.level) * 2
        case "mage":    return Double(c.int) * 1.2 + Double(c.wis) * 0.5 + Double(c.level) * 2
        default:        return Double(c.str) * 1.5 + Double(c.level) * 2
        }
    }

    private func autoAttackDamageType(_ cls: String) -> String {
        switch cls {
        case "mage": return "magical"
        case "rogue": return "poison"
        default: return "physical"
        }
    }

    private func reduceDamageByType(raw: Double, defender: FighterStats, damageType: String) -> Double {
        if damageType == "true_damage" { return raw }
        if damageType == "poison" {
            let effectiveArmor = Double(max(0, defender.armor)) * (1 - config.poisonArmorPenetration)
            return raw * (100 / (100 + effectiveArmor))
        }
        let resist = damageType == "magical" ? defender.magicResist : defender.armor
        let effectiveResist = Double(max(0, resist))
        return raw * (100 / (100 + effectiveResist))
    }

    private func applyClassReduction(damage: Double, defenderClass: String) -> Double {
        if defenderClass == "tank" { return damage * config.tankDamageReduction }
        return damage
    }

    private func critChance(attacker: FighterStats, stanceMod: StanceModifiers) -> Double {
        return min(Double(attacker.luk) * config.critPerLuk + Double(attacker.agi) * config.critPerAgi + stanceMod.crit, config.maxCritChance)
    }

    private func dodgeChance(defender: FighterStats, stanceMod: StanceModifiers) -> Double {
        let classBonus: Double = defender.characterClass == "rogue" ? config.rogueDodgeBonus : 0
        return min(Double(defender.agi) * config.dodgePerAgi + Double(defender.luk) * config.dodgePerLuk + classBonus + stanceMod.dodge, config.maxDodgeChance)
    }

    private func chaIntimidation(defenderCha: Int) -> Double {
        return min(Double(defenderCha) * config.chaIntimidationPerPoint, config.chaIntimidationCap) / 100
    }

    private func applyVariance(_ damage: Double) -> Double {
        let multiplier = (1 - config.damageVariance) + rng.next() * (config.damageVariance * 2)
        return damage * multiplier
    }

    private func rollPercent() -> Double {
        return rng.next() * 100
    }

    // MARK: - Skills

    private func selectSkill(skills: [[String: Any]], cooldowns: SkillCooldownState) -> [String: Any]? {
        for skill in skills {
            guard let key = skill["skill_key"] as? String,
                  (skill["damage_base"] as? Double) != nil || (skill["damage_base"] as? Int) != nil
            else { continue }
            if (cooldowns[key] ?? 0) <= 0 {
                return skill
            }
        }
        return nil
    }

    private func putOnCooldown(cooldowns: inout SkillCooldownState, skill: [String: Any]) {
        guard let key = skill["skill_key"] as? String else { return }
        let cd = skill["cooldown"] as? Int ?? 0
        cooldowns[key] = cd
    }

    private func tickCooldowns(_ cooldowns: inout SkillCooldownState) {
        for key in cooldowns.keys {
            if let val = cooldowns[key], val > 0 {
                cooldowns[key] = val - 1
            }
        }
    }

    private func calculateSkillDamage(skill: [String: Any], attacker: FighterStats) -> (rawDamage: Double, damageType: String, skillName: String) {
        let dmgBase = (skill["damage_base"] as? Double) ?? Double(skill["damage_base"] as? Int ?? 0)
        let dmgType = skill["damage_type"] as? String ?? "physical"
        let name = skill["name"] as? String ?? "Skill"

        var total = dmgBase
        if let scaling = skill["damage_scaling"] as? [String: Any] {
            for (stat, mult) in scaling {
                let multiplier = (mult as? Double) ?? Double(mult as? Int ?? 0)
                let statVal: Int
                switch stat {
                case "str": statVal = attacker.str
                case "agi": statVal = attacker.agi
                case "int": statVal = attacker.int
                case "wis": statVal = attacker.wis
                case "vit": statVal = attacker.vit
                case "end": statVal = attacker.end
                case "luk": statVal = attacker.luk
                default: statVal = 0
                }
                total += Double(statVal) * multiplier
            }
        }

        // Rank scaling
        let rank = skill["rank"] as? Int ?? 1
        let rankScaling = (skill["rank_scaling"] as? Double) ?? 0.1
        total *= 1 + Double(rank - 1) * rankScaling

        return (total, dmgType, name)
    }

    // MARK: - Build Result

    private func buildResult(winnerId: String, loserId: String, turns: [CombatLog], player: FighterStats, enemy: FighterStats) -> CombatData {
        let isWin = winnerId == player.id

        let playerFighter = CombatFighter(
            id: player.id,
            characterName: player.name,
            characterClass: CharacterClass(rawValue: player.characterClass) ?? .warrior,
            origin: .human,
            level: player.level,
            maxHp: player.maxHp,
            currentHp: nil,
            avatar: player.avatar
        )
        let enemyFighter = CombatFighter(
            id: enemy.id,
            characterName: enemy.name,
            characterClass: CharacterClass(rawValue: enemy.characterClass) ?? .warrior,
            origin: .human,
            level: enemy.level,
            maxHp: enemy.maxHp,
            currentHp: nil,
            avatar: enemy.avatar
        )

        // Result info will be filled in by the resolve endpoint; for now use optimistic values
        let resultInfo = CombatResultInfo(
            isWin: isWin,
            winnerId: winnerId,
            goldReward: nil,
            xpReward: nil,
            turnsTaken: turns.count,
            ratingChange: nil,
            firstWinBonus: nil,
            leveledUp: nil,
            newLevel: nil,
            statPointsAwarded: nil
        )

        return CombatData(
            player: playerFighter,
            enemy: enemyFighter,
            combatLog: turns,
            result: resultInfo,
            rewards: nil,
            source: "pvp"
        )
    }
}


