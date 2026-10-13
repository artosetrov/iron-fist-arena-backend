import { beforeEach, describe, expect, it, vi } from 'vitest'
import { makeNextRequest } from '../helpers/next-request'

const { prismaMock, verifierMock, mockGetSignedDataVerifier } = vi.hoisted(() => {
  // The route must verify Apple's JWS signature before reading anything.
  // In tests the verifier is stubbed to decode the unsigned test payloads,
  // which keeps the fixtures readable while still exercising the real
  // "verify first, then trust" control flow.
  const decode = (jws: string) =>
    JSON.parse(Buffer.from(jws.split('.')[1], 'base64url').toString('utf8'))

  const verifierMock = {
    verifyAndDecodeNotification: vi.fn(async (jws: string) => decode(jws)),
    verifyAndDecodeTransaction: vi.fn(async (jws: string) => decode(jws)),
    verifyAndDecodeRenewalInfo: vi.fn(async (jws: string) => decode(jws)),
  }

  return {
    prismaMock: {
      premiumSubscription: {
        findFirst: vi.fn(),
        update: vi.fn(),
      },
    },
    verifierMock,
    mockGetSignedDataVerifier: vi.fn<() => typeof verifierMock | null>(() => verifierMock),
  }
})

vi.mock('@/lib/prisma', () => ({
  prisma: prismaMock,
}))

vi.mock('@/lib/apple-jws', () => ({
  isSignedDataVerificationConfigured: () => mockGetSignedDataVerifier() !== null,
  signedDataVerifierError: () => 'test: verifier unavailable',
  verifyWithAnyEnvironment: async (decode: (v: typeof verifierMock) => Promise<unknown>) => {
    const verifier = mockGetSignedDataVerifier()
    if (!verifier) throw new Error('not configured')
    return decode(verifier)
  },
}))

import { POST } from '@/app/api/iap/apple-notifications/route'

function makeSignedPayload(payload: unknown): string {
  return `header.${Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url')}.signature`
}

describe('POST /api/iap/apple-notifications', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    mockGetSignedDataVerifier.mockReturnValue(verifierMock)
    const decode = (jws: string) =>
      JSON.parse(Buffer.from(jws.split('.')[1], 'base64url').toString('utf8'))
    verifierMock.verifyAndDecodeNotification.mockImplementation(async (jws: string) => decode(jws))
    verifierMock.verifyAndDecodeTransaction.mockImplementation(async (jws: string) => decode(jws))
    verifierMock.verifyAndDecodeRenewalInfo.mockImplementation(async (jws: string) => decode(jws))

    prismaMock.premiumSubscription.findFirst.mockResolvedValue({
      id: 'sub-1',
      originalTransactionId: 'orig-sub',
    })
    prismaMock.premiumSubscription.update.mockResolvedValue({
      id: 'sub-1',
    })
  })

  it('acknowledges DID_RENEW and updates the subscription state from Apple payloads', async () => {
    const response = await POST(
      makeNextRequest('http://localhost/api/iap/apple-notifications', {
        method: 'POST',
        body: JSON.stringify({
          signedPayload: makeSignedPayload({
            notificationType: 'DID_RENEW',
            notificationUUID: 'notif-1',
            version: '2.0',
            signedDate: Date.parse('2026-04-15T12:00:00.000Z'),
            data: {
              bundleId: 'com.hexbound.app',
              environment: 'Sandbox',
              signedTransactionInfo: makeSignedPayload({
                transactionId: 'tx-renew-2',
                originalTransactionId: 'orig-sub',
                productId: 'com.hexbound.premium_pass_monthly',
                purchaseDate: Date.parse('2026-04-15T12:00:00.000Z'),
                expiresDate: Date.parse('2026-05-15T12:00:00.000Z'),
                type: 'Auto-Renewable Subscription',
              }),
              signedRenewalInfo: makeSignedPayload({
                originalTransactionId: 'orig-sub',
                autoRenewStatus: 1,
                productId: 'com.hexbound.premium_pass_monthly',
              }),
            },
          }),
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({ ok: true })
    expect(prismaMock.premiumSubscription.findFirst).toHaveBeenCalledWith({
      where: { originalTransactionId: 'orig-sub' },
    })
    expect(prismaMock.premiumSubscription.update).toHaveBeenCalledWith({
      where: { id: 'sub-1' },
      data: {
        expiresAt: new Date('2026-05-15T12:00:00.000Z'),
        latestTransactionId: 'tx-renew-2',
        status: 'active',
      },
    })
  })

  it('returns 200 without updating when the webhook arrives before any local subscription row exists', async () => {
    prismaMock.premiumSubscription.findFirst.mockResolvedValue(null)

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/apple-notifications', {
        method: 'POST',
        body: JSON.stringify({
          signedPayload: makeSignedPayload({
            notificationType: 'EXPIRED',
            notificationUUID: 'notif-2',
            version: '2.0',
            signedDate: Date.parse('2026-04-15T12:00:00.000Z'),
            data: {
              bundleId: 'com.hexbound.app',
              environment: 'Sandbox',
              signedTransactionInfo: makeSignedPayload({
                transactionId: 'tx-expired',
                originalTransactionId: 'orig-missing',
                productId: 'com.hexbound.premium_pass_monthly',
                purchaseDate: Date.parse('2026-04-15T12:00:00.000Z'),
                expiresDate: Date.parse('2026-05-15T12:00:00.000Z'),
                type: 'Auto-Renewable Subscription',
              }),
            },
          }),
        }),
      }),
    )

    expect(response.status).toBe(200)
    await expect(response.json()).resolves.toMatchObject({ ok: true })
    expect(prismaMock.premiumSubscription.update).not.toHaveBeenCalled()
  })

  it('rejects a payload whose signature does not verify and changes nothing', async () => {
    verifierMock.verifyAndDecodeNotification.mockRejectedValue(new Error('Invalid signature'))

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/apple-notifications', {
        method: 'POST',
        body: JSON.stringify({
          signedPayload: makeSignedPayload({
            notificationType: 'DID_RENEW',
            notificationUUID: 'notif-forged',
            version: '2.0',
            signedDate: Date.now(),
            data: {
              bundleId: 'com.hexbound.app',
              environment: 'Production',
              signedTransactionInfo: makeSignedPayload({
                transactionId: 'tx-forged',
                originalTransactionId: 'orig-sub',
                productId: 'com.hexbound.premium_pass_monthly',
                purchaseDate: Date.now(),
                expiresDate: Date.parse('2099-01-01T00:00:00.000Z'),
                type: 'Auto-Renewable Subscription',
              }),
            },
          }),
        }),
      }),
    )

    expect(response.status).toBe(401)
    expect(prismaMock.premiumSubscription.update).not.toHaveBeenCalled()
    expect(prismaMock.premiumSubscription.findFirst).not.toHaveBeenCalled()
  })

  it('refuses to process notifications when verification is not configured', async () => {
    mockGetSignedDataVerifier.mockReturnValue(null)

    const response = await POST(
      makeNextRequest('http://localhost/api/iap/apple-notifications', {
        method: 'POST',
        body: JSON.stringify({ signedPayload: makeSignedPayload({ notificationType: 'DID_RENEW' }) }),
      }),
    )

    expect(response.status).toBe(503)
    expect(prismaMock.premiumSubscription.update).not.toHaveBeenCalled()
  })
})
