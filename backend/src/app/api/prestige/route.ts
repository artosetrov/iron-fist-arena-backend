import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { checkPrestige } from '@/lib/game/progression'
import { getPrestigeConfig } from '@/lib/game/live-config'
import { recalculateDerivedStats } from '@/lib/game/equipment-stats'
import { invalidateSkillCache, invalidatePassiveCache } from '@/lib/game/combat-loader'
import { rateLimit } from '@/lib/rate-limit'
import { updateMultipleAchievements } from '@/lib/game/achievements'

/**
 * GET /api/prestige
 * Check if character is eligible for prestige.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    if (!characterId) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true, level: true, prestigeLevel: true },
    })

    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    const result = await checkPrestige(character.level, character.prestigeLevel)

    return NextResponse.json({
      canPrestige: result.canPrestige,
      currentPrestige: character.prestigeLevel,
      nextPrestige: result.newPrestigeLevel,
      statBonusPercent: result.statBonusPercent,
    })
  } catch (error) {
    console.error('prestige check error:', error)
    return NextResponse.json({ error: 'Failed to check prestige' }, { status: 500 })
  }
}

/**
 * POST /api/prestige
 * Perform prestige: reset level to 1, gain a prestige level, keep everything
 * else — gear, allocated stats, the talent tree and unspent points.
 * Body: { character_id }
 *
 * Design (2026-10-14 balance batch, docs/06_game_systems/PROGRESSION.md):
 * prestige used to wipe every unlocked passive and zero the passive points,
 * which at L50 was a ~27% damage loss for a +5% stat bonus — nobody rational
 * pressed the button. Prestige is now a replay of the 1→50 curve with the
 * build intact; the bonus per prestige is PRESTIGE.STAT_BONUS_PER_PRESTIGE
 * (live-config `prestige.*`). The re-earned talent points cannot double the
 * tree because /passives/unlock caps TOTAL investment at
 * PASSIVES.MAX_PASSIVE_POINTS; the re-earned stat points do stack, as they
 * always did. Gear gates (equip, shop, loot) use gear-level.ts so a P1 at
 * level 1 keeps full access to the ladder it has already climbed.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`prestige:${user.id}`, 3, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body

    if (!character_id) {
      return NextResponse.json({ error: 'character_id is required' }, { status: 400 })
    }

    const PRESTIGE_CONFIG = await getPrestigeConfig()

    // Atomic prestige with row-level lock
    const result = await prisma.$transaction(async (tx) => {
      const [character] = await tx.$queryRawUnsafe<Array<{
        id: string
        user_id: string
        level: number
        prestige_level: number
      }>>(
        `SELECT id, user_id, level, prestige_level FROM characters WHERE id = $1 FOR UPDATE`,
        character_id
      )

      if (!character) throw new Error('NOT_FOUND')
      if (character.user_id !== user.id) throw new Error('FORBIDDEN')

      const prestigeResult = await checkPrestige(character.level, character.prestige_level)
      if (!prestigeResult.canPrestige) throw new Error('NOT_ELIGIBLE')

      const newPrestigeLevel = character.prestige_level + 1

      // Reset level to 1, keep XP at 0, increment prestige. The talent tree,
      // allocated stats and unspent points are NOT touched (see header).
      const updated = await tx.character.update({
        where: { id: character_id },
        data: {
          level: 1,
          currentXp: 0,
          prestigeLevel: newPrestigeLevel,
          // Points for "level 1" of the replay, on top of whatever is unspent.
          statPointsAvailable: { increment: PRESTIGE_CONFIG.STAT_POINTS_PER_LEVEL },
        },
      })

      await recalculateDerivedStats(character_id, tx)

      return { updated, newPrestigeLevel }
    })

    await invalidateSkillCache(character_id)
    await invalidatePassiveCache(character_id)

    // Achievement tracking
    try {
      const prestigeLevel = result.newPrestigeLevel
      const achievementUpdates: { key: string; increment: number; absolute?: boolean }[] = [
        { key: 'first_prestige', increment: prestigeLevel, absolute: true },
        { key: 'prestige_3', increment: prestigeLevel, absolute: true },
      ]
      await updateMultipleAchievements(prisma, character_id, achievementUpdates)
    } catch (achErr) {
      console.error('Achievement tracking error (prestige):', achErr)
    }

    return NextResponse.json({
      success: true,
      prestigeLevel: result.newPrestigeLevel,
      statBonusPercent: result.newPrestigeLevel * PRESTIGE_CONFIG.STAT_BONUS_PER_PRESTIGE * 100,
      message: `Prestige ${result.newPrestigeLevel} achieved! +${(PRESTIGE_CONFIG.STAT_BONUS_PER_PRESTIGE * 100).toFixed(0)}% all stats bonus.`,
    })
  } catch (error) {
    if (error instanceof Error) {
      if (error.message === 'NOT_FOUND') return NextResponse.json({ error: 'Character not found' }, { status: 404 })
      if (error.message === 'FORBIDDEN') return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
      if (error.message === 'NOT_ELIGIBLE') return NextResponse.json({ error: 'Character must be at max level to prestige' }, { status: 400 })
    }
    console.error('prestige error:', error)
    return NextResponse.json({ error: 'Failed to perform prestige' }, { status: 500 })
  }
}
