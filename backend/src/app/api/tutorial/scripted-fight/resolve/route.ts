import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { runCombat, initCombatConfig, type CharacterStats } from '@/lib/game/combat'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { getScriptedOpponent } from '@/lib/game/tutorial-opponents'
import { applyLevelUp } from '@/lib/game/progression'
import { TUTORIAL_FIGHT_REWARDS, getBuildingsUnlockedAt } from '@/lib/game/tutorial'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'

/**
 * POST /api/tutorial/scripted-fight/resolve
 *
 * Runs the scripted tutorial fight with a deterministic seed, grants
 * first-victory rewards (150 gold + 50 XP + scripted weapon drop),
 * triggers level up, and marks tutorialCompleted so the player can
 * never replay for extra rewards.
 *
 * Body:
 *   {
 *     character_id: string,
 *     stance?: { attack: 'head'|'chest'|'legs', defense: 'head'|'chest'|'legs' }
 *   }
 *
 * Response:
 *   {
 *     combat: CombatResult,
 *     rewards: { gold, xp, itemCatalogKey, itemName? },
 *     levelUp: { leveledUp, newLevel, ... } | null,
 *     unlocks: string[]  // building keys unlocked at new level
 *   }
 *
 * SECURITY:
 *   - Ownership check (character.userId === user.id)
 *   - Replay guard (tutorialCompleted/tutorialSkipped/tutorialStep gate at
 *     start of transaction)
 *   - Rate limit 3/60s
 *   - No stamina cost, no ELO mutation, no daily quest tracking,
 *     no battle pass, no durability — fully isolated from real game state
 *   - Full transaction so reward grant + tutorialCompleted flag are atomic
 *
 * SANITY CHECK:
 *   The seed is chosen offline to guarantee hero victory. If the actual
 *   combat result is NOT a hero victory, something drifted (balance change,
 *   seed rot). We log and alert but STILL grant rewards — shipping a
 *   slightly-off tutorial is better than bricking onboarding.
 *
 * See: docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  if (
    !(await rateLimit(
      `tutorial-fight:${user.id}`,
      TUTORIAL_FIGHT_REWARDS.rateLimit.max,
      TUTORIAL_FIGHT_REWARDS.rateLimit.windowMs,
    ))
  ) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, stance } = body as {
      character_id?: string
      stance?: { attack: string; defense: string }
    }

    if (!character_id || typeof character_id !== 'string') {
      return NextResponse.json(
        { error: 'character_id required' },
        { status: 400 },
      )
    }

    await initCombatConfig()

    const scripted = getScriptedOpponent('tutorial_orc_grunt')

    // Apply forced stance if client didn't send one (determinism).
    const finalStance = stance ?? scripted.forcedStance

    // Load hero OUTSIDE the transaction (read-heavy, uses caches).
    const hero = await loadCombatCharacter(character_id)
    // Apply stance to hero CharacterStats for combat resolution.
    const heroWithStance: CharacterStats = {
      ...hero,
      combatStance: {
        attack: finalStance.attack,
        defense: finalStance.defense,
      },
    }

    // Run combat BEFORE the transaction — pure computation, idempotent.
    const combatResult = await runCombat(
      heroWithStance,
      { ...scripted.character, currentHp: scripted.character.maxHp },
      scripted.guaranteedVictorySeed,
    )

    // SANITY CHECK — seed drift detection.
    const heroWon = combatResult.winnerId === heroWithStance.id
    if (!heroWon) {
      console.error(
        `[tutorial-fight] SEED DRIFT: hero lost scripted fight! ` +
          `character=${character_id} hero_class=${hero.class} ` +
          `seed=${scripted.guaranteedVictorySeed} turns=${combatResult.totalTurns}. ` +
          `Re-run backend/scripts/find-tutorial-seed.ts and update tutorial-opponents.ts.`,
      )
      // Do NOT block the player — we still grant rewards below.
    }

    // Transaction: grant rewards, mark completed, level up.
    const txResult = await prisma.$transaction(async (tx) => {
      // Re-fetch inside transaction with row lock to prevent concurrent resolves.
      const [characterLocked] = await tx.$queryRawUnsafe<
        Array<{
          id: string
          user_id: string
          level: number
          tutorial_completed: boolean
          tutorial_skipped: boolean
          tutorial_step: number
        }>
      >(
        `SELECT id, user_id, level, tutorial_completed, tutorial_skipped, tutorial_step
         FROM "characters"
         WHERE id = $1
         FOR UPDATE`,
        character_id,
      )

      if (!characterLocked) {
        throw new Error('NOT_FOUND')
      }
      if (characterLocked.user_id !== user.id) {
        throw new Error('FORBIDDEN')
      }
      if (
        characterLocked.tutorial_completed ||
        characterLocked.tutorial_skipped ||
        characterLocked.tutorial_step >= 3
      ) {
        throw new Error('ALREADY_COMPLETED')
      }

      // Grant XP + gold, mark completed atomically.
      await tx.character.update({
        where: { id: character_id },
        data: {
          currentXp: { increment: TUTORIAL_FIGHT_REWARDS.xp },
          tutorialCompleted: true,
          tutorialCompletedAt: new Date(),
          // Also advance tutorialStep to 2 (first_fight_won) for legacy compat.
          tutorialStep: Math.max(characterLocked.level >= 1 ? 2 : 0, 0),
        },
      })

      // Gold lives on the user (account-level after 2026-04-09 migration),
      // not on the character. Grant via User update.
      await tx.user.update({
        where: { id: user.id },
        data: {
          gold: { increment: TUTORIAL_FIGHT_REWARDS.gold },
        },
      })

      // Apply level-up check (50 XP at Lv1 should push to Lv2).
      const levelUpResult = await applyLevelUp(tx, character_id)

      // Scripted item drop — look up catalog item by key, grant if it exists.
      // Gracefully degrade if item is missing (log + skip, don't fail).
      let itemName: string | undefined
      const catalogItem = await tx.item.findUnique({
        where: { catalogId: TUTORIAL_FIGHT_REWARDS.itemCatalogKey },
        select: { id: true, itemName: true },
      })
      if (catalogItem) {
        await tx.equipmentInventory.create({
          data: {
            characterId: character_id,
            itemId: catalogItem.id,
            upgradeLevel: 0,
            durability: 100,
            maxDurability: 100,
            isEquipped: false,
          },
        })
        itemName = catalogItem.itemName
      } else {
        console.warn(
          `[tutorial-fight] Tutorial reward item "${TUTORIAL_FIGHT_REWARDS.itemCatalogKey}" ` +
            `not found in catalog — skipping item grant. Add it to the Item table or ` +
            `update TUTORIAL_FIGHT_REWARDS.itemCatalogKey in tutorial.ts.`,
        )
      }

      // Compute building unlocks for the (possibly new) level.
      const newLevel = levelUpResult?.leveledUp
        ? levelUpResult.newLevel
        : characterLocked.level
      const unlocks = getBuildingsUnlockedAt(newLevel)

      return {
        levelUp: levelUpResult,
        itemName,
        unlocks,
      }
    })

    logTutorialEvent({
      event: 'scripted_fight_resolve',
      characterId: character_id,
      step: 2,
      completed: true,
    })

    return NextResponse.json({
      combat: combatResult,
      rewards: {
        gold: TUTORIAL_FIGHT_REWARDS.gold,
        xp: TUTORIAL_FIGHT_REWARDS.xp,
        itemCatalogKey: TUTORIAL_FIGHT_REWARDS.itemCatalogKey,
        itemName: txResult.itemName,
      },
      levelUp: txResult.levelUp,
      unlocks: txResult.unlocks,
      sanityCheckPassed: heroWon,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') {
        return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      }
      if (error.message === 'FORBIDDEN') {
        return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      }
      if (error.message === 'ALREADY_COMPLETED') {
        return NextResponse.json(
          { error: 'Tutorial already completed', alreadyCompleted: true },
          { status: 409 },
        )
      }
    }
    console.error('tutorial scripted-fight resolve error:', error)
    return NextResponse.json(
      { error: 'Failed to resolve tutorial fight' },
      { status: 500 },
    )
  }
}
