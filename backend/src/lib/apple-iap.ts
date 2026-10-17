/**
 * Apple App Store Server API v2 — Transaction Verification
 *
 * Uses the App Store Server API to verify StoreKit 2 transactions.
 * Docs: https://developer.apple.com/documentation/appstoreserverapi
 *
 * Required env vars:
 *   APPLE_IAP_KEY_ID       — Key ID from App Store Connect (API Keys → In-App Purchase)
 *   APPLE_IAP_ISSUER_ID    — Issuer ID from App Store Connect
 *   APPLE_IAP_PRIVATE_KEY  — .p8 private key contents (with \n for newlines)
 *   APPLE_IAP_PRIVATE_KEY_PATH — local path to a .p8 private key file (preferred for local dev)
 *   APPLE_BUNDLE_ID        — Your app bundle ID (com.hexbound.app)
 *
 * APPLE_IAP_ENVIRONMENT (production | sandbox, default production) only picks
 * which App Store environment is asked FIRST. A transaction it does not know
 * (404) is looked up in the other one: App Review and TestFlight buy in the
 * sandbox with production-signed builds, so a production server that only
 * asks production fails every reviewer purchase (Guideline 2.1) — and a
 * sandbox-only one fails every real purchase after launch.
 */

import * as crypto from 'crypto'
import * as fs from 'fs'
import * as path from 'path'

// ──────────────────────────────────────────────
// Types
// ──────────────────────────────────────────────

export interface AppleTransactionInfo {
  transactionId: string
  originalTransactionId: string
  bundleId: string
  productId: string
  purchaseDate: number       // ms since epoch
  type: 'Consumable' | 'Non-Consumable' | 'Auto-Renewable Subscription' | 'Non-Renewing Subscription'
  inAppOwnershipType: 'PURCHASED' | 'FAMILY_SHARED'
  environment: 'Sandbox' | 'Production'
  signedDate: number
  // Subscription-only fields (present when type is 'Auto-Renewable Subscription').
  // See docs/06_game_systems/PREMIUM_PASS_MIGRATION.md.
  expiresDate?: number       // ms since epoch — renewal boundary
  revocationDate?: number    // ms since epoch — refund/family-revoke timestamp
  revocationReason?: 0 | 1   // 0=app issue, 1=other (refund)
  // UUID the client attached at purchase time (StoreKit `appAccountToken`).
  // iOS sets it to the Hexbound user id so a receipt can be bound to the
  // account that bought it (AUDIT-2026-10-13 H8). Absent on older builds.
  appAccountToken?: string
}

export interface AppleVerifyResult {
  valid: boolean
  transactionInfo?: AppleTransactionInfo
  error?: string
}

// ──────────────────────────────────────────────
// Product ID mapping (App Store Connect ↔ internal)
// ──────────────────────────────────────────────

/**
 * The ONLY authoritative link between an App Store Connect product identifier
 * and an internal `IAP_PRODUCTS` key.
 *
 * Rewards must always be resolved from Apple's `productId`, never from a
 * client-supplied `product_id` — otherwise a real $0.99 receipt can be replayed
 * against a $49.99 SKU. Adding a SKU means adding it here, in
 * `IAP_PRODUCTS` (balance.ts), in the iOS `IAPProduct` enum, in
 * `HexboundProducts.storekit`, and in App Store Connect.
 */
export const APPLE_TO_INTERNAL_PRODUCT_ID: Record<string, string> = {
  // Gem packs
  'com.hexbound.gems_small': 'gems_small',
  'com.hexbound.gems_medium': 'gems_medium',
  'com.hexbound.gems_large': 'gems_large',
  'com.hexbound.gems_huge': 'gems_huge',
  'com.hexbound.gems_mega': 'gems_mega',
  // Adventurer's Bundles (Economy v3)
  'com.hexbound.adventurer_bundle_I': 'adventurer_bundle_I',
  'com.hexbound.adventurer_bundle_II': 'adventurer_bundle_II',
  'com.hexbound.adventurer_bundle_III': 'adventurer_bundle_III',
  // Starter / subscription
  'com.hexbound.starter_bundle': 'starter_bundle',
  'com.hexbound.monthly_gem_card': 'monthly_gem_card',
  'com.hexbound.premium_pass_monthly': 'premium_pass_monthly',
  // Retired SKUs — kept so an in-flight receipt still resolves to the right
  // product and is rejected by the `enabled: false` gate rather than by a
  // confusing "unknown product" error.
  'com.hexbound.gold500': 'gold_500',
  'com.hexbound.gold1200': 'gold_1200',
  'com.hexbound.gold3500': 'gold_3500',
  'com.hexbound.gold8000': 'gold_8000',
  'com.hexbound.gold20000': 'gold_20000',
  'com.hexbound.premium_forever': 'premium_forever',
}

