/**
 * find-tutorial-seed.ts — Offline brute-force seed search for scripted tutorial fights.
 *
 * PURPOSE:
 *   The scripted tutorial fight (W2.D3) guarantees hero victory against a synthetic
 *   opponent. Determinism comes from `runCombat(hero, opponent, seed)`. We need a seed
 *   that produces a valid hero victory for ALL 4 classes at default Lv1 loadout,
 *   in ≤ maxTurnsForVictory, so any class the player picks wins in the right pacing.
 *
 *   This script brute-forces seeds in [0, 1_000_000) and stops at the first seed where:
 *     - All 4 classes (warrior, rogue, mage, tank) win as the hero
 *     - Each fight completes in ≤ opponent.maxTurnsForVictory turns
 *
 *   The result is a single integer to paste into `tutorial-opponents.ts`
 *   as `guaranteedVictorySeed` for each entry.
 *
 * USAGE:
 *   cd backend
 *   tsx scripts/find-tutorial-seed.ts
 *
 *   Optional: specify a single opponent key to search for:
 *   tsx scripts/find-tutorial-seed.ts tutorial_orc_grunt
 *
 *   Optional: override max seed range:
 *   SEED_MAX=5000000 tsx scripts/find-tutorial-seed.ts
 *
 * RE-RUN CONDITIONS:
 *   - After any balance change (combat formulas, stat scaling, class multipliers)
 *   - After adding a new entry to TUTORIAL_OPPONENTS
 *   - If the seed drift sanity check in /api/tutorial/scripted-fight/resolve fires
 *
 * FAILURE MODE:
 *   If no seed is found in [0, SEED_MAX), the opponent is too strong. Weaken its
 *   stats in tutorial-opponents.ts (lower str, lower maxHp, etc.) and re-run.
 *
 * See: docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
 */

import {
  runCombat,
  initCombatConfig,
  type CharacterStats,
  type CharacterClassType,
} from '../src/lib/game/combat'
import {
  TUTORIAL_OPPONENTS,
  listScriptedOpponentKeys,
  type ScriptedOpponentKey,
  type ScriptedOpponent,
} from '../src/lib/game/tutorial-opponents'

// ── Config ────────────────────────────────────────────────────────────
const SEED_MAX = Number(process.env.SEED_MAX ?? 1_000_000)
const CLASSES: CharacterClassType[] = ['warrior', 'rogue', 'mage', 'tank']

// ── Default Lv1 hero builder ──────────────────────────────────────────
// Mirrors the class stat emphasis used in combat-simulator.buildSimCharacter,
// but simplified for Lv1 (no gear, no derived stats recomputation — we hardcode
// maxHp/armor/magicResist to match what applyCharacterPostProcessing produces
// for a default Lv1 character).
//
// IMPORTANT: Keep this in sync with OnboardingViewModel's default Lv1 stats.
// If that file diverges, regenerate the seed.
function buildDefaultLv1Hero(cls: CharacterClassType): CharacterStats {
  // Base stats for Lv1 — 10 across the board before class multipliers.
  const baseStats = {
    str: 10,
    agi: 10,
    vit: 10,
    end: 10,
    int: 10,
    wis: 10,
    luk: 10,
    cha: 10,
  }

  // Apply class emphasis (matches combat-simulator.ts logic).
  switch (cls) {
    case 'warrior':
      baseStats.str = Math.round(baseStats.str * 1.4) // 14
      baseStats.vit = Math.round(baseStats.vit * 1.2) // 12
      break
    case 'tank':
      baseStats.vit = Math.round(baseStats.vit * 1.4) // 14
      baseStats.end = Math.round(baseStats.end * 1.4) // 14
      break
    case 'rogue':
      baseStats.agi = Math.round(baseStats.agi * 1.4) // 14
      baseStats.luk = Math.round(baseStats.luk * 1.2) // 12
      break
    case 'mage':
      baseStats.int = Math.round(baseStats.int * 1.4) // 14
      baseStats.wis = Math.round(baseStats.wis * 1.2) // 12
      break
  }

  // Derived stats — approximate values matching applyCharacterPostProcessing
  // for default Lv1. VIT × 10 + 50 → maxHp, END × 0.8 → armor, WIS × 0.5 → magicResist.
  const maxHp = baseStats.vit * 10 + 50
  const armor = Math.round(baseStats.end * 0.8)
  const magicResist = Math.round(baseStats.wis * 0.5)

  return {
    id: `hero_${cls}`,
    name: `Hero (${cls})`,
    class: cls,
    level: 1,
    ...baseStats,
    maxHp,
    currentHp: maxHp,
    armor,
    magicResist,
    equippedSkills: [],
    passiveBonuses: undefined,
    combatStance: null,
  }
}

