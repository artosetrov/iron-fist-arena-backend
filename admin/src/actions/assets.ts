'use server'

import { getSupabaseAdmin } from '@/lib/supabase'
import { getAdminUser } from '@/lib/auth'

export async function listAssets(bucket: string, path?: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const supabase = getSupabaseAdmin()
  const { data, error } = await supabase.storage
    .from(bucket)
    .list(path || '', { limit: 100, sortBy: { column: 'name', order: 'asc' } })

  if (error) throw new Error(error.message)
  return data
}

export async function uploadAsset(bucket: string, path: string, formData: FormData) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const supabase = getSupabaseAdmin()
  const file = formData.get('file') as File
  if (!file) throw new Error('No file provided')

  const buffer = Buffer.from(await file.arrayBuffer())

  const { error } = await supabase.storage
    .from(bucket)
    .upload(path, buffer, {
      contentType: file.type,
      upsert: true,
    })

  if (error) throw new Error(error.message)

  const { data: urlData } = supabase.storage
    .from(bucket)
    .getPublicUrl(path)

  return { publicUrl: `${urlData.publicUrl}?v=${Date.now()}` }
}

export async function deleteAsset(bucket: string, path: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const supabase = getSupabaseAdmin()
  const { error } = await supabase.storage
    .from(bucket)
    .remove([path])

  if (error) throw new Error(error.message)
  return { success: true }
}

export async function getAssetUrl(bucket: string, path: string) {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  const supabase = getSupabaseAdmin()
  const { data } = supabase.storage
    .from(bucket)
    .getPublicUrl(path)

  return data.publicUrl
}
