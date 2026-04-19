import { NextRequest, NextResponse } from 'next/server'
import { getAuthAdmin, forbiddenResponse } from '@/lib/auth-admin'
import { prisma } from '@/lib/prisma'

/**
 * GET /api/admin/referrals
 *
 * Returns ReferralRewardClaim rows with both the referrer and invitee
 * character names. Ordered by qualifiedAt DESC.
 *
 * Query params: `limit=100`, `offset=0`.
 *
 * Read-only for Phase 1. Manual-credit / dispute-resolution actions live in
 * Phase 2 so they can be audited via AdminLog.
 */
export async function GET(req: NextRequest) {
  const user = await getAuthAdmin(req)
  if (!user) return forbiddenResponse()

  try {
    const limit = Math.min(parseInt(req.nextUrl.searchParams.get('limit') ?? '100'), 500)
    const offset = parseInt(req.nextUrl.searchParams.get('offset') ?? '0')

    const [claims, total] = await Promise.all([
      prisma.referralRewardClaim.findMany({
        include: {
          referrerCharacter: {
            select: {
              id: true, characterName: true,
              user: { select: { email: true } },
            },
          },
          inviteeCharacter: {
            select: {
              id: true, characterName: true,
              user: { select: { email: true } },
            },
          },
        },
        orderBy: { qualifiedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.referralRewardClaim.count(),
    ])

    return NextResponse.json({
      claims: claims.map((c) => ({
        id: c.id,
        referrerCharacterId: c.referrerCharacterId,
        referrerName: c.referrerCharacter.characterName,
        referrerEmail: c.referrerCharacter.user?.email ?? null,
        inviteeCharacterId: c.inviteeCharacterId,
        inviteeName: c.inviteeCharacter.characterName,
        inviteeEmail: c.inviteeCharacter.user?.email ?? null,
        qualifiedAt: c.qualifiedAt,
      })),
      total,
      limit,
      offset,
    })
  } catch (error) {
    console.error('admin referrals list error:', error)
    return NextResponse.json({ error: 'Failed to fetch referral claims' }, { status: 500 })
  }
}
