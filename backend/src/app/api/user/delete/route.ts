import { NextRequest, NextResponse } from 'next/server'
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
 * 1. Delete Prisma user record (cascades all related data via FK onDelete: Cascade)
 * 2. Delete Supabase auth user via admin API
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
    // All foreign keys use onDelete: Cascade, so deleting the user record
    // automatically removes: characters (and their items, equipment, consumables,
    // training sessions, gold mine sessions, minigame sessions, daily quests,
    // pvp matches, dungeon progress, dungeon runs, legendary shards,
    // battle pass claims, skills, passives, achievements, quest progress),
    // cosmetics, push tokens, IAP transactions, daily gem cards, mail recipients.
    await prisma.user.delete({
      where: { id: user.id },
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

    // Check if user was already deleted (concurrent request)
    if (error instanceof Error && error.message.includes('Record to delete does not exist')) {
      return NextResponse.json({ success: true, message: 'Account already deleted' })
    }

    return NextResponse.json(
      { error: 'Failed to delete account' },
      { status: 500 }
    )
  }
}
