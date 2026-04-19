// =============================================================================
// passives.ts — Passive tree bonus aggregation and validation
// =============================================================================

// --- Types ---

export interface PassiveBonuses {
  flatStats: Record<string, number>    // { str: 5, agi: 3 }
  percentStats: Record<string, number> // { str: 10 } = +10%
  flatDamage: number
  percentDamage: number
  flatCritChance: number
  flatDodgeChance: number
  flatHp: number
  percentHp: number
  flatArmor: number
  flatMagicResist: number
  percentArmor: number
  percentMagicResist: number
  lifesteal: number
  cooldownReduction: number
  damageReduction: number
}

export interface PassiveNodeData {
  bonusType: string
  bonusStat: string | null
  bonusValue: number
}

// --- Empty bonuses ---

export function emptyPassiveBonuses(): PassiveBonuses {
  return {
    flatStats: {},
    percentStats: {},
    flatDamage: 0,
    percentDamage: 0,
    flatCritChance: 0,
    flatDodgeChance: 0,
    flatHp: 0,
    percentHp: 0,
    flatArmor: 0,
    flatMagicResist: 0,
    percentArmor: 0,
    percentMagicResist: 0,
    lifesteal: 0,
    cooldownReduction: 0,
    damageReduction: 0,
  }
}

// --- Aggregation ---

/**
 * Aggregate all passive bonuses from a list of unlocked passive nodes.
 * Each node contributes its bonus based on bonusType.
 */
export function aggregatePassiveBonuses(nodes: PassiveNodeData[]): PassiveBonuses {
  const bonuses = emptyPassiveBonuses()

  for (const node of nodes) {
    const { bonusType, bonusStat, bonusValue } = node

    switch (bonusType) {
      case 'flat_stat':
        if (bonusStat) {
          bonuses.flatStats[bonusStat] = (bonuses.flatStats[bonusStat] ?? 0) + bonusValue
        }
        break
      case 'percent_stat':
        if (bonusStat) {
          bonuses.percentStats[bonusStat] = (bonuses.percentStats[bonusStat] ?? 0) + bonusValue
        }
        break
      case 'flat_damage':
        bonuses.flatDamage += bonusValue
        break
      case 'percent_damage':
        bonuses.percentDamage += bonusValue
        break
      case 'flat_crit_chance':
        bonuses.flatCritChance += bonusValue
        break
      case 'flat_dodge_chance':
        bonuses.flatDodgeChance += bonusValue
        break
      case 'flat_hp':
        bonuses.flatHp += bonusValue
        break
      case 'percent_hp':
        bonuses.percentHp += bonusValue
        break
      case 'flat_armor':
        bonuses.flatArmor += bonusValue
        break
      case 'flat_magic_resist':
        bonuses.flatMagicResist += bonusValue
        break
      case 'percent_armor':
        bonuses.percentArmor += bonusValue
        break
      case 'percent_magic_resist':
        bonuses.percentMagicResist += bonusValue
        break
      case 'lifesteal':
        bonuses.lifesteal += bonusValue
        break
      case 'cooldown_reduction':
        bonuses.cooldownReduction += bonusValue
        break
      case 'damage_reduction':
        bonuses.damageReduction += bonusValue
        break
    }
  }

  return bonuses
}

// --- Rank Cost Derivation (Talents v2, 2026-04-19) ---

/**
 * Derive per-rank SP costs from a node's total cost.
 *
 * Talents v2 convention (see docs/06_game_systems/SKILL_TREE_DESIGN_V2.md §2):
 *   - Foundation + Specialization nodes (3 ranks): total cost 6 → [1, 2, 3]
 *   - Keystone nodes (single rank): total cost 3 → [3]
 *   - Ultimate nodes (single rank): total cost 5 → [5]
 *
 * Any node outside these buckets is treated as single-rank and charges the full cost.
 * This keeps legacy single-rank nodes working without a data migration — they unlock
 * once at currentRank=1, paying `cost` SP.
 */
export function getRankCosts(totalCost: number): number[] {
  if (totalCost === 6) return [1, 2, 3]
  return [totalCost]
}

/**
 * Max rank derived from total cost — mirrors `getRankCosts`.
 */
export function getMaxRank(totalCost: number): number {
  return getRankCosts(totalCost).length
}

// --- Tree Validation ---

/**
 * Check whether a passive node can be unlocked by a character.
 * Rules:
 * 1. Start nodes can always be unlocked (no prerequisite).
 * 2. Non-start nodes must be connected (via any direction) to at least one already-unlocked node.
 *
 * @param nodeId        The node the player wants to unlock
 * @param connections   All edges in the passive tree [{fromId, toId}]
 * @param unlockedIds   Set of node IDs the player has already unlocked
 * @param isStartNode   Whether the target node is a start node
 */
export function canUnlockNode(
  nodeId: string,
  connections: Array<{ fromId: string; toId: string }>,
  unlockedIds: Set<string>,
  isStartNode: boolean,
): boolean {
  // Start nodes can always be unlocked
  if (isStartNode) return true

  // Non-start nodes must be adjacent to at least one unlocked node
  for (const conn of connections) {
    // Check both directions (undirected graph)
    if (conn.fromId === nodeId && unlockedIds.has(conn.toId)) return true
    if (conn.toId === nodeId && unlockedIds.has(conn.fromId)) return true
  }

  return false
}
