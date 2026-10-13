/**
 * Apple Server Notifications v2 webhook — Premium Pass renewal authority.
 *
 * Phase 2 (2026-04-14). See docs/06_game_systems/PREMIUM_PASS_MIGRATION.md.
 *
 * Endpoint registered in App Store Connect → App → General → App Information
 *   Prod URL:    https://api.hexboundapp.com/api/iap/apple-notifications
 *   Sandbox URL: same (Apple routes based on environment)
 *
 * Apple POSTs a signedPayload (JWS) on lifecycle events:
 *   DID_RENEW             — periodic renewal → extend expiresAt
 *   EXPIRED               — subscription ended without renewal → status=expired
 *   DID_CHANGE_RENEWAL_STATUS — user toggled auto-renew → update autoRenew
 *   GRACE_PERIOD_EXPIRED  — billing retry window ended → status=expired
 *   REFUND / REVOKE       — Apple revoked entitlement → status=refunded
 *   OFFER_REDEEMED        — promo offer applied → update expiresAt
 *
 * Auth model: this endpoint is unauthenticated by design — Apple cannot send
 * a bearer token. Authenticity comes entirely from the JWS signature, which
 * is verified against Apple's certificate chain via `@/lib/apple-jws`
 * (Apple's own `SignedDataVerifier`). An unverifiable payload is rejected,
 * never decoded-and-trusted: this row grants paid entitlements, so a forged
 * DID_RENEW would be free premium forever.
 *
 * Idempotency: Apple retries on non-2xx. We always return 200 after
 * processing to prevent duplicate deliveries, and our upserts are
 * idempotent by user_id + latest_transaction_id.
 */

import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import { IAP_PRODUCTS } from '@/lib/game/balance'
import {
  isSignedDataVerificationConfigured,
  signedDataVerifierError,
  verifyWithAnyEnvironment,
} from '@/lib/apple-jws'

// ──────────────────────────────────────────────
// Apple payload types (minimal — see Apple docs for full schema)
// ──────────────────────────────────────────────

interface ResponseBodyV2DecodedPayload {
  notificationType: string
  subtype?: string
  notificationUUID: string
  data?: {
    bundleId: string
    environment: 'Sandbox' | 'Production'
    signedTransactionInfo?: string  // JWS
    signedRenewalInfo?: string      // JWS
  }
  version: string
  signedDate: number
}

interface JWSTransactionDecodedPayload {
  transactionId: string
  originalTransactionId: string
  productId: string
  purchaseDate: number
  expiresDate?: number
  revocationDate?: number
  revocationReason?: 0 | 1
  type: string
}

interface JWSRenewalInfoDecodedPayload {
  originalTransactionId: string
  autoRenewStatus: 0 | 1 // 0=off, 1=on
  autoRenewProductId?: string
  expirationIntent?: 1 | 2 | 3 | 4 | 5
  productId: string
}


// ──────────────────────────────────────────────
// Handler
// ──────────────────────────────────────────────

