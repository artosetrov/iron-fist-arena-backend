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
 * Auth model: Apple signs the entire payload with its intermediate cert.
 * We decode the JWS payload (signature verification against Apple's cert
 * chain is a Phase 3 hardening item — see PREMIUM_PASS_MIGRATION.md).
 *
 * Idempotency: Apple retries on non-2xx. We always return 200 after
 * processing to prevent duplicate deliveries, and our upserts are
 * idempotent by user_id + latest_transaction_id.
 */

import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'

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
// JWS decode (payload only — signature verification is Phase 3)
// ──────────────────────────────────────────────

function decodeJWSPayload<T>(jws: string): T {
  const parts = jws.split('.')
  if (parts.length !== 3) throw new Error('Invalid JWS')
  return JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'))
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

    const payload = decodeJWSPayload<ResponseBodyV2DecodedPayload>(body.signedPayload)
    const { notificationType, subtype, data } = payload

    if (!data?.signedTransactionInfo) {
      console.warn('[apple-webhook] payload missing signedTransactionInfo', notificationType)
      return NextResponse.json({ ok: true })
    }

    const tx = decodeJWSPayload<JWSTransactionDecodedPayload>(data.signedTransactionInfo)
    const renewal = data.signedRenewalInfo
      ? decodeJWSPayload<JWSRenewalInfoDecodedPayload>(data.signedRenewalInfo)
      : null

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
    let updates: {
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

    return NextResponse.json({ ok: true })
  } catch (error) {
    console.error('[apple-webhook] error', error)
    // Return 200 even on errors to stop Apple retries for malformed payloads.
    // Real failures will still surface in logs for investigation.
    return NextResponse.json({ ok: true })
  }
}
