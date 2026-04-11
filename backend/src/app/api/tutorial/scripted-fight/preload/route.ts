import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { loadCombatCharacter } from '@/lib/game/combat-loader'
import { getScriptedOpponent } from '@/lib/game/tutorial-opponents'
import { logTutorialEvent } from '@/lib/game/tutorial-analytics'

/**
 * POST /api/tutorial/scripted-fight/preload
 *
 * Loads the hero + scripted tutorial opponent payload that the iOS client
 * uses to populate CombatDetailView before the scripted fight. Does NOT
 * run the combat — that happens in /resolve once the player taps FIGHT.
 *
 * Body: { character_id: string }
 *
 * Response:
 *   {
 *     hero: CharacterStats,
 *     opponent: CharacterStats,
 *     forcedStance: { attack, defense },
 *     scripted: true
 *   }
 *
 * Errors:
 *   401 Unauthorized — no user
 *   400 character_id required
 *   403 Character not owned by user
 *   404 Character not found
 *   409 Tutorial already completed (replay prevention)
 *   429 Rate limited
 *
 * Security notes:
 *   - Double-check character.userId === user.id (ownership)
 *   - Gate on tutorialCompleted to prevent replay-for-rewards exploits
 *   - Rate limited at 5/60s (higher than resolve because preload is cheap)
 *
 * See: docs/07_ui_ux/W2_D3_SCRIPTED_FIGHT_DESIGN.md
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  if (!(await rateLimit(`tutorial-preload:${user.id}`, 5, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id } = body as { character_id?: string }

    if (!character_id || typeof character_id !== 'string') {
      return NextResponse.json(
        { error: 'character_id required' },
        { status: 400 },
      )
    }

    // Ownership + replay guard
    const character = await prisma.character.findUnique({
      where: { id: character_id },
      select: {
        id: true,
        userId: true,
        tutorialCompleted: true,
      },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }
    if (character.tutorialCompleted) {
      return NextResponse.json(
        { error: 'Tutorial already completed', alreadyCompleted: true },
        { status: 409 },
      )
    }

    // Load hero with skills/passives, grab scripted opponent from catalog
    const hero = await loadCombatCharacter(character_id)
    const scripted = getScriptedOpponent('tutorial_orc_grunt')

    logTutorialEvent({
      event: 'scripted_fight_preload',
      characterId: character_id,
      step: 0,
      completed: false,
    })

    return NextResponse.json({
      hero,
      opponent: scripted.character,
      forcedStance: scripted.forcedStance,
      scripted: true,
    })
  } catch (error) {
    console.error('tutorial scripted-fight preload error:', error)
    return NextResponse.json(
      { error: 'Failed to preload tutorial fight' },
      { status: 500 },
    )
  }
}