/**
 * Resolve Apple's product identifier to an internal `IAP_PRODUCTS` key.
 * Returns undefined for an identifier we do not sell.
 *
 * A bare internal key is also accepted, because some environments (StoreKit
 * Configuration files, sandbox setups) register SKUs without the reverse-DNS
 * prefix. This stays strict where it matters: whatever comes back still has to
 * equal the product the caller claimed, so it can never widen a $0.99 receipt
 * into a $49.99 grant.
 */
export function internalProductIdFromApple(appleProductId: string): string | undefined {
  const mapped = APPLE_TO_INTERNAL_PRODUCT_ID[appleProductId]
  if (mapped) return mapped
  return Object.values(APPLE_TO_INTERNAL_PRODUCT_ID).includes(appleProductId)
    ? appleProductId
    : undefined
}

// ──────────────────────────────────────────────
// JWT Generation for App Store Server API
// ──────────────────────────────────────────────

function loadApplePrivateKey(): string | undefined {
  const inlinePrivateKey = process.env.APPLE_IAP_PRIVATE_KEY?.replace(/\\n/g, '\n').trim()
  if (inlinePrivateKey) return inlinePrivateKey

  const privateKeyPath = process.env.APPLE_IAP_PRIVATE_KEY_PATH?.trim()
  if (!privateKeyPath) return undefined

  const resolvedPath = path.isAbsolute(privateKeyPath)
    ? privateKeyPath
    : path.resolve(process.cwd(), privateKeyPath)

  try {
    return fs.readFileSync(resolvedPath, 'utf8').trim()
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error'
    console.warn(`[Apple IAP] Failed to read APPLE_IAP_PRIVATE_KEY_PATH at ${resolvedPath}: ${message}`)
    return undefined
  }
}

function getAppleConfig() {
  const keyId = process.env.APPLE_IAP_KEY_ID
  const issuerId = process.env.APPLE_IAP_ISSUER_ID
  const privateKey = loadApplePrivateKey()
  const bundleId = process.env.APPLE_BUNDLE_ID || 'com.hexbound.app'
  const environment = process.env.APPLE_IAP_ENVIRONMENT || 'production'

  if (!keyId || !issuerId || !privateKey) {
    return null // Config not set — skip verification
  }

  return { keyId, issuerId, privateKey, bundleId, environment }
}

/**
 * Generate a signed JWT for Apple App Store Server API.
 * Uses ES256 (P-256 + SHA-256) as required by Apple.
 */
function generateAppleJWT(keyId: string, issuerId: string, privateKey: string, bundleId: string): string {
  const now = Math.floor(Date.now() / 1000)

  const header = {
    alg: 'ES256',
    kid: keyId,
    typ: 'JWT',
  }

  const payload = {
    iss: issuerId,
    iat: now,
    exp: now + 3600, // 1 hour
    aud: 'appstoreconnect-v1',
    bid: bundleId,
  }

  const encodedHeader = base64url(JSON.stringify(header))
  const encodedPayload = base64url(JSON.stringify(payload))
  const signingInput = `${encodedHeader}.${encodedPayload}`

  const sign = crypto.createSign('SHA256')
  sign.update(signingInput)
  const signature = sign.sign(privateKey)

  // Convert DER signature to raw r|s format for ES256
  const rawSig = derToRaw(signature)
  const encodedSignature = base64url(rawSig)

  return `${signingInput}.${encodedSignature}`
}

function base64url(input: string | Buffer): string {
  const buf = typeof input === 'string' ? Buffer.from(input, 'utf8') : input
  return buf.toString('base64url')
}

/**
 * Convert DER-encoded ECDSA signature to raw 64-byte r|s format.
 */
function derToRaw(derSig: Buffer): Buffer {
  // DER format: 0x30 [total-len] 0x02 [r-len] [r] 0x02 [s-len] [s]
  let offset = 2 // skip 0x30 and total length

  // Read r
  offset++ // skip 0x02
  const rLen = derSig[offset++]
  const r = derSig.subarray(offset, offset + rLen)
  offset += rLen

  // Read s
  offset++ // skip 0x02
  const sLen = derSig[offset++]
  const s = derSig.subarray(offset, offset + sLen)

  // Pad/trim to 32 bytes each
  const raw = Buffer.alloc(64)
  r.subarray(Math.max(0, rLen - 32)).copy(raw, 32 - Math.min(32, rLen))
  s.subarray(Math.max(0, sLen - 32)).copy(raw, 64 - Math.min(32, sLen))

  return raw
}

