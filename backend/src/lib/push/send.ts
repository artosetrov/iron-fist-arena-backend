import type { CharacterClass, Prisma } from '@prisma/client'
import http2 from 'node:http2'
import { createPrivateKey, sign as cryptoSign } from 'node:crypto'
import { prisma } from '@/lib/prisma'

type PushPayload = {
  title: string
  body: string
  data?: Record<string, unknown>
}

type SendResult = {
  sent: number
  failed: number
  errors: string[]
}

type PushBroadcastFilter = {
  minLevel?: number
  maxLevel?: number
  class?: CharacterClass
}

function getErrorMessage(error: unknown): string {
  if (error instanceof Error && error.message) {
    return error.message
  }
  return 'Unknown error'
}

/**
 * Send push notification to a list of user IDs.
 * Fetches active tokens, sends live iOS/APNS pushes, logs results, and keeps
 * Android tokens inert until an actual FCM transport is shipped.
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
    } catch (error: unknown) {
      failed++
      const errMsg = getErrorMessage(error)
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
  filter?: PushBroadcastFilter
): Promise<SendResult> {
  // Build character filter to find matching userIds
  const charWhere: Prisma.CharacterWhereInput = {}
  const levelFilter: Prisma.IntFilter = {}
  if (filter?.minLevel !== undefined) levelFilter.gte = filter.minLevel
  if (filter?.maxLevel !== undefined) levelFilter.lte = filter.maxLevel
  if (Object.keys(levelFilter).length > 0) charWhere.level = levelFilter
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
// Device-level send (live APNS / deferred Android)
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

// ---------------------------------------------------------------------------
// APNs transport — HTTP/2 + ES256 provider token (AUDIT-2026-10-13 C5)
//
// Env:
//   APNS_KEY_ID    — 10-char key id from App Store Connect → Keys
//   APNS_TEAM_ID   — Apple developer team id
//   APNS_AUTH_KEY  — contents of AuthKey_XXXX.p8 (PEM; "\n" escapes allowed)
//   APNS_BUNDLE_ID — defaults to com.hexbound.app
//   APNS_ENV       — "production" | "sandbox" (TestFlight/App Store use
//                    production; defaults to production when NODE_ENV=production)
// Without key id / team id / key the sender logs and reports success=false.
// ---------------------------------------------------------------------------


let cachedJwt: { value: string; issuedAt: number } | null = null
const JWT_MAX_AGE_MS = 50 * 60 * 1000 // Apple: refresh at least hourly, not more often than every 20 min

function base64url(input: Buffer | string): string {
  return Buffer.from(input).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
}

function apnsProviderToken(): string | null {
  const keyId = process.env.APNS_KEY_ID
  const teamId = process.env.APNS_TEAM_ID
  const rawKey = process.env.APNS_AUTH_KEY
  if (!keyId || !teamId || !rawKey) return null

  const now = Date.now()
  if (cachedJwt && now - cachedJwt.issuedAt < JWT_MAX_AGE_MS) return cachedJwt.value

  const header = base64url(JSON.stringify({ alg: 'ES256', kid: keyId }))
  const claims = base64url(JSON.stringify({ iss: teamId, iat: Math.floor(now / 1000) }))
  const signingInput = `${header}.${claims}`
  const key = createPrivateKey(rawKey.replace(/\\n/g, '\n'))
  // JWS wants the raw r||s signature, not DER.
  const signature = cryptoSign('sha256', Buffer.from(signingInput), { key, dsaEncoding: 'ieee-p1363' })
  const value = `${signingInput}.${base64url(signature)}`
  cachedJwt = { value, issuedAt: now }
  return value
}

function apnsHost(): string {
  const env = process.env.APNS_ENV ?? (process.env.NODE_ENV === 'production' ? 'production' : 'sandbox')
  return env === 'production' ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com'
}

/**
 * One HTTP/2 POST to /3/device/{token}. Resolves true on 200, throws with
 * Apple's `reason` otherwise. The caller marks `BadDeviceToken` /
 * `Unregistered` tokens inactive.
 */
async function sendAPNS(token: string, payload: PushPayload): Promise<boolean> {
  const jwt = apnsProviderToken()
  const bundleId = process.env.APNS_BUNDLE_ID ?? 'com.hexbound.app'

  if (!jwt) {
    console.log(`[Push/APNS] not configured (APNS_KEY_ID/TEAM_ID/AUTH_KEY) — skipped ${token.slice(0, 12)}…: ${payload.title}`)
    return false
  }

  const apnsPayload = {
    aps: {
      alert: { title: payload.title, body: payload.body },
      sound: 'default',
      badge: 1,
    },
    ...(payload.data ?? {}),
  }

  return new Promise<boolean>((resolve, reject) => {
    const client = http2.connect(apnsHost())
    const finish = (fn: () => void) => { try { client.close() } catch { /* noop */ } fn() }
    client.on('error', (err) => finish(() => reject(err)))

    const req = client.request({
      ':method': 'POST',
      ':path': `/3/device/${token}`,
      'authorization': `bearer ${jwt}`,
      'apns-topic': bundleId,
      'apns-push-type': 'alert',
      'apns-priority': '10',
      'content-type': 'application/json',
    })

    let status = 0
    let body = ''
    req.setEncoding('utf8')
    req.on('response', (headers) => { status = Number(headers[':status'] ?? 0) })
    req.on('data', (chunk) => { body += chunk })
    req.on('end', () => finish(() => {
      if (status === 200) return resolve(true)
      let reason = `HTTP ${status}`
      try { reason = (JSON.parse(body) as { reason?: string }).reason ?? reason } catch { /* keep */ }
      reject(new Error(reason))
    }))
    req.on('error', (err) => finish(() => reject(err)))
    req.setTimeout(10_000, () => { req.close(http2.constants.NGHTTP2_CANCEL); finish(() => reject(new Error('APNs timeout'))) })
    req.end(JSON.stringify(apnsPayload))
  })
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
