import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { cacheDelete, cacheGet, cacheSet } from '@/lib/cache'
import { rateLimit } from '@/lib/rate-limit'
import { ConsumableType } from '@prisma/client'
import { getGameConfig } from '@/lib/game/config'

// Interactive Combat v1 — Phase 4.A
// CRUD for character active-skill slots. A slot can hold EITHER a passive-talent
// node OR a health-potion consumable (see spec §2–4). Exactly one of `node_id`
// and `consumable_type` is set per row — enforced by DB CHECK constraint.
//
// GET    /api/passives/active-slots?character_id=...  → list slots + consumable picker meta
// POST   /api/passives/active-slots                   → equip { character_id, slot_index, node_id? | consumable_type? }
// DELETE /api/passives/active-slots?character_id=...&slot_index=...  → clear slot
//
// For atomic multi-slot updates (preferred from the picker), see ./batch/route.ts.

const CACHE_TTL = 5 * 60 * 1000
const MAX_SLOTS = 3
const cacheKey = (characterId: string) => `active-slots:char:${characterId}`

// Consumables allowed in active slots in Phase 4 scope. Non-health potions (stamina,
// scrolls, shards) are intentionally excluded — they don't fit the combat model.
const ALLOWED_CONSUMABLES: readonly ConsumableType[] = [
  'health_potion_small',
  'health_potion_medium',
  'health_potion_large',
] as const

const DEFAULT_CONSUMABLE_PRICES: Record<ConsumableType, number> = {
  stamina_potion_small: 100,
  stamina_potion_medium: 250,
  stamina_potion_large: 500,
  health_potion_small: 150,
  health_potion_medium: 350,
  health_potion_large: 700,
  protection_scroll: 0,
  legendary_shard: 0,
}

async function getConsumablePrice(type: ConsumableType): Promise<number> {
  return getGameConfig<number>(
    `consumable.price.${type}`,
    DEFAULT_CONSUMABLE_PRICES[type],
  )
}

export type SlotResponse = {
  slot_index: number
  kind: 'talent' | 'consumable'
  node_id: string | null
  node_key: string | null
  consumable_type: ConsumableType | null
  name: string
  description: string | null
  icon: string | null
  active_action_type: string | null  // burst_damage / heal_self / ... (null for consumables)
  active_cooldown: number | null     // null for consumables (they're 1/battle, not cooldown-based)
  active_magnitude: number | null
  equipped_at: Date
}

export type ConsumableMeta = {
  consumable_type: ConsumableType
  name: string
  description: string | null
  rarity: string
  price_gold: number
  owned_count: number
}

// GET — list a character's active slots + picker meta for Consumables section.
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

    // Consumables meta is cheap and price-sensitive — always read fresh, don't
    // cache with the slot payload (prices can change via GameConfig mid-session).
    const consumablesMetaPromise = buildConsumablesMeta(characterId)

    const cached = await cacheGet<SlotResponse[]>(cacheKey(characterId))
    if (cached) {
      const consumablesMeta = await consumablesMetaPromise
      return NextResponse.json({
        slots: cached,
        max_slots: MAX_SLOTS,
        consumables_meta: consumablesMeta,
      })
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

    // Lookup item metadata for consumable slots (name, description, icon) in one go.
    const consumableTypesInSlots = [
      ...new Set(slots.map((s) => s.consumableType).filter((t): t is ConsumableType => !!t)),
    ]
    const itemByCatalogId = consumableTypesInSlots.length > 0
      ? await prisma.item.findMany({
          where: { catalogId: { in: consumableTypesInSlots as unknown as string[] } },
          select: { catalogId: true, itemName: true, description: true, imageKey: true },
        }).then((rows) => new Map(rows.map((r) => [r.catalogId, r])))
      : new Map<string, { catalogId: string; itemName: string; description: string | null; imageKey: string | null }>()

    const payload: SlotResponse[] = slots.map((s) => {
      if (s.nodeId && s.node) {
        return {
          slot_index: s.slotIndex,
          kind: 'talent',
          node_id: s.nodeId,
          node_key: s.node.nodeKey,
          consumable_type: null,
          name: s.node.name,
          description: s.node.description,
          icon: s.node.icon,
          active_action_type: s.node.activeActionType,
          active_cooldown: s.node.activeCooldown,
          active_magnitude: s.node.activeMagnitude,
          equipped_at: s.equippedAt,
        }
      }
      // Consumable slot — nodeId is null, consumableType is set.
      const ct = s.consumableType!
      const itemMeta = itemByCatalogId.get(ct)
      return {
        slot_index: s.slotIndex,
        kind: 'consumable',
        node_id: null,
        node_key: null,
        consumable_type: ct,
        name: itemMeta?.itemName ?? prettifyConsumableType(ct),
        description: itemMeta?.description ?? null,
        icon: itemMeta?.imageKey ?? null,
        active_action_type: null,
        active_cooldown: null,
        active_magnitude: null,
        equipped_at: s.equippedAt,
      }
    })

    await cacheSet(cacheKey(characterId), payload, CACHE_TTL)
    const consumablesMeta = await consumablesMetaPromise
    return NextResponse.json({
      slots: payload,
      max_slots: MAX_SLOTS,
      consumables_meta: consumablesMeta,
    })
  } catch (error) {
    console.error('active-slots GET error:', error)
    return NextResponse.json({ error: 'Failed to fetch active slots' }, { status: 500 })
  }
}

