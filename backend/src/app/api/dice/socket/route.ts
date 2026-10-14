import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { buildDicePayload, hasLiveMatch, ownedRuneKeys } from '@/lib/game/dice-loadout'
import { MAX_GREAT_PER_DIE, MAX_RUNES_PER_DIE, runeByKey, socketsForLevel } from '@/lib/game/runes'

/**
 * POST /api/dice/socket — put a rune on a face, move it, or take it off.
 *
 * Body: { character_id, die: 'atk' | 'grd', face_index: 0..5, rune_key: string | null }
 * Free and instant out of combat. Checks: rune owned (talent node unlocked),
 * class + die type match, socket open by level, ≤ 3 runes and ≤ 1 Great per
 * die, no live match. A rune already elsewhere moves (one copy per hero).
 * Returns the full GET /api/dice payload.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  if (!(await rateLimit(`dice-socket:${user.id}`, 60, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json().catch(() => null)
    const characterId = body?.character_id
    const die: 'atk' | 'grd' | null = body?.die === 'atk' || body?.die === 'grd' ? body.die : null
    const face = body?.face_index
    const runeKey: string | null = body?.rune_key ?? null
    if (typeof characterId !== 'string' || die === null ||
        !Number.isInteger(face) || face < 0 || face > 5 ||
        (runeKey !== null && typeof runeKey !== 'string')) {
      return NextResponse.json({ error: 'Invalid payload' }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { id: true, userId: true, class: true, level: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    if (await hasLiveMatch(character.id)) {
      return NextResponse.json({ error: 'Finish your fight before changing runes', code: 'IN_MATCH' }, { status: 409 })
    }

    if (runeKey === null) {
      await prisma.characterDieRune.deleteMany({ where: { characterId, die, faceIndex: face } })
      return NextResponse.json(await buildDicePayload(character))
    }

    const rune = runeByKey(runeKey)
    if (!rune || rune.class !== character.class) {
      return NextResponse.json({ error: 'Unknown rune for this class' }, { status: 400 })
    }
    if (rune.die !== die) {
      return NextResponse.json({ error: rune.die === 'atk' ? 'This rune goes on the attack die' : 'This rune goes on the guard die', code: 'WRONG_DIE' }, { status: 400 })
    }
    const owned = await ownedRuneKeys(character.id)
    if (!owned.has(rune.key)) {
      return NextResponse.json({ error: 'Unlock this rune in Talents first', code: 'NOT_OWNED' }, { status: 403 })
    }

    const err = await prisma.$transaction(async (tx) => {
      // Lock the character's rune rows for this edit.
      await tx.$queryRawUnsafe('SELECT id FROM characters WHERE id = $1 FOR UPDATE', character.id)
      const rows = await tx.characterDieRune.findMany({
        where: { characterId, die },
        select: { faceIndex: true, runeKey: true },
      })
      // What the die holds after the move: drop this face's old rune and this rune's old face.
      const remaining = rows.filter((r) => r.faceIndex !== face && r.runeKey !== rune.key)
      const cap = Math.min(socketsForLevel(character.level)[die], MAX_RUNES_PER_DIE)
      if (remaining.length + 1 > cap) return cap === 0 ? 'NO_SOCKETS' : 'SOCKETS_FULL'
      const greats = remaining.filter((r) => runeByKey(r.runeKey)?.tier === 'great').length
      if (rune.tier === 'great' && greats >= MAX_GREAT_PER_DIE) return 'ONE_GREAT'

      await tx.characterDieRune.deleteMany({
        where: { characterId, OR: [{ runeKey: rune.key }, { die, faceIndex: face }] },
      })
      await tx.characterDieRune.create({ data: { characterId, die, faceIndex: face, runeKey: rune.key } })
      return null
    })
    if (err) {
      const msg: Record<string, string> = {
        NO_SOCKETS: 'This die has no open socket yet',
        SOCKETS_FULL: 'All open sockets on this die are used — take a rune off first',
        ONE_GREAT: 'Only one Great rune per die',
      }
      return NextResponse.json({ error: msg[err], code: err }, { status: 409 })
    }
    return NextResponse.json(await buildDicePayload(character))
  } catch (error) {
    console.error('dice socket error:', error)
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
