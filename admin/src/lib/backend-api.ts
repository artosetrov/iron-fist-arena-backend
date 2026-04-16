import { cookies } from 'next/headers'
import { NextRequest, NextResponse } from 'next/server'

const DEFAULT_BACKEND_API_URL = 'http://localhost:3001'

function getBackendApiBaseUrl(): string {
  const baseUrl = process.env.NEXT_PUBLIC_API_URL || process.env.API_URL || DEFAULT_BACKEND_API_URL
  return baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl
}

export async function proxyBackendAdminRoute(
  request: NextRequest,
  path: string,
  init?: {
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
    body?: unknown
  },
) {
  const cookieStore = await cookies()
  const token = cookieStore.get('admin-token')?.value

  if (!token) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const headers = new Headers({
    Authorization: `Bearer ${token}`,
  })

  if (init?.body !== undefined) {
    headers.set('Content-Type', 'application/json')
  }

  const response = await fetch(
    `${getBackendApiBaseUrl()}${path}${request.nextUrl.search}`,
    {
      method: init?.method ?? request.method,
      headers,
      body: init?.body !== undefined ? JSON.stringify(init.body) : undefined,
      cache: 'no-store',
    },
  )

  const contentType = response.headers.get('content-type') ?? 'application/json'
  const body = await response.text()

  return new NextResponse(body, {
    status: response.status,
    headers: {
      'content-type': contentType,
    },
  })
}
