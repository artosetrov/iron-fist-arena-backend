import 'server-only'

import { cookies } from 'next/headers'

const DEFAULT_BACKEND_API_URL = 'http://localhost:3001'

function getBackendAdminBaseUrl(): string {
  return process.env.NEXT_PUBLIC_API_URL || process.env.API_URL || DEFAULT_BACKEND_API_URL
}

function extractErrorMessage(payload: unknown, fallback: string): string {
  if (!payload || typeof payload !== 'object') return fallback

  const error = (payload as { error?: unknown }).error
  return typeof error === 'string' && error.length > 0 ? error : fallback
}

export async function callBackendAdminJson<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = (await cookies()).get('admin-token')?.value
  if (!token) throw new Error('Unauthorized')

  const headers = new Headers(init.headers)
  headers.set('Authorization', `Bearer ${token}`)

  if (init.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json')
  }

  const response = await fetch(`${getBackendAdminBaseUrl()}${path}`, {
    ...init,
    headers,
    cache: 'no-store',
  })

  const contentType = response.headers.get('content-type') ?? ''
  const payload = contentType.includes('application/json')
    ? await response.json().catch(() => null)
    : await response.text().catch(() => null)

  if (!response.ok) {
    throw new Error(extractErrorMessage(payload, `Backend admin request failed (${response.status})`))
  }

  return payload as T
}
