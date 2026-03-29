#if DEBUG
import Foundation

enum MockData {

    // MARK: - Character

    static let character = Character(
        id: "mock-char-001",
        characterName: "ShadowBlade",
        characterClass: .warrior,
        origin: .orc,
        gender: .male,
        avatar: nil,
        level: 25,
        experience: 3200,
        gold: 14500,
        gems: 320,
        currentHp: 680,
        maxHp: 850,
        currentStamina: 90,
        maxStamina: 120,
        pvpRating: 1847,
        pvpWins: 142,
        pvpLosses: 63,
        pvpWinStreak: 5,
        pvpLossStreak: 0,
        firstWinToday: false,
        freePvpToday: 2,
        inventorySlots: 30,
        strength: 45,
        agility: 22,
        vitality: 38,
        endurance: 30,
        intelligence: 12,
        wisdom: 15,
        luck: 18,
        charisma: 10,
        statPoints: 3,
        combatStance: CombatStance(attack: "head", defense: "chest"),
        prestige: 1,
        armor: 85,
        magicResist: 35
    )

    // MARK: - Combat

    static let playerId = "mock-char-001"
    static let enemyId = "mock-enemy-001"

    static let combatData = CombatData(
        player: CombatFighter(
            id: playerId,
            characterName: "ShadowBlade",
            characterClass: .warrior,
            origin: .orc,
            level: 25,
            maxHp: 850,
            currentHp: nil,
            avatar: nil
        ),
        enemy: CombatFighter(
            id: enemyId,
            characterName: "DarkMage99",
            characterClass: .mage,
            origin: .demon,
            level: 24,
            maxHp: 620,
            currentHp: nil,
            avatar: nil
        ),
        combatLog: [
            CombatLog(attackerId: playerId, action: "attack", targetZone: "chest", defendZone: "head", damage: 142, isCrit: false, isMiss: false, isDodge: false, isBlocked: false, statusApplied: nil, heal: nil, damageType: "physical", skillUsed: nil),
            CombatLog(attackerId: enemyId, action: "attack", targetZone: "head", defendZone: "chest", damage: 95, isCrit: false, isMiss: false, isDodge: false, isBlocked: false, statusApplied: nil, heal: nil, damageType: "magical", skillUsed: "Fireball"),
            CombatLog(attackerId: playerId, action: "attack", targetZone: "legs", defendZone: "legs", damage: 210, isCrit: true, isMiss: false, isDodge: false, isBlocked: false, statusApplied: "bleed", heal: nil, damageType: "physical", skillUsed: "Cleave"),
            CombatLog(attackerId: enemyId, action: "attack", targetZone: "chest", defendZone: "chest", damage: 0, isCrit: false, isMiss: false, isDodge: false, isBlocked: true, statusApplied: nil, heal: nil, damageType: "magical", skillUsed: nil),
            CombatLog(attackerId: playerId, action: "attack", targetZone: "head", defendZone: "head", damage: 178, isCrit: false, isMiss: false, isDodge: false, isBlocked: false, statusApplied: nil, heal: nil, damageType: "physical", skillUsed: nil),
        ],
        result: CombatResultInfo(
            isWin: true,
            winnerId: playerId,
            goldReward: 350,
            xpReward: 280,
            turnsTaken: 5,
            ratingChange: 18,
            firstWinBonus: true,
            leveledUp: false,
            newLevel: nil,
            statPointsAwarded: nil
        ),
        rewards: CombatRewards(gold: 350, xp: 280),
        loot: nil,
        source: "pvp"
    )

    static let combatResult = combatData

    // MARK: - Resolve Result

    static let resolveResult = ResolveResult(
        verified: true,
        clientMatches: true,
        serverWinnerId: playerId,
        goldReward: 350,
        xpReward: 280,
        ratingChange: 18,
        firstWinBonus: true,
        leveledUp: false,
        newLevel: nil,
        statPointsAwarded: nil,
        loot: [],
        staminaCurrent: 80,
        staminaMax: 120,
        matchId: "mock-match-001",
        durabilityDegraded: [],
        hpCurrent: 850,
        hpMax: 1000
    )

    // MARK: - Helpers

    /// Injects mock data into AppState so screens render with content.
    @MainActor static func injectIntoAppState(_ appState: AppState) {
        appState.currentCharacter = character
        appState.combatData = combatData
        appState.combatResult = combatResult
        appState.resolveResult = resolveResult
        appState.pendingLoot = []
    }
}
#endif
