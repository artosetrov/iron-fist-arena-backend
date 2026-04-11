// =============================================================================
// GET /api/battle-pass/weekly-challenges?character_id=…
// =============================================================================
//
// Returns the 5 weekly BP challenges for the current ISO week. Lazily
// materializes WeeklyChallengeProgress rows on first call of the week — no
// cron job needed. Every player sees the same 5 challenges per week (pool
// is deterministic), but progress/claimed is per-character.
//
// Response shape (matches iOS expectations — see BPWeeklyChallengesViewModel):
// {
//   iso_week: "2026-W15",
//   challenges: [
//     { slot_index, goal_type, goal_target, progress, bp_xp_award,
//       claimed, label, description }, …
//   ]
// }

import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { buildWeeklyChallenges, isoWeekOf } from '@/lib/game/weekly-challenges'

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
      select: { userId: true },
    })
    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }
    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    const isoWeek = isoWeekOf()
    const template = buildWeeklyChallenges(isoWeek)

    // Lazy materialization: upsert missing rows for this (character, week).
    // We skipDuplicates so concurrent requests don't race.
    await prisma.weeklyChallengeProgress.createMany({
      data: template.map((t) => ({
        characterId,
        isoWeek,
        slotIndex: t.slotIndex,
        goalType: t.goalType,
        goalTarget: t.goalTarget,
        bpXpAward: t.bpXpAward,
      })),
      skipDuplicates: true,
    })

    const rows = await prisma.weeklyChallengeProgress.findMany({
      where: { characterId, isoWeek },
      orderBy: { slotIndex: 'asc' },
    })

    // Merge server state (progress, claimed) with template metadata
    // (label, description) — metadata lives in code, not DB.
    const byIndex = new Map(template.map((t) => [t.slotIndex, t]))

    const challenges = rows.map((r: typeof rows[number]) => {
      const meta = byIndex.get(r.slotIndex)
      return {
        slot_index: r.slotIndex,
        goal_type: r.goalType,
        goal_target: r.goalTarget,
        progress: r.progress,
        bp_xp_award: r.bpXpAward,
        claimed: r.claimed,
        completed: r.progress >= r.goalTarget,
        label: meta?.label ?? r.goalType,
        description: meta?.description ?? '',
      }
    })

    return NextResponse.json({
      iso_week: isoWeek,
      challenges,
    })
  } catch (error) {
    console.error('get weekly challenges error:', error)
    return NextResponse.json(
      { error: 'Failed to fetch weekly challenges' },
      { status: 500 },
    )
  }
}