// ──────────────────────────────────────────────
// Decode Apple's signed JWS (signed transaction)
// ──────────────────────────────────────────────

function decodeJWSPayload<T>(jws: string): T {
  const parts = jws.split('.')
  if (parts.length !== 3) throw new Error('Invalid JWS format')
  const payload = Buffer.from(parts[1], 'base64url').toString('utf8')
  return JSON.parse(payload)
}

// ──────────────────────────────────────────────
// Main verification function
// ──────────────────────────────────────────────

type StoreKitEnvironment = 'production' | 'sandbox'

const STOREKIT_API_HOSTS: Record<StoreKitEnvironment, string> = {
  production: 'https://api.storekit.itunes.apple.com',
  sandbox: 'https://api.storekit-sandbox.itunes.apple.com',
}

/**
 * Verify an Apple IAP transaction using the App Store Server API v2.
 *
 * GET /v1/transactions/{transactionId}
 *
 * Returns transaction info if valid, or an error message.
 */
/**
 * True on any deployed environment, not just when NODE_ENV happens to be set.
 * A staging box with NODE_ENV unset must not become a free-currency endpoint.
 */
function isProductionDeploy(): boolean {
  if (process.env.NODE_ENV === 'production') return true
  const vercelEnv = process.env.VERCEL_ENV
  return vercelEnv === 'production' || vercelEnv === 'preview'
}

export async function verifyAppleTransaction(transactionId: string): Promise<AppleVerifyResult> {
  const config = getAppleConfig()

  // If Apple IAP keys are not configured we cannot prove anything about this
  // transaction. Fail CLOSED in production — a missing env var must never be a
  // path to free currency. Dev/sandbox keeps the bypass so StoreKit
  // Configuration testing still works without App Store Connect keys.
  if (!config) {
    if (isProductionDeploy()) {
      console.error('[Apple IAP] Keys not configured in production — rejecting transaction')
      return {
        valid: false,
        error: 'Purchase verification is temporarily unavailable. You have not been charged for anything that was not delivered — contact support with your receipt.',
      }
    }
    console.warn('[Apple IAP] Keys not configured — skipping server-side verification (non-production only)')
    return { valid: true }
  }

  try {
    const jwt = generateAppleJWT(
      config.keyId,
      config.issuerId,
      config.privateKey,
      config.bundleId
    )

    // The configured environment first, then the other one on a 404 — see the
    // header comment. Any other failure is final: a 401 or a 5xx says nothing
    // about which environment owns the transaction.
    const order: StoreKitEnvironment[] = config.environment === 'sandbox'
      ? ['sandbox', 'production']
      : ['production', 'sandbox']

    let response: Response | undefined
    for (const [i, env] of order.entries()) {
      response = await fetch(
        `${STOREKIT_API_HOSTS[env]}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
        {
          headers: {
            Authorization: `Bearer ${jwt}`,
            'Content-Type': 'application/json',
          },
        }
      )
      // The last 404 falls through with its body unread, for the error below.
      if (response.status !== 404 || i === order.length - 1) break
      await response.text().catch(() => '') // drain before the next request
      console.warn(`[Apple IAP] Transaction ${transactionId} not found in ${env}, asking ${order[i + 1]}`)
    }

    if (!response) {
      return { valid: false, error: 'Failed to verify with Apple' }
    }

    if (!response.ok) {
      const errorBody = await response.text()
      console.error(`[Apple IAP] API error ${response.status}: ${errorBody}`)

      if (response.status === 404) {
        return { valid: false, error: 'Transaction not found in App Store' }
      }
      return { valid: false, error: `Apple API error: ${response.status}` }
    }

    const data = await response.json() as { signedTransactionInfo: string }

    if (!data.signedTransactionInfo) {
      return { valid: false, error: 'No signed transaction info in response' }
    }

    // Decode the JWS payload — Apple signs it with their certificate
    const txInfo = decodeJWSPayload<AppleTransactionInfo>(data.signedTransactionInfo)

    // Validate bundle ID matches our app
    if (txInfo.bundleId !== config.bundleId) {
      return {
        valid: false,
        error: `Bundle ID mismatch: expected ${config.bundleId}, got ${txInfo.bundleId}`,
      }
    }

    // Sandbox money is not real money: keep these greppable in production
    // logs (App Review, TestFlight testers, sandbox accounts).
    if (txInfo.environment === 'Sandbox' && isProductionDeploy()) {
      console.warn(`[Apple IAP] Sandbox transaction ${transactionId} (${txInfo.productId}) accepted in production`)
    }

    return { valid: true, transactionInfo: txInfo }
  } catch (error) {
    console.error('[Apple IAP] Verification error:', error)
    return { valid: false, error: 'Failed to verify with Apple' }
  }
}