// POST — equip a talent or consumable into a slot (upsert by slot_index).
// Body: { character_id, slot_index, node_id?: string, consumable_type?: ConsumableType }
// Exactly one of node_id / consumable_type must be provided.
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  if (!(await rateLimit(`active-slots-equip:${user.id}`, 20, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    const body = await req.json()
    const { character_id, slot_index, node_id, consumable_type } = body as {
      character_id?: string
      slot_index?: number
      node_id?: string | null
      consumable_type?: ConsumableType | null
    }

    if (!character_id || typeof slot_index !== 'number') {
      return NextResponse.json({ error: 'character_id and slot_index are required' }, { status: 400 })
    }
    if (!Number.isInteger(slot_index) || slot_index < 0 || slot_index >= MAX_SLOTS) {
      return NextResponse.json({ error: `slot_index must be 0..${MAX_SLOTS - 1}` }, { status: 400 })
    }
    const hasNode = !!node_id
    const hasConsumable = !!consumable_type
    if (hasNode === hasConsumable) {
      return NextResponse.json(
        { error: 'Provide exactly one of node_id or consumable_type' },
        { status: 400 },
      )
    }
    if (hasConsumable && !ALLOWED_CONSUMABLES.includes(consumable_type as ConsumableType)) {
      return NextResponse.json(
        { error: `consumable_type must be one of: ${ALLOWED_CONSUMABLES.join(', ')}` },
        { status: 400 },
      )
    }

    await prisma.$transaction(async (tx) => {
      const character = await tx.character.findUnique({
        where: { id: character_id },
        select: { userId: true, class: true },
      })
      if (!character) throw new Error('NOT_FOUND')
      if (character.userId !== user.id) throw new Error('FORBIDDEN')

      if (hasNode) {
        const node = await tx.passiveNode.findUnique({
          where: { id: node_id as string },
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

        const unlocked = await tx.characterPassive.findUnique({
          where: { characterId_nodeId: { characterId: character_id, nodeId: node_id as string } },
          select: { id: true },
        })
        if (!unlocked) throw new Error('NODE_NOT_UNLOCKED')

        // If this node is already in a DIFFERENT slot, move it (partial-unique index
        // on (character_id, node_id) WHERE node_id IS NOT NULL enforces one-per-node).
        const existingSameNode = await tx.characterActiveSlot.findFirst({
          where: { characterId: character_id, nodeId: node_id as string },
          select: { id: true, slotIndex: true },
        })
        if (existingSameNode && existingSameNode.slotIndex !== slot_index) {
          await tx.characterActiveSlot.delete({ where: { id: existingSameNode.id } })
        }
      } else {
        // Consumable path: DB partial-unique on (character_id) WHERE consumable_type
        // IS NOT NULL enforces max-1-consumable. If another consumable row exists,
        // it must be at this same slot_index (we're about to replace it anyway); if
        // it's at a different slot, explicitly delete it to satisfy the constraint.
        const existingConsumable = await tx.characterActiveSlot.findFirst({
          where: { characterId: character_id, consumableType: { not: null } },
          select: { id: true, slotIndex: true },
        })
        if (existingConsumable && existingConsumable.slotIndex !== slot_index) {
          await tx.characterActiveSlot.delete({ where: { id: existingConsumable.id } })
        }
      }

      // Replace whatever is at (character, slot_index).
      await tx.characterActiveSlot.deleteMany({
        where: { characterId: character_id, slotIndex: slot_index },
      })

      await tx.characterActiveSlot.create({
        data: {
          characterId: character_id,
          slotIndex: slot_index,
          nodeId: hasNode ? (node_id as string) : null,
          consumableType: hasConsumable ? (consumable_type as ConsumableType) : null,
        },
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

// DELETE — clear a specific slot.
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

// --- helpers ---

async function buildConsumablesMeta(characterId: string): Promise<ConsumableMeta[]> {
  const [inventoryRows, itemRows, prices] = await Promise.all([
    prisma.consumableInventory.findMany({
      where: {
        characterId,
        consumableType: { in: ALLOWED_CONSUMABLES as unknown as ConsumableType[] },
      },
      select: { consumableType: true, quantity: true },
    }),
    prisma.item.findMany({
      where: { catalogId: { in: ALLOWED_CONSUMABLES as unknown as string[] } },
      select: { catalogId: true, itemName: true, description: true, rarity: true },
    }),
    Promise.all(ALLOWED_CONSUMABLES.map(getConsumablePrice)),
  ])

  const ownedByType = new Map(inventoryRows.map((r) => [r.consumableType, r.quantity]))
  const itemByCatalog = new Map(itemRows.map((r) => [r.catalogId, r]))

  return ALLOWED_CONSUMABLES.map((type, i) => {
    const item = itemByCatalog.get(type)
    return {
      consumable_type: type,
      name: item?.itemName ?? prettifyConsumableType(type),
      description: item?.description ?? null,
      rarity: item?.rarity ?? 'common',
      price_gold: prices[i],
      owned_count: ownedByType.get(type) ?? 0,
    }
  })
}

function prettifyConsumableType(type: ConsumableType): string {
  // Fallback when Items catalog is empty. Not expected in prod.
  return type.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}