export async function POST(req: NextRequest) {
  try {
    const body = await req.json() as { signedPayload?: string }
    if (!body.signedPayload) {
      return NextResponse.json({ error: 'missing signedPayload' }, { status: 400 })
    }

    // Signature first. Nothing below may read the payload until Apple's chain
    // has vouched for it.
    if (!isSignedDataVerificationConfigured()) {
      // Misconfiguration, not an attack. 503 makes Apple retry, so no
      // notification is lost once the certificates are in place.
      console.error('[apple-webhook] verification unavailable:', signedDataVerifierError())
      return NextResponse.json({ error: 'verification unavailable' }, { status: 503 })
    }

    let payload: ResponseBodyV2DecodedPayload
    let tx: JWSTransactionDecodedPayload
    let renewal: JWSRenewalInfoDecodedPayload | null = null

    try {
      const signedPayload = body.signedPayload
      payload = await verifyWithAnyEnvironment((v) =>
        v.verifyAndDecodeNotification(signedPayload),
      ) as unknown as ResponseBodyV2DecodedPayload

      const signedTransactionInfo = payload.data?.signedTransactionInfo
      if (!signedTransactionInfo) {
        console.warn('[apple-webhook] payload missing signedTransactionInfo', payload.notificationType)
        return NextResponse.json({ ok: true })
      }

      tx = await verifyWithAnyEnvironment((v) =>
        v.verifyAndDecodeTransaction(signedTransactionInfo),
      ) as unknown as JWSTransactionDecodedPayload

      const signedRenewalInfo = payload.data?.signedRenewalInfo
      renewal = signedRenewalInfo
        ? (await verifyWithAnyEnvironment((v) =>
            v.verifyAndDecodeRenewalInfo(signedRenewalInfo),
          )) as unknown as JWSRenewalInfoDecodedPayload
        : null
    } catch (error) {
      // Bad signature, wrong bundle id, expired cert, or a revocation-check
      // outage. Apple retries on any non-2xx regardless, so 401 here is a
      // signal for our own logs rather than a way to stop redelivery.
      const message = error instanceof Error ? error.message : 'Unknown error'
      console.error('[apple-webhook] signature verification failed:', message)
      return NextResponse.json({ error: 'invalid signature' }, { status: 401 })
    }

    const { notificationType, subtype } = payload

    // Every field of Apple's decoded payloads is optional in the library's
    // types. Without this guard a missing originalTransactionId becomes
    // `findFirst({ where: { originalTransactionId: undefined } })`, which in
    // Prisma means "no filter" — i.e. it would return, and then mutate, an
    // unrelated player's subscription.
    if (!tx.originalTransactionId) {
      console.warn('[apple-webhook] transaction has no originalTransactionId', notificationType)
      return NextResponse.json({ ok: true })
    }

    if (!notificationType) {
      console.warn('[apple-webhook] payload has no notificationType', tx.originalTransactionId)
      return NextResponse.json({ ok: true })
    }

    // Look up the existing subscription by original_transaction_id.
    // original_transaction_id is stable across all renewals / resumes.
    const sub = await prisma.premiumSubscription.findFirst({
      where: { originalTransactionId: tx.originalTransactionId },
    })

    if (!sub) {
      // No matching subscription — this can happen if a user subscribes
      // through a flow we haven't seen (e.g. family share, cross-device).
      // Log for monitoring; Apple will keep retrying and we'll backfill
      // once /verify-receipt sees a transaction from the same user.
      console.warn('[apple-webhook] no subscription for original_tx_id', tx.originalTransactionId, notificationType)
      return NextResponse.json({ ok: true })
    }

    // Compute next state based on notification type.
    // Apple docs: https://developer.apple.com/documentation/appstoreservernotifications/notificationtype
    const updates: {
      expiresAt?: Date
      latestTransactionId?: string
      status?: 'active' | 'grace_period' | 'expired' | 'refunded'
      autoRenew?: boolean
    } = {}

    switch (notificationType) {
      case 'DID_RENEW':
      case 'SUBSCRIBED':
      case 'OFFER_REDEEMED':
        // Active renewal — extend expiresAt.
        if (tx.expiresDate) updates.expiresAt = new Date(tx.expiresDate)
        updates.latestTransactionId = tx.transactionId
        updates.status = 'active'
        break

      case 'DID_FAIL_TO_RENEW':
        // Billing issue — enter grace period. Apple will retry.
        updates.status = subtype === 'GRACE_PERIOD' ? 'grace_period' : 'expired'
        break

      case 'EXPIRED':
        updates.status = 'expired'
        break

      case 'DID_CHANGE_RENEWAL_STATUS':
        if (renewal) updates.autoRenew = renewal.autoRenewStatus === 1
        break

      case 'REFUND':
      case 'REVOKE':
      case 'CONSUMPTION_REQUEST':
        // Apple reversed the charge — revoke entitlement immediately.
        updates.status = 'refunded'
        break

      default:
        // Unknown / non-actionable (TEST, PRICE_INCREASE, etc.) — ack and move on.
        console.log('[apple-webhook] non-actionable notification', notificationType, subtype)
        return NextResponse.json({ ok: true })
    }

    if (Object.keys(updates).length > 0) {
      await prisma.premiumSubscription.update({
        where: { id: sub.id },
        data: updates,
      })
    }

    // Renewal gems. The Premium Pass is sold as "+300 gems per renewal"
    // (IAP_PRODUCTS.premium_pass_monthly.subscription.monthlyGems); the first
    // allotment is credited by /verify-receipt, every later one here.
    // Idempotent against Apple retries: grant only when this renewal's
    // transactionId was not yet recorded on the row (AUDIT-2026-10-13 H4).
    if (notificationType === 'DID_RENEW' && sub.latestTransactionId !== tx.transactionId) {
      const monthlyGems = IAP_PRODUCTS[sub.productId]?.subscription?.monthlyGems ?? 0
      if (monthlyGems > 0) {
        await prisma.$transaction(async (dbTx) => {
          // Re-check under the row to beat a concurrent duplicate delivery.
          const claimed = await dbTx.$executeRawUnsafe(
            `UPDATE "premium_subscriptions"
                SET "renewal_gems_tx_id" = $2
              WHERE "id" = $1
                AND ("renewal_gems_tx_id" IS NULL OR "renewal_gems_tx_id" <> $2)`,
            sub.id,
            tx.transactionId,
          )
          if (claimed === 1) {
            await dbTx.user.update({
              where: { id: sub.userId },
              data: { gems: { increment: monthlyGems } },
            })
          }
        })
      }
    }

    return NextResponse.json({ ok: true })
  } catch (error) {
    console.error('[apple-webhook] error', error)
    // Return 200 even on errors to stop Apple retries for malformed payloads.
    // Real failures will still surface in logs for investigation.
    return NextResponse.json({ ok: true })
  }
}
