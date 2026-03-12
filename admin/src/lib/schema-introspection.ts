import { prisma } from './prisma'
import type { TableInfo, ColumnInfo } from '@/types/schema'

const SYSTEM_TABLES = ['_prisma_migrations', 'schema_migrations']
const SAFE_NAME_RE = /^[a-zA-Z_][a-zA-Z0-9_]*$/

function sanitizeName(name: string): string {
  if (!SAFE_NAME_RE.test(name)) {
    throw new Error(`Invalid identifier: "${name}". Only alphanumeric characters and underscores are allowed.`)
  }
  return name
}

export async function getTables(): Promise<string[]> {
  const result = await prisma.$queryRaw<{ table_name: string }[]>`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
    ORDER BY table_name
  `
  return result
    .map(r => r.table_name)
    .filter(t => !SYSTEM_TABLES.includes(t))
}

export async function getTableInfo(tableName: string): Promise<TableInfo> {
  const safeTable = sanitizeName(tableName)
  const columns = await getColumns(safeTable)
  const countResult = await prisma.$queryRawUnsafe<{ count: bigint }[]>(
    `SELECT COUNT(*) as count FROM "${safeTable}"`
  )
  const row_count = Number(countResult[0]?.count || 0)
  return { table_name: tableName, columns, row_count }
}

async function getColumns(tableName: string): Promise<ColumnInfo[]> {
  const cols = await prisma.$queryRaw<{
    column_name: string
    data_type: string
    udt_name: string
    is_nullable: string
    column_default: string | null
    character_maximum_length: number | null
  }[]>`
    SELECT column_name, data_type, udt_name, is_nullable, column_default, character_maximum_length
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = ${tableName}
    ORDER BY ordinal_position
  `

  const pks = await prisma.$queryRaw<{ column_name: string }[]>`
    SELECT kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_schema = 'public' AND tc.table_name = ${tableName} AND tc.constraint_type = 'PRIMARY KEY'
  `
  const pkSet = new Set(pks.map(p => p.column_name))

  const fks = await prisma.$queryRaw<{
    column_name: string
    foreign_table_name: string
    foreign_column_name: string
  }[]>`
    SELECT
      kcu.column_name,
      ccu.table_name AS foreign_table_name,
      ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
    WHERE tc.table_schema = 'public' AND tc.table_name = ${tableName} AND tc.constraint_type = 'FOREIGN KEY'
  `
  const fkMap = new Map(fks.map(f => [f.column_name, { table: f.foreign_table_name, column: f.foreign_column_name }]))

  const enumCols = cols.filter(c => c.data_type === 'USER-DEFINED')
  const enumMap = new Map<string, string[]>()
  for (const ec of enumCols) {
    const vals = await prisma.$queryRaw<{ enumlabel: string }[]>`
      SELECT e.enumlabel
      FROM pg_type t JOIN pg_enum e ON t.oid = e.enumtypid
      WHERE t.typname = ${ec.udt_name}
      ORDER BY e.enumsortorder
    `
    enumMap.set(ec.column_name, vals.map(v => v.enumlabel))
  }

  return cols.map(c => ({
    column_name: c.column_name,
    data_type: c.data_type,
    udt_name: c.udt_name,
    is_nullable: c.is_nullable as 'YES' | 'NO',
    column_default: c.column_default,
    character_maximum_length: c.character_maximum_length,
    is_primary_key: pkSet.has(c.column_name),
    is_foreign_key: fkMap.has(c.column_name),
    foreign_table: fkMap.get(c.column_name)?.table || null,
    foreign_column: fkMap.get(c.column_name)?.column || null,
    enum_values: enumMap.get(c.column_name) || null,
  }))
}

export async function getTableRows(
  tableName: string,
  options: {
    page?: number
    pageSize?: number
    search?: string
    searchColumn?: string
    orderBy?: string
    orderDir?: 'asc' | 'desc'
  } = {}
) {
  const { page = 1, pageSize = 20, search, searchColumn, orderBy, orderDir = 'desc' } = options
  const offset = (page - 1) * pageSize
  const safeTable = sanitizeName(tableName)
  const safePageSize = Math.min(Math.max(1, Math.floor(pageSize)), 100)
  const safeOffset = Math.max(0, Math.floor(offset))
  const safeOrderDir = orderDir === 'asc' ? 'ASC' : 'DESC'

  let whereClause = ''
  const queryParams: unknown[] = []
  if (search && searchColumn) {
    const safeSearchCol = sanitizeName(searchColumn)
    queryParams.push(`%${search}%`)
    whereClause = `WHERE "${safeSearchCol}"::text ILIKE $1`
  }

  const orderClause = orderBy
    ? `ORDER BY "${sanitizeName(orderBy)}" ${safeOrderDir}`
    : `ORDER BY 1 DESC`

  const rows = queryParams.length > 0
    ? await prisma.$queryRawUnsafe(
        `SELECT * FROM "${safeTable}" ${whereClause} ${orderClause} LIMIT ${safePageSize} OFFSET ${safeOffset}`,
        ...queryParams
      )
    : await prisma.$queryRawUnsafe(
        `SELECT * FROM "${safeTable}" ${orderClause} LIMIT ${safePageSize} OFFSET ${safeOffset}`
      )

  const countResult = queryParams.length > 0
    ? await prisma.$queryRawUnsafe<{ count: bigint }[]>(
        `SELECT COUNT(*) as count FROM "${safeTable}" ${whereClause}`,
        ...queryParams
      )
    : await prisma.$queryRawUnsafe<{ count: bigint }[]>(
        `SELECT COUNT(*) as count FROM "${safeTable}"`
      )
  const totalRows = Number(countResult[0]?.count || 0)

  return { rows: rows as Record<string, unknown>[], totalRows, page, pageSize }
}
