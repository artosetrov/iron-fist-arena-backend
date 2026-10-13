import { NextRequest, NextResponse } from 'next/server'
import { Prisma } from '@prisma/client'
import { getAuthUser } from '@/lib/auth'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'
import { createAdminClient } from '@/lib/supabase/server'

/**
 * POST /api/user/delete
 * Body: (none required)
 * Permanently deletes the authenticated user's account and all associated data.
 * Required by App Store guidelines for account deletion.
 *
 * Deletion order:
 * 1. Clean up pvp_matches by hand — those FKs are ON DELETE RESTRICT, so the
 *    cascade from `user` dies there and the whole delete fails for anyone who
 *    has ever fought (PvP, bot, or boss — they all write a PvpMatch row).
 * 2. Delete the Prisma user record (everything else does cascade).
 * 3. Delete the Supabase auth user via admin API.
 *
 * Mirrors the cleanup in DELETE /api/characters/[id], which already had to
 * solve the same constraint.
 */
export async function POST(req: NextRequest) {
  const user = await getAuthUser(req)
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  // Strict rate limit: 1 request per minute to prevent accidental double-delete
  if (!(await rateLimit(`user-delete:${user.id}`, 1, 60_000))) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 })
  }

  try {
    // Step 1: Delete all user data from application database.
    // Everything except pvp_matches cascades from the user row. PvpMatch
    // references characters with ON DELETE RESTRICT on player1/player2, so it
    // must be cleared first or the delete fails with a constraint error.
    // Read the character list INSIDE the transaction: a character created
    // between the read and the delete would otherwise resurrect the constraint
    // error this cleanup exists to avoid.
    await prisma.$transaction(async (tx) => {
      const characters = await tx.character.findMany({
        where: { userId: user.id },
        select: { id: true },
      })
      const characterIds = characters.map((c) => c.id)

      if (characterIds.length > 0) {
        // Nullify the optional participant columns first.
        await tx.pvpMatch.updateMany({
          where: { winnerId: { in: characterIds } },
          data: { winnerId: null },
        })
        await tx.pvpMatch.updateMany({
          where: { loserId: { in: characterIds } },
          data: { loserId: null },
        })
        // Then drop every match this user's characters took part in.
        await tx.pvpMatch.deleteMany({
          where: {
            OR: [
              { player1Id: { in: characterIds } },
              { player2Id: { in: characterIds } },
            ],
          },
        })
      }

      // Finally the user — cascades characters and everything hanging off them.
      await tx.user.delete({ where: { id: user.id } })
    })

    // Step 2: Delete the Supabase auth user.
    // This invalidates all tokens and removes the auth record.
    const supabaseAdmin = createAdminClient()
    const { error: supabaseError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (supabaseError) {
      // User data is already deleted from our DB at this point.
      // Log the Supabase error but don't fail the request — the user's
      // application data is gone, which is the primary requirement.
      console.error('Supabase auth user deletion failed (data already removed):', supabaseError)
    }

    return NextResponse.json({ success: true, message: 'Account deleted permanently' })
  } catch (error) {
    console.error('Account deletion error:', error)

    // Check if user was already deleted (concurrent request). Inside a
    // transaction Prisma reshapes the message, so match on the code.
    if (
      (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') ||
      (error instanceof Error && error.message.includes('Record to delete does not exist'))
    ) {
      return NextResponse.json({ success: true, message: 'Account already deleted' })
    }

    return NextResponse.json(
      { error: 'Failed to delete account' },
      { status: 500 }
    )
  }
}
