import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { ConsumableType } from '@prisma/client'
import {
  ACTIVE_SLOT_CONSUMABLES,
  invalidateActiveSlotsCache,
} from '@/lib/game/active-slots'

// Interactive Combat v1 — Phase 4.A
// Atomic "save loadout" endpoint. The Active Skill Picker commits the full
// 3-slot selection in one call so the server always sees a consistent state
// (no intermediate "2 slots equipped, 1 in limbo" window).
//
// POST /api/passives/active-slots/batch
// Body:
//   {
//     character_id: string,
//     slots: Array<{
//       slot_index: 0 | 1 | 2,
//       node_id?: string | null,         // mutually exclusive with consumable_type
//       consumable_type?: ConsumableType | null
//     }>
//   }
//
// Rules:
//   - `slots` MUST cover exactly [0, 1, 2] (no duplicates, no gaps).
//   - Each slot is one of: empty (both null), talent (node_id set), or consumable.
//   - At most 1 consumable across the 3 slots.
//   - At most 1 occurrence of any given node_id across the 3 slots.
//   - Same validation as single-slot POST: talent must be activatable + unlocked.
//
// Behaviour: DELETE all 3 rows, INSERT the new ones inside a single transaction.
// Cache is invalidated on success.

const MAX_SLOTS = 3

type SlotPayload = {
  slot_index: number
  node_id?: string | null
  consumable_type?: ConsumableType | null
}

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`active-slots-batch:${user.id}`, 10, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, slots } = body as {
      character_id?: string
      slots?: SlotPayload[]
    }

    if (!character_id || !Array.isArray(slots)) {
      return NextResponse.json(
        { error: 'character_id and slots[] are required' },
        { status: 400 },
      )
    }

    const validation = validateSlotsPayload(slots)
    if ('error' in validation) {
      return NextResponse.json({ error: validation.error }, { status: 400 })
    }

    await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, class: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      // Validate each talent slot (node exists, activatable, unlocked, class-ok).
      const talentNodeIds = slots
        .map((s) => s.node_id)
        .filter((id): id is string => !!id)

      if (talentNodeIds.length > 0) {
        const nodes = await tx.passiveNode.findMany({
          where: { id: { in: talentNodeIds } },
          select: {
            id: true, isActivatable: true, classRestriction: true,
          },
        })
        const nodeById = new Map(nodes.map((n) => [n.id, n]))
        for (const nodeId of talentNodeIds) {
          const node = nodeById.get(nodeId)
          if (!node) throw new Error('NODE_NOT_FOUND')
          if (!node.isActivatable) throw new Error('NODE_NOT_ACTIVATABLE')
          if (node.classRestriction && node.classRestriction !== character.class) {
            throw new Error('CLASS_RESTRICTED')
          }
        }

        const unlocked = await tx.characterPassive.findMany({
          where: {
            characterId: character_id,
            nodeId: { in: talentNodeIds },
          },
          select: { nodeId: true },
        })
        const unlockedSet = new Set(unlocked.map((u) => u.nodeId))
        for (const nodeId of talentNodeIds) {
          if (!unlockedSet.has(nodeId)) throw new Error('NODE_NOT_UNLOCKED')
        }
      }

      const consumableTypes = slots
        .map((s) => s.consumable_type)
        .filter((type): type is ConsumableType => !!type)

      if (consumableTypes.length > 0) {
        const ownedConsumables = await tx.consumableInventory.findMany({
          where: {
            characterId: character_id,
            consumableType: { in: consumableTypes },
            quantity: { gt: 0 },
          },
          select: { consumableType: true },
        })
        const ownedSet = new Set(ownedConsumables.map((row) => row.consumableType))
        for (const consumableType of consumableTypes) {
          if (!ownedSet.has(consumableType)) {
            throw new Error('CONSUMABLE_NOT_OWNED')
          }
        }
      }

      // Wipe + rewrite. The partial-unique indexes on (character_id, node_id) and
      // (character_id) WHERE consumable_type IS NOT NULL catch any caller mistake
      // that slipped through validation.
      await tx.characterActiveSlot.deleteMany({ where: { characterId: character_id } })

      const rowsToCreate = slots
        .filter((s) => !!s.node_id || !!s.consumable_type)
        .map((s) => ({
          characterId: character_id,
          slotIndex: s.slot_index,
          nodeId: s.node_id ?? null,
          consumableType: (s.consumable_type ?? null) as ConsumableType | null,
        }))

      if (rowsToCreate.length > 0) {
        await tx.characterActiveSlot.createMany({ data: rowsToCreate })
      }
    })

    await invalidateActiveSlotsCache(character_id)
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
        CONSUMABLE_NOT_OWNED: { msg: 'Own this potion before equipping it', status: 400 },
      }
      const mapped = map[error.message]
      if (mapped) return NextResponse.json({ error: mapped.msg }, { status: mapped.status })
    }
    console.error('active-slots batch POST error:', error)
    return NextResponse.json({ error: 'Failed to save loadout' }, { status: 500 })
  }
}

function validateSlotsPayload(slots: SlotPayload[]):
  | { error: string }
  | { ok: true }
{
  if (slots.length !== MAX_SLOTS) {
    return { error: `slots must contain exactly ${MAX_SLOTS} entries` }
  }

  const seenIndex = new Set<number>()
  const seenNodeIds = new Set<string>()
  let consumableCount = 0

  for (const s of slots) {
    if (!Number.isInteger(s.slot_index) || s.slot_index < 0 || s.slot_index >= MAX_SLOTS) {
      return { error: `slot_index must be 0..${MAX_SLOTS - 1}` }
    }
    if (seenIndex.has(s.slot_index)) {
      return { error: `Duplicate slot_index ${s.slot_index}` }
    }
    seenIndex.add(s.slot_index)

    const hasNode = !!s.node_id
    const hasConsumable = !!s.consumable_type
    if (hasNode && hasConsumable) {
      return { error: 'A slot cannot hold both a talent and a consumable' }
    }
      if (hasConsumable) {
      if (!ACTIVE_SLOT_CONSUMABLES.includes(s.consumable_type as ConsumableType)) {
        return {
          error: `consumable_type must be one of: ${ACTIVE_SLOT_CONSUMABLES.join(', ')}`,
        }
      }
      consumableCount += 1
    }
    if (hasNode) {
      const nodeId = s.node_id as string
      if (seenNodeIds.has(nodeId)) {
        return { error: `Duplicate node_id ${nodeId}` }
      }
      seenNodeIds.add(nodeId)
    }
  }

  if (consumableCount > 1) {
    return { error: 'At most one consumable per loadout' }
  }

  return { ok: true }
}
