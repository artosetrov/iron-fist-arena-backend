'use server'

import { getTables, getTableInfo, getTableRows } from '@/lib/schema-introspection'
import { getAdminUser } from '@/lib/auth'
import type { TableInfo } from '@/types/schema'

export async function getTablesList(): Promise<string[]> {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return getTables()
}

export async function getTableDetails(tableName: string): Promise<TableInfo> {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return getTableInfo(tableName)
}

export async function getTableData(
  tableName: string,
  options: {
    page?: number
    pageSize?: number
    search?: string
    searchColumn?: string
    orderBy?: string
    orderDir?: 'asc' | 'desc'
  } = {}
): Promise<{
  rows: Record<string, unknown>[]
  totalRows: number
  page: number
  pageSize: number
}> {
  const admin = await getAdminUser()
  if (!admin) throw new Error('Unauthorized')
  return getTableRows(tableName, options)
}
