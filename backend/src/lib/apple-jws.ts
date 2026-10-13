/**
 * Apple JWS verification — signature-checked decoding of App Store payloads.
 *
 * Apple signs every Server Notification and every signed transaction with a
 * certificate chain rooted at an Apple CA. Decoding the payload without
 * checking that signature means anyone who can POST to the webhook can claim
 * anything about any subscription. This module wraps Apple's own
 * `@apple/app-store-server-library` verifier so the chain is actually checked.
 *
 * Required configuration:
 *   APPLE_ROOT_CERTS       — base64 DER of Apple root CA cert(s), comma-separated.
 *                            Alternative to the certs directory below.
 *   APPLE_ROOT_CERTS_DIR   — directory holding Apple root CA .cer files
 *                            (default: <cwd>/certs/apple)
 *   APPLE_BUNDLE_ID        — defaults to com.hexbound.app
 *   APPLE_APP_APPLE_ID     — numeric App Store app id. REQUIRED — find it in
 *                            App Store Connect → App Information.
 *
 * Sandbox and production payloads are both accepted: Apple posts them to the
 * same url, so a verifier is built for each environment and tried in turn.
 *
 * Get the root certificates from https://www.apple.com/certificateauthority/
 * ("Apple Root CA - G3 Root" is the one that anchors App Store payloads today;
 * dropping several roots in is harmless and future-proofs a rotation).
 *
 * Without roots configured this module refuses to verify. That is deliberate:
 * an unverifiable payload must never be treated as authentic.
 */

import * as fs from 'fs'
import * as path from 'path'
import { SignedDataVerifier, Environment } from '@apple/app-store-server-library'

// Apple sends sandbox and production notifications to the SAME url, and a
// SignedDataVerifier rejects any payload whose environment doesn't match its
// own. One verifier per environment, tried in order, is the only way to accept
// both — otherwise every TestFlight renewal looks like a forgery.
let cachedVerifiers: SignedDataVerifier[] | null = null
let cachedError: string | null = null

function loadRootCertificates(): Buffer[] {
  const inline = process.env.APPLE_ROOT_CERTS?.trim()
  if (inline) {
    return inline
      .split(',')
      .map((entry) => entry.trim())
      .filter(Boolean)
      .map((entry) => Buffer.from(entry, 'base64'))
  }

  const dir = process.env.APPLE_ROOT_CERTS_DIR?.trim()
    || path.resolve(process.cwd(), 'certs/apple')

  try {
    return fs
      .readdirSync(dir)
      .filter((name) => /\.(cer|der|crt)$/i.test(name))
      .map((name) => fs.readFileSync(path.join(dir, name)))
  } catch {
    return []
  }
}

/**
 * Build (once) the verifiers for this process — production first, then sandbox.
 * Returns an empty array when configuration is missing; callers must fail closed.
 */
export function getSignedDataVerifiers(): SignedDataVerifier[] {
  if (cachedVerifiers) return cachedVerifiers
  if (cachedError) return []

  const roots = loadRootCertificates()
  if (roots.length === 0) {
    cachedError = 'No Apple root certificates configured (APPLE_ROOT_CERTS or APPLE_ROOT_CERTS_DIR)'
    console.error(`[apple-jws] ${cachedError}`)
    return []
  }

  const bundleId = process.env.APPLE_BUNDLE_ID || 'com.hexbound.app'
  const rawAppAppleId = process.env.APPLE_APP_APPLE_ID?.trim()
  const appAppleId = rawAppAppleId ? Number(rawAppAppleId) : undefined

  if (!appAppleId) {
    // The library requires the numeric app id to verify PRODUCTION payloads.
    cachedError = 'APPLE_APP_APPLE_ID is required to verify production payloads'
    console.error(`[apple-jws] ${cachedError}`)
    return []
  }

  try {
    // enableOnlineChecks=true fetches revocation state for the chain. Worth the
    // latency on an endpoint that grants paid entitlements.
    cachedVerifiers = [
      new SignedDataVerifier(roots, true, Environment.PRODUCTION, bundleId, appAppleId),
      new SignedDataVerifier(roots, true, Environment.SANDBOX, bundleId, appAppleId),
    ]
    return cachedVerifiers
  } catch (error) {
    cachedError = error instanceof Error ? error.message : 'Unknown error'
    console.error(`[apple-jws] Failed to build verifier: ${cachedError}`)
    return []
  }
}

/**
 * Verify a signed payload against every configured environment.
 *
 * `decode` receives one verifier and should call the matching
 * `verifyAndDecode*` method. The first verifier that accepts wins; if all
 * reject, the last error is rethrown so the caller can log the real reason.
 */
export async function verifyWithAnyEnvironment<T>(
  decode: (verifier: SignedDataVerifier) => Promise<T>,
): Promise<T> {
  const verifiers = getSignedDataVerifiers()
  if (verifiers.length === 0) {
    throw new Error(cachedError || 'Apple JWS verification is not configured')
  }

  let lastError: unknown
  for (const verifier of verifiers) {
    try {
      return await decode(verifier)
    } catch (error) {
      lastError = error
    }
  }
  throw lastError instanceof Error ? lastError : new Error('Apple JWS verification failed')
}

/** Why verification is unavailable, for logging. Null when it is available. */
export function signedDataVerifierError(): string | null {
  return cachedVerifiers ? null : cachedError
}

/** True when at least one verifier could be built. */
export function isSignedDataVerificationConfigured(): boolean {
  return getSignedDataVerifiers().length > 0
}

/** Reset the memoized verifier. Tests only. */
export function __resetSignedDataVerifier(): void {
  cachedVerifiers = null
  cachedError = null
}
