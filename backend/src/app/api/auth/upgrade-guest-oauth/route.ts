import { NextRequest, NextResponse } from 'next/server'
import { getAuthUser } from '@/lib/auth'
import { createAdminClient } from '@/lib/supabase/server'
import { prisma } from '@/lib/prisma'
import { rateLimit } from '@/lib/rate-limit'

/**
 * POST /api/auth/upgrade-guest-oauth
 *
 * Links a Google or Apple identity to an existing guest account.
 * Since Supabase signInWithIdToken creates a new user (different UUID),
 * we transfer all data from the guest user to the OAuth user, then
 * delete the guest. This preserves all character progress.
 *
 * Body: { id_token: string, access_token?: string, provider: 'google' | 'apple' }
 *
 * Flow:
 * 1. Verify caller is an authenticated guest (authProvider = 'anonymous')
 * 2. signInWithIdToken to create/find the OAuth user in Supabase
 * 3. If OAuth user already has a character → error (account conflict)
 * 4. Transfer all user-owned data from guest to OAuth user
 * 5. Delete guest user from Prisma + Supabase
 * 6. Return new OAuth session tokens
 */
export async function POST(req: NextRequest) {
  const guestUser = await getAuthUser(req)
  if (!guestUser) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || 'unknown'
  if (!(await rateLimit('upgrade-guest-oauth:' + ip, 5, 60_000))) {
    return NextResponse.json(
      { error: 'Too many requests. Please try again later.' },
      { status: 429 }
    )
  }

  try {
    const body = await req.json()
    const { id_token, access_token: oauthAccessToken, provider } = body

    if (!id_token) {
      return NextResponse.json({ error: 'id_token is required' }, { status: 400 })
    }

    if (provider !== 'google' && provider !== 'apple') {
      return NextResponse.json(
        { error: 'provider must be "google" or "apple"' },
        { status: 400 }
      )
    }

    // 1. Verify the caller is a guest
    const guestDbUser = await prisma.user.findUnique({
      where: { id: guestUser.id },
      select: { id: true, authProvider: true, gems: true, premiumUntil: true },
    })

    if (!guestDbUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    if (guestDbUser.authProvider !== 'anonymous') {
      return NextResponse.json(
        { error: 'Account is already registered' },
        { status: 400 }
      )
    }

    // 2. Sign in with the OAuth token → creates/finds OAuth user in Supabase
    const supabase = createAdminClient()

    const signInPayload: { provider: 'google' | 'apple'; token: string; access_token?: string } = {
      provider,
      token: id_token,
    }
    if (provider === 'google' && oauthAccessToken) {
      signInPayload.access_token = oauthAccessToken
    }

    const { data: oauthData, error: oauthError } = await supabase.auth.signInWithIdToken(signInPayload)

    if (oauthError || !oauthData?.session || !oauthData?.user) {
      console.error('upgrade-guest-oauth signInWithIdToken error:', oauthError)
      return NextResponse.json(
        { error: oauthError?.message ?? `${provider} Sign In failed` },
        { status: 401 }
      )
    }

    const oauthUserId = oauthData.user.id
    const oauthEmail = oauthData.user.email ?? ''

    // Edge case: if Supabase matched the same user (unlikely for anonymous → OAuth)
    if (oauthUserId === guestUser.id) {
      // Same user — just update the DB record
      await prisma.user.update({
        where: { id: guestUser.id },
        data: {
          email: oauthEmail,
          authProvider: provider,
          username: oauthData.user.user_metadata?.full_name || oauthEmail.split('@')[0] || `${provider}_user`,
          lastLogin: new Date(),
        },
      })

      return NextResponse.json({
        access_token: oauthData.session.access_token,
        refresh_token: oauthData.session.refresh_token,
        expires_in: oauthData.session.expires_in,
        user: {
          id: oauthUserId,
          email: oauthEmail,
          is_anonymous: false,
        },
      })
    }

    // 3. Check if the OAuth user already has a character (account conflict)
    const existingOAuthCharacter = await prisma.character.findFirst({
      where: { userId: oauthUserId },
      select: { id: true, characterName: true },
    })

    if (existingOAuthCharacter) {
      return NextResponse.json(
        {
          error: `This ${provider === 'google' ? 'Google' : 'Apple'} account already has a character (${existingOAuthCharacter.characterName}). Please log in with that account instead.`,
        },
        { status: 409 }
      )
    }

    // 4. Transfer all data from guest user to OAuth user inside a transaction
    await prisma.$transaction(async (tx) => {
      // Ensure OAuth user record exists in Prisma
      const displayName =
        oauthData.user.user_metadata?.full_name ||
        oauthEmail.split('@')[0] ||
        `${provider}_${oauthUserId.slice(0, 8)}`

      await tx.user.upsert({
        where: { id: oauthUserId },
        update: {
          email: oauthEmail,
          authProvider: provider,
          username: displayName,
          lastLogin: new Date(),
          // Carry over premium/gems from guest
          gems: guestDbUser.gems,
          premiumUntil: guestDbUser.premiumUntil,
        },
        create: {
          id: oauthUserId,
          email: oauthEmail,
          username: displayName,
          authProvider: provider,
          gems: guestDbUser.gems,
          premiumUntil: guestDbUser.premiumUntil,
          lastLogin: new Date(),
        },
      })

      // Transfer characters
      await tx.character.updateMany({
        where: { userId: guestUser.id },
        data: { userId: oauthUserId },
      })

      // Transfer cosmetics
      await tx.cosmetic.updateMany({
        where: { userId: guestUser.id },
        data: { userId: oauthUserId },
      })

      // Transfer push tokens
      await tx.pushToken.updateMany({
        where: { userId: guestUser.id },
        data: { userId: oauthUserId },
      })

      // Transfer IAP transactions
      await tx.iapTransaction.updateMany({
        where: { userId: guestUser.id },
        data: { userId: oauthUserId },
      })

      // Transfer daily gem card (unique constraint — delete old if OAuth user somehow has one)
      const guestGemCard = await tx.dailyGemCard.findUnique({
        where: { userId: guestUser.id },
      })
      if (guestGemCard) {
        await tx.dailyGemCard.deleteMany({ where: { userId: oauthUserId } })
        await tx.dailyGemCard.update({
          where: { userId: guestUser.id },
          data: { userId: oauthUserId },
        })
      }

      // Delete the old guest user (cascades PushLog etc.)
      await tx.user.delete({ where: { id: guestUser.id } })
    })

    // 5. Delete the guest user from Supabase auth
    const { error: deleteError } = await supabase.auth.admin.deleteUser(guestUser.id)
    if (deleteError) {
      console.warn('upgrade-guest-oauth: failed to delete guest from Supabase auth:', deleteError)
      // Non-fatal — data is already transferred
    }

    // 6. Return new OAuth session tokens
    return NextResponse.json({
      access_token: oauthData.session.access_token,
      refresh_token: oauthData.session.refresh_token,
      expires_in: oauthData.session.expires_in,
      user: {
        id: oauthUserId,
        email: oauthEmail,
        is_anonymous: false,
      },
    })
  } catch (error) {
    console.error('upgrade-guest-oauth error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
