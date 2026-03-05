import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { UPGRADE_CHANCES } from '@/lib/game/balance'

export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const body = await req.json()
    const { character_id, inventory_id } = body

    if (!character_id || !inventory_id) {
      return NextResponse.json(
        { error: 'character_id and inventory_id are required' },
        { status: 400 }
      )
    }

    // Verify character ownership
    const character = await prisma.character.findUnique({
      where: { id: character_id },
    })

    if (!character) {
      return NextResponse.json({ error: 'Character not found' }, { status: 404 })
    }

    if (character.userId !== user.id) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
    }

    // Get the inventory item
    const inventoryItem = await prisma.equipmentInventory.findUnique({
      where: { id: inventory_id },
      include: { item: true },
    })

    if (!inventoryItem) {
      return NextResponse.json({ error: 'Inventory item not found' }, { status: 404 })
    }

    if (inventoryItem.characterId !== character_id) {
      return NextResponse.json({ error: 'Item does not belong to this character' }, { status: 403 })
    }

    const currentLevel = inventoryItem.upgradeLevel

    // Check if already at max upgrade level
    if (currentLevel >= UPGRADE_CHANCES.length) {
      return NextResponse.json(
        { error: 'Item is already at maximum upgrade level' },
        { status: 400 }
      )
    }

    // Calculate cost: (upgradeLevel + 1) * 100 gold
    const upgradeCost = (currentLevel + 1) * 100

    if (character.gold < upgradeCost) {
      return NextResponse.json(
        { error: 'Not enough gold', required: upgradeCost, current: character.gold },
        { status: 400 }
      )
    }

    // Roll for success
    const successChance = UPGRADE_CHANCES[currentLevel]
    const roll = Math.random() * 100
    const success = roll < successChance

    // Deduct gold regardless of success
    const updateData: { gold: { decrement: number } } = {
      gold: { decrement: upgradeCost },
    }

    if (success) {
      // Upgrade succeeded: deduct gold and increment upgrade level
      const [updatedCharacter, updatedItem] = await prisma.$transaction([
        prisma.character.update({
          where: { id: character_id },
          data: updateData,
        }),
        prisma.equipmentInventory.update({
          where: { id: inventory_id },
          data: { upgradeLevel: { increment: 1 } },
          include: { item: true },
        }),
      ])

      return NextResponse.json({
        success: true,
        inventoryItem: updatedItem,
        gold: updatedCharacter.gold,
        upgradeCost,
        newLevel: currentLevel + 1,
      })
    } else {
      // Upgrade failed: deduct gold only
      const updatedCharacter = await prisma.character.update({
        where: { id: character_id },
        data: updateData,
      })

      return NextResponse.json({
        success: false,
        inventoryItem: { ...inventoryItem },
        gold: updatedCharacter.gold,
        upgradeCost,
        newLevel: currentLevel,
      })
    }
  } catch (error) {
    console.error('upgrade item error:', error)
    return NextResponse.json(
      { error: 'Failed to upgrade item' },
      { status: 500 }
    )
  }
}
