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
 *   APPLE_BUNDLE_ID        — Your app bundle ID (com.hexbound.app)
 *
 * In sandbox/development, set:
 *   APPLE_IAP_ENVIRONMENT=sandbox
 */

import * as crypto from 'crypto'

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
  // ... more fields available
}

export interface AppleVerifyResult {
  valid: boolean
  transactionInfo?: AppleTransactionInfo
  error?: string
}

// ──────────────────────────────────────────────
// JWT Generation for App Store Server API
// ──────────────────────────────────────────────

function getAppleConfig() {
  const keyId = process.env.APPLE_IAP_KEY_ID
  const issuerId = process.env.APPLE_IAP_ISSUER_ID
  const privateKey = process.env.APPLE_IAP_PRIVATE_KEY?.replace(/\\n/g, '\n')
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

/**
 * Verify an Apple IAP transaction using the App Store Server API v2.
 *
 * GET /v1/transactions/{transactionId}
 *
 * Returns transaction info if valid, or an error message.
 */
export async function verifyAppleTransaction(transactionId: string): Promise<AppleVerifyResult> {
  const config = getAppleConfig()

  // If Apple IAP keys are not configured, skip server verification
  // (allows dev/sandbox testing with StoreKit Configuration)
  if (!config) {
    console.warn('[Apple IAP] Keys not configured — skipping server-side verification')
    return { valid: true }
  }

  try {
    const jwt = generateAppleJWT(
      config.keyId,
      config.issuerId,
      config.privateKey,
      config.bundleId
    )

    const baseUrl = config.environment === 'sandbox'
      ? 'https://api.storekit-sandbox.itunes.apple.com'
      : 'https://api.storekit.itunes.apple.com'

    const response = await fetch(
      `${baseUrl}/inApps/v1/transactions/${transactionId}`,
      {
        headers: {
          Authorization: `Bearer ${jwt}`,
          'Content-Type': 'application/json',
        },
      }
    )

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

    return { valid: true, transactionInfo: txInfo }
  } catch (error) {
    console.error('[Apple IAP] Verification error:', error)
    return { valid: false, error: 'Failed to verify with Apple' }
  }
}
