import { generateKeyPairSync } from 'node:crypto'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { verifyAppleTransaction } from '@/lib/apple-iap'

const PRODUCTION = 'https://api.storekit.itunes.apple.com'
const SANDBOX = 'https://api.storekit-sandbox.itunes.apple.com'

// A throwaway P-256 key: the JWT only has to be signable, Apple is mocked.
const { privateKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' })
const PRIVATE_KEY_PEM = privateKey.export({ type: 'pkcs8', format: 'pem' }).toString()

function signedTransaction(environment: 'Sandbox' | 'Production', bundleId = 'com.hexbound.app') {
  const part = (value: object) => Buffer.from(JSON.stringify(value)).toString('base64url')
  const payload = {
    transactionId: '2000000123456789',
    originalTransactionId: '2000000123456789',
    bundleId,
    productId: 'com.hexbound.gems_small',
    purchaseDate: 1_760_000_000_000,
    type: 'Consumable',
    inAppOwnershipType: 'PURCHASED',
    environment,
    signedDate: 1_760_000_000_000,
  }
  return `${part({ alg: 'ES256' })}.${part(payload)}.signature`
}

function appleFound(environment: 'Sandbox' | 'Production', bundleId?: string) {
  return new Response(JSON.stringify({ signedTransactionInfo: signedTransaction(environment, bundleId) }), {
    status: 200,
  })
}

function appleNotFound() {
  return new Response('{"errorCode":4040010,"errorMessage":"Transaction id not found."}', { status: 404 })
}

describe('verifyAppleTransaction', () => {
  const fetchMock = vi.fn()

  beforeEach(() => {
    vi.stubEnv('APPLE_IAP_KEY_ID', 'TESTKEY123')
    vi.stubEnv('APPLE_IAP_ISSUER_ID', '00000000-0000-0000-0000-000000000000')
    vi.stubEnv('APPLE_IAP_PRIVATE_KEY', PRIVATE_KEY_PEM)
    vi.stubEnv('APPLE_IAP_ENVIRONMENT', '')
    vi.stubGlobal('fetch', fetchMock)
    fetchMock.mockReset()
    vi.spyOn(console, 'warn').mockImplementation(() => {})
    vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.unstubAllEnvs()
    vi.unstubAllGlobals()
  })

  it('asks production first and stops there when production knows the transaction', async () => {
    fetchMock.mockResolvedValueOnce(appleFound('Production'))

    const result = await verifyAppleTransaction('2000000123456789')

    expect(result.valid).toBe(true)
    expect(result.transactionInfo?.environment).toBe('Production')
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(fetchMock.mock.calls[0][0]).toBe(`${PRODUCTION}/inApps/v1/transactions/2000000123456789`)
  })

  it('accepts a sandbox purchase (App Review, TestFlight) after production answers 404', async () => {
    fetchMock.mockResolvedValueOnce(appleNotFound()).mockResolvedValueOnce(appleFound('Sandbox'))

    const result = await verifyAppleTransaction('2000000123456789')

    expect(result.valid).toBe(true)
    expect(result.transactionInfo?.environment).toBe('Sandbox')
    expect(fetchMock.mock.calls.map(([url]) => url)).toEqual([
      `${PRODUCTION}/inApps/v1/transactions/2000000123456789`,
      `${SANDBOX}/inApps/v1/transactions/2000000123456789`,
    ])
  })

  it('reports not found when neither environment knows the transaction', async () => {
    fetchMock.mockResolvedValueOnce(appleNotFound()).mockResolvedValueOnce(appleNotFound())

    const result = await verifyAppleTransaction('2000000123456789')

    expect(result).toEqual({ valid: false, error: 'Transaction not found in App Store' })
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it('starts with the sandbox when APPLE_IAP_ENVIRONMENT=sandbox, then asks production', async () => {
    vi.stubEnv('APPLE_IAP_ENVIRONMENT', 'sandbox')
    fetchMock.mockResolvedValueOnce(appleNotFound()).mockResolvedValueOnce(appleFound('Production'))

    const result = await verifyAppleTransaction('2000000123456789')

    expect(result.valid).toBe(true)
    expect(fetchMock.mock.calls.map(([url]) => url)).toEqual([
      `${SANDBOX}/inApps/v1/transactions/2000000123456789`,
      `${PRODUCTION}/inApps/v1/transactions/2000000123456789`,
    ])
  })

  it('does not fall back on errors other than 404', async () => {
    fetchMock.mockResolvedValueOnce(new Response('unauthorized', { status: 401 }))

    const result = await verifyAppleTransaction('2000000123456789')

    expect(result).toEqual({ valid: false, error: 'Apple API error: 401' })
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it('still rejects another app’s sandbox transaction', async () => {
    fetchMock.mockResolvedValueOnce(appleNotFound()).mockResolvedValueOnce(appleFound('Sandbox', 'com.other.app'))

    const result = await verifyAppleTransaction('2000000123456789')

    expect(result.valid).toBe(false)
    expect(result.error).toMatch(/Bundle ID mismatch/)
  })
})