// ── Seed search for a single opponent ─────────────────────────────────
interface SeedSearchResult {
  opponentKey: ScriptedOpponentKey
  seed: number | null
  perClassTurns: Record<string, number>
  totalCandidatesTried: number
}

async function findSeedForOpponent(
  opponent: ScriptedOpponent,
): Promise<SeedSearchResult> {
  console.log(`\n🔍 Searching seed for opponent: ${opponent.displayName} (${opponent.key})`)
  console.log(`   Max turns allowed: ${opponent.maxTurnsForVictory}`)
  console.log(`   Range: [0, ${SEED_MAX.toLocaleString()})`)

  const heroes = CLASSES.map(buildDefaultLv1Hero)

  let candidatesTried = 0
  const perClassTurns: Record<string, number> = {}

  for (let seed = 0; seed < SEED_MAX; seed++) {
    candidatesTried++

    // Progress indicator every 50k seeds.
    if (seed > 0 && seed % 50_000 === 0) {
      process.stdout.write(`   …${(seed / 1000).toFixed(0)}k seeds tried\r`)
    }

    let allWin = true
    const turnsThisSeed: Record<string, number> = {}

    for (const hero of heroes) {
      // Deep clone opponent so we don't mutate the catalog copy between fights.
      const opponentCopy: CharacterStats = {
        ...opponent.character,
        currentHp: opponent.character.maxHp,
      }
      const heroCopy: CharacterStats = {
        ...hero,
        currentHp: hero.maxHp,
      }

      const result = await runCombat(heroCopy, opponentCopy, seed)

      if (result.winnerId !== heroCopy.id) {
        allWin = false
        break
      }

      if (result.totalTurns > opponent.maxTurnsForVictory) {
        allWin = false
        break
      }

      turnsThisSeed[hero.class] = result.totalTurns
    }

    if (allWin) {
      console.log(`\n✅ Found seed: ${seed}`)
      console.log(`   Per-class turn counts: ${JSON.stringify(turnsThisSeed)}`)
      return {
        opponentKey: opponent.key,
        seed,
        perClassTurns: turnsThisSeed,
        totalCandidatesTried: candidatesTried,
      }
    }
  }

  console.log(`\n❌ No seed found in [0, ${SEED_MAX}) for ${opponent.key}`)
  return {
    opponentKey: opponent.key,
    seed: null,
    perClassTurns: {},
    totalCandidatesTried: candidatesTried,
  }
}

// ── Main ──────────────────────────────────────────────────────────────
async function main() {
  console.log('━━━ Tutorial Seed Search ━━━')
  console.log(`SEED_MAX = ${SEED_MAX.toLocaleString()}\n`)

  await initCombatConfig()
  console.log('✓ Combat config initialized')

  // Parse CLI arg — optional opponent key filter.
  const requestedKey = process.argv[2] as ScriptedOpponentKey | undefined
  const keysToSearch = requestedKey
    ? [requestedKey]
    : listScriptedOpponentKeys()

  if (requestedKey && !TUTORIAL_OPPONENTS[requestedKey]) {
    console.error(`Unknown opponent key: ${requestedKey}`)
    console.error(`Available: ${listScriptedOpponentKeys().join(', ')}`)
    process.exit(1)
  }

  const results: SeedSearchResult[] = []
  for (const key of keysToSearch) {
    const opponent = TUTORIAL_OPPONENTS[key]
    const result = await findSeedForOpponent(opponent)
    results.push(result)
  }

  // ── Summary ────────────────────────────────────────────────────────
  console.log('\n━━━ Summary ━━━')
  for (const r of results) {
    if (r.seed !== null) {
      console.log(`✅ ${r.opponentKey}: seed = ${r.seed} (0x${r.seed.toString(16).toUpperCase()})`)
      console.log(`   Per-class turns: ${JSON.stringify(r.perClassTurns)}`)
    } else {
      console.log(`❌ ${r.opponentKey}: NO SEED FOUND — opponent too strong, weaken stats`)
    }
  }

  // ── Paste instructions ─────────────────────────────────────────────
  console.log('\n━━━ Next step ━━━')
  console.log('Update backend/src/lib/game/tutorial-opponents.ts:')
  for (const r of results) {
    if (r.seed !== null) {
      console.log(`  ${r.opponentKey}.guaranteedVictorySeed: ${r.seed},`)
    }
  }

  const anyFailed = results.some((r) => r.seed === null)
  process.exit(anyFailed ? 1 : 0)
}

main().catch((err) => {
  console.error('Fatal error:', err)
  process.exit(1)
})
