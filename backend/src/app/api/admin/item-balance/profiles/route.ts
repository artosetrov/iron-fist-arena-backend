import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/item-balance/profiles
 * Returns all ItemBalanceProfile rows.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const profiles = await prisma.itemBalanceProfile.findMany({
      orderBy: { itemType: 'asc' },
    })

    return NextResponse.json({ profiles })
  } catch (error) {
    console.error('get balance profiles error:', error)
    return NextResponse.json({ error: 'Failed to fetch profiles' }, { status: 500 })
  }
}

/**
 * PUT /api/admin/item-balance/profiles
 * Upsert an ItemBalanceProfile. Body: { itemType, statWeights, powerWeight, description? }
 */
export async function PUT(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const { itemType, statWeights, powerWeight, description } = await req.json()

    if (!itemType || !statWeights) {
      return NextResponse.json({ error: 'itemType and statWeights are required' }, { status: 400 })
    }

    const profile = await prisma.itemBalanceProfile.upsert({
      where: { itemType },
      update: {
        statWeights,
        powerWeight: powerWeight ?? 1.0,
        description: description ?? null,
        updatedBy: user.id,
      },
      create: {
        itemType,
        statWeights,
        powerWeight: powerWeight ?? 1.0,
        description: description ?? null,
        updatedBy: user.id,
      },
    })

    await prisma.adminLog.create({
      data: {
        adminId: user.id,
        action: 'update_balance_profile',
        details: { itemType, statWeights, powerWeight },
      },
    })

    return NextResponse.json({ profile })
  } catch (error) {
    console.error('upsert balance profile error:', error)
    return NextResponse.json({ error: 'Failed to update profile' }, { status: 500 })
  }
}
