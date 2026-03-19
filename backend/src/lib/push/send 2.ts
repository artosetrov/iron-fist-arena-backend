import { prisma } from '@/lib/prisma'

type PushPayload = {
  title: string
  body: string
  data?: Record<string, any>
}

type SendResult = {
  sent: number
  failed: number
  errors: string[]
}

/**
 * Send push notification to a list of user IDs.
 * Fetches active tokens, sends via APNS/FCM, logs results.
 *
 * APNS integration:
 * - Requires APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY_PATH env vars
 * - Uses HTTP/2 to api.push.apple.com (production) or api.sandbox.push.apple.com
 * - Falls back to logging in dev mode when env vars are not set
 */
export async function sendPushToUsers(
  userIds: string[],
  payload: PushPayload,
  campaignId?: string
): Promise<SendResult> {
  const tokens = await prisma.pushToken.findMany({
    where: {
      userId: { in: userIds },
      isActive: true,
    },
    select: { userId: true, token: true, platform: true },
  })

  let sent = 0
  let failed = 0
  const errors: string[] = []

  for (const t of tokens) {
    try {
      const success = await sendToDevice(t.token, t.platform, payload)
      if (success) {
        sent++
        await logPush(campaignId, t.userId, t.token, payload, 'sent')
      } else {
        failed++
        await logPush(campaignId, t.userId, t.token, payload, 'failed', 'Send returned false')
      }
    } catch (error: any) {
      failed++
      const errMsg = error?.message ?? 'Unknown error'
      errors.push(`${t.userId}: ${errMsg}`)
      await logPush(campaignId, t.userId, t.token, payload, 'failed', errMsg)

      // If APNS says token is invalid, deactivate it
      if (errMsg.includes('BadDeviceToken') || errMsg.includes('Unregistered')) {
        await prisma.pushToken.updateMany({
          where: { token: t.token },
          data: { isActive: false },
        })
      }
    }
  }

  return { sent, failed, errors }
}

/**
 * Send push to all active users (broadcast).
 * Processes in batches to avoid memory issues.
 */
export async function sendPushBroadcast(
  payload: PushPayload,
  campaignId?: string,
  filter?: { minLevel?: number; maxLevel?: number; class?: string }
): Promise<SendResult> {
  // Build character filter to find matching userIds
  const charWhere: any = {}
  if (filter?.minLevel) charWhere.level = { ...charWhere.level, gte: filter.minLevel }
  if (filter?.maxLevel) charWhere.level = { ...charWhere.level, lte: filter.maxLevel }
  if (filter?.class) charWhere.class = filter.class

  const hasFilter = Object.keys(charWhere).length > 0

  let userIds: string[]
  if (hasFilter) {
    const chars = await prisma.character.findMany({
      where: charWhere,
      select: { userId: true },
      distinct: ['userId'],
    })
    userIds = chars.map((c) => c.userId)
  } else {
    const users = await prisma.user.findMany({
      select: { id: true },
    })
    userIds = users.map((u) => u.id)
  }

  if (userIds.length === 0) return { sent: 0, failed: 0, errors: [] }

  // Process in batches of 100
  const batchSize = 100
  let totalSent = 0
  let totalFailed = 0
  const allErrors: string[] = []

  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize)
    const result = await sendPushToUsers(batch, payload, campaignId)
    totalSent += result.sent
    totalFailed += result.failed
    allErrors.push(...result.errors)
  }

  return { sent: totalSent, failed: totalFailed, errors: allErrors }
}

// ---------------------------------------------------------------------------
// Device-level send (APNS / FCM)
// ---------------------------------------------------------------------------

async function sendToDevice(
  token: string,
  platform: string,
  payload: PushPayload
): Promise<boolean> {
  if (platform === 'ios') {
    return sendAPNS(token, payload)
  }
  // FCM placeholder for Android
  console.log(`[Push] FCM send to ${token.slice(0, 8)}... (not implemented)`)
  return false
}

async function sendAPNS(token: string, payload: PushPayload): Promise<boolean> {
  const keyId = process.env.APNS_KEY_ID
  const teamId = process.env.APNS_TEAM_ID
  const bundleId = process.env.APNS_BUNDLE_ID ?? 'com.hexbound.app'
  const isProduction = process.env.NODE_ENV === 'production'

  if (!keyId || !teamId) {
    // Dev mode — just log
    console.log(`[Push/APNS] DEV MODE — would send to ${token.slice(0, 12)}...`)
    console.log(`  Title: ${payload.title}`)
    console.log(`  Body: ${payload.body}`)
    return true // Pretend success in dev
  }

  const host = isProduction
    ? 'https://api.push.apple.com'
    : 'https://api.sandbox.push.apple.com'

  const apnsPayload = {
    aps: {
      alert: { title: payload.title, body: payload.body },
      sound: 'default',
      badge: 1,
    },
    ...(payload.data ?? {}),
  }

  try {
    // NOTE: Real APNS requires JWT token signed with the p8 key.
    // This would use jose or jsonwebtoken to create the JWT.
    // For now, we use a pre-generated bearer token from env.
    const bearerToken = process.env.APNS_BEARER_TOKEN

    const response = await fetch(`${host}/3/device/${token}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apns-topic': bundleId,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        ...(bearerToken ? { Authorization: `Bearer ${bearerToken}` } : {}),
      },
      body: JSON.stringify(apnsPayload),
    })

    if (response.status === 200) return true

    const errorBody = await response.json().catch(() => ({}))
    const reason = (errorBody as any)?.reason ?? `HTTP ${response.status}`
    throw new Error(reason)
  } catch (error: any) {
    throw error
  }
}

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------

async function logPush(
  campaignId: string | undefined,
  userId: string,
  token: string,
  payload: PushPayload,
  status: string,
  error?: string
) {
  try {
    await prisma.pushLog.create({
      data: {
        campaignId: campaignId ?? null,
        userId,
        token,
        title: payload.title,
        body: payload.body,
        status,
        error: error ?? null,
      },
    })
  } catch {
    // Non-critical — don't fail the send
  }
}
