import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

/**
 * GET /api/assets/manifest
 *
 * Returns a manifest of all game assets with their URLs and metadata.
 * The iOS client uses this to:
 *   1. Check which assets have changed since last sync
 *   2. Download only the delta into disk cache
 *   3. Serve cached assets instantly (stale-while-revalidate)
 *
 * No auth required — asset URLs are public anyway.
 * Cached for 60 seconds on CDN to avoid hammering Supabase Storage API.
 */

interface AssetEntry {
  key: string
  url: string
  size: number
  category: 'items' | 'skins' | 'bosses'
  updatedAt: string | null
}

// In-memory cache to avoid listing buckets on every request
let manifestCache: { data: AssetEntry[]; version: string; timestamp: number } | null = null
const CACHE_TTL_MS = 60_000 // 60 seconds

function getSupabase() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  )
}

async function listBucketAssets(
  supabase: ReturnType<typeof getSupabase>,
  bucket: string,
  prefix: string,
  category: AssetEntry['category']
): Promise<AssetEntry[]> {
  const { data, error } = await supabase.storage
    .from(bucket)
    .list(prefix || undefined, { limit: 1000, sortBy: { column: 'name', order: 'asc' } })

  if (error || !data) {
    console.error(`Failed to list ${bucket}/${prefix}:`, error?.message)
    return []
  }

  const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
  const entries: AssetEntry[] = []

  for (const item of data) {
    // Skip folders and non-image files
    const mimetype = item.metadata?.mimetype || ''
    if (!item.id || !mimetype.startsWith('image/')) continue

    const key = item.name.replace(/\.[^.]+$/, '') // Remove extension
    const path = prefix ? `${prefix}/${item.name}` : item.name
    const url = `${baseUrl}/storage/v1/object/public/${bucket}/${path}`

    entries.push({
      key,
      url,
      size: item.metadata?.size || 0,
      category,
      updatedAt: item.updated_at || item.created_at || null,
    })
  }

  return entries
}

export async function GET() {
  try {
    const now = Date.now()

    // Return cached manifest if fresh
    if (manifestCache && (now - manifestCache.timestamp) < CACHE_TTL_MS) {
      return NextResponse.json(
        {
          version: manifestCache.version,
          totalAssets: manifestCache.data.length,
          assets: manifestCache.data,
          cached: true,
        },
        {
          headers: {
            'Cache-Control': 'public, max-age=60, stale-while-revalidate=300',
          },
        }
      )
    }

    const supabase = getSupabase()

    // Fetch all categories in parallel
    const [items, skins, bosses] = await Promise.all([
      listBucketAssets(supabase, 'assets', 'items', 'items'),
      listBucketAssets(supabase, 'assets', 'appearances', 'skins'),
      listBucketAssets(supabase, 'dungeon-assets', '', 'bosses'),
    ])

    const allAssets = [...items, ...skins, ...bosses]
    const version = String(now)

    // Update cache
    manifestCache = { data: allAssets, version, timestamp: now }

    return NextResponse.json(
      {
        version,
        totalAssets: allAssets.length,
        assets: allAssets,
        cached: false,
      },
      {
        headers: {
          'Cache-Control': 'public, max-age=60, stale-while-revalidate=300',
        },
      }
    )
  } catch (error) {
    console.error('Asset manifest error:', error)
    return NextResponse.json(
      { message: 'Failed to generate asset manifest' },
      { status: 500 }
    )
  }
}
