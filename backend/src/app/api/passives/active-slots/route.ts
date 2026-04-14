import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { cacheDelete, cacheGet, cacheSet } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'

// Interactive Combat v1 — Phase 1.4
// CRUD for character active-skill slots (3 slots per character).
//
// GET    /api/passives/active-slots?character_id=...  → list equipped slots
// POST   /api/passives/active-slots                   → equip { character_id, slot_index, node_id }
// DELETE /api/passives/active-slots?character_id=...&slot_index=...  → clear slot

const CACHE_TTL = 5 * 60 * 1000
const MAX_SLOTS = 3
const cacheKey = (characterId: string) => `active-slots:char:${characterId}`

type SlotResponse = {
  slot_index: number
  node_id: string
  node_key: string
  name: string
  description: string | null
  icon: string | null
  active_action_type: string | null
  active_cooldown: number | null
  active_magnitude: number | null
  equipped_at: Date
}

// GET — list a character's active slots
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
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    const cached = await cacheGet<SlotResponse[]>(cacheKey(characterId))
    if (cached) {
      return NextResponse.json({ slots: cached, max_slots: MAX_SLOTS })
    }

    const slots = await prisma.characterActiveSlot.findMany({
      where: { characterId },
      include: {
        node: {
          select: {
            id: true, nodeKey: true, name: true, description: true, icon: true,
            activeActionType: true, activeCooldown: true, activeMagnitude: true,
          },
        },
      },
      orderBy: { slotIndex: 'asc' },
    })

    const payload: SlotResponse[] = slots.map((s) => ({
      slot_index: s.slotIndex,
      node_id: s.nodeId,
      node_key: s.node.nodeKey,
      name: s.node.name,
      description: s.node.description,
      icon: s.node.icon,
      active_action_type: s.node.activeActionType,
      active_cooldown: s.node.activeCooldown,
      active_magnitude: s.node.activeMagnitude,
      equipped_at: s.equippedAt,
    }))

    await cacheSet(cacheKey(characterId), payload, CACHE_TTL)
    return NextResponse.json({ slots: payload, max_slots: MAX_SLOTS })
  } catch (error) {
    console.error('active-slots GET error:', error)
    return NextResponse.json({ error: 'Failed to fetch active slots' }, { status: 500 })
  }
}

// POST — equip a node into a slot (upsert by slot_index)
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`active-slots-equip:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const { character_id, slot_index, node_id } = await req.json()

    if (!character_id || typeof slot_index !== 'number' || !node_id) {
      return NextResponse.json({ error: 'character_id, slot_index, node_id are required' }, { status: 400 })
    }
    if (!Number.isInteger(slot_index) || slot_index < 0 || slot_index >= MAX_SLOTS) {
      return NextResponse.json({ error: `slot_index must be 0..${MAX_SLOTS - 1}` }, { status: 400 })
    }

    await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, class: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      const node = await tx.passiveNode.findUnique({
        where: { id: node_id },
        select: {
          id: true, isActivatable: true, classRestriction: true,
          activeActionType: true, activeCooldown: true, activeMagnitude: true,
        },
      })
      if (!node) throw new Error('NODE_NOT_FOUND')
      if (!node.isActivatable) throw new Error('NODE_NOT_ACTIVATABLE')
      if (node.classRestriction && node.classRestriction !== character.class) {
        throw new Error('CLASS_RESTRICTED')
      }

      // Must be unlocked on this character
      const unlocked = await tx.characterPassive.findUnique({
        where: { characterId_nodeId: { characterId: character_id, nodeId: node_id } },
        select: { id: true },
      })
      if (!unlocked) throw new Error('NODE_NOT_UNLOCKED')

      // Enforce (character, node) uniqueness — if node already equipped in a DIFFERENT slot, remove it.
      const existingSameNode = await tx.characterActiveSlot.findUnique({
        where: { characterId_nodeId: { characterId: character_id, nodeId: node_id } },
        select: { id: true, slotIndex: true },
      })
      if (existingSameNode && existingSameNode.slotIndex !== slot_index) {
        await tx.characterActiveSlot.delete({ where: { id: existingSameNode.id } })
      }

      // Replace whatever is at (character, slot_index)
      await tx.characterActiveSlot.deleteMany({
        where: { characterId: character_id, slotIndex: slot_index },
      })

      await tx.characterActiveSlot.create({
        data: { characterId: character_id, nodeId: node_id, slotIndex: slot_index },
      })
    })

    await cacheDelete(cacheKey(character_id))
    return NextResponse.json({ success: true })
  } catch (error) {
    if (error instanceof Error) {
      const map: Record<string, { msg: string; status: number }> = {
        NOT_FOUND: { msg: 'Character not found', status: 404 },
        FORBIDDEN: { msg: 'Forbidden', status: 403 },
        NODE_NOT_FOUND: { msg: 'Passive node not found', status: 404 },
        NODE_NOT_ACTIVATABLE: { msg: 'This talent is not activatable', status: 400 },
        NODE_NOT_UNLOCKED: { msg: 'Unlock this talent first', status: 400 },
        CLASS_RESTRICTED: { msg: 'This talent is not available for your class', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('active-slots POST error:', error)
    return NextResponse.json({ error: 'Failed to equip active slot' }, { status: 500 })
  }
}

// DELETE — clear a specific slot
export async function DELETE(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`active-slots-clear:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const characterId = req.nextUrl.searchParams.get('character_id')
    const slotIndexRaw = req.nextUrl.searchParams.get('slot_index')
    if (!characterId || slotIndexRaw == null) {
      return NextResponse.json({ error: 'character_id and slot_index are required' }, { status: 400 })
    }
    const slotIndex = parseInt(slotIndexRaw, 10)
    if (!Number.isInteger(slotIndex) || slotIndex < 0 || slotIndex >= MAX_SLOTS) {
      return NextResponse.json({ error: `slot_index must be 0..${MAX_SLOTS - 1}` }, { status: 400 })
    }

    const character = await prisma.character.findUnique({
      where: { id: characterId },
      select: { userId: true },
    })
    if (!character) return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    if (character.userId !== user.id) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    await prisma.characterActiveSlot.deleteMany({
      where: { characterId, slotIndex },
    })

    await cacheDelete(cacheKey(characterId))
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('active-slots DELETE error:', error)
    return NextResponse.json({ error: 'Failed to clear active slot' }, { status: 500 })
  }
}
