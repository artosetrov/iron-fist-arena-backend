'use server'

import { prisma } from '@/lib/prisma'
import { getAdminUser } from '@/lib/auth'
import { auditLog } from '@/lib/audit-log'

// ---------------------------------------------------------------------------
// Identifier / value sanitisation
// ---------------------------------------------------------------------------

const SAFE_NAME_RE = /^[a-zA-Z_][a-zA-Z0-9_]*$/

/** Max number of columns that can be provided in a single create/update. */
const MAX_COLUMNS = 50

/** Max string length for a single field value. */
const MAX_VALUE_LENGTH = 10_000

function sanitizeName(name: string): string {
  if (!SAFE_NAME_RE.test(name)) {
    throw new Error(
      `Invalid identifier: "${name}". Only alphanumeric characters and underscores are allowed.`
    )
  }
  return name
}

// ---------------------------------------------------------------------------
// Input data validation helpers
// ---------------------------------------------------------------------------

function validateRecordData(
  data: Record<string, unknown>
): { entries: [string, unknown][]; error?: never } | { error: string; entries?: never } {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return { error: 'Data must be a plain object' }
  }

  const entries = Object.entries(data)
  if (entries.length === 0) return { error: 'No data provided' }
  if (entries.length > MAX_COLUMNS) {
    return { error: `Too many columns (${entries.length}). Maximum is ${MAX_COLUMNS}.` }
  }

  for (const [key, value] of entries) {
    // Column name safety is enforced later via sanitizeName; do a quick
    // length check first so absurdly long names don't reach the regex.
    if (key.length > 128) {
      return { error: `Column name too long: "${key.slice(0, 32)}..."` }
    }

    // Validate value types — only primitives, null, and plain objects/arrays (for JSON) are allowed.
    if (value !== null && value !== undefined) {
      const t = typeof value
      if (t === 'function' || t === 'symbol' || t === 'bigint') {
        return { error: `Unsupported value type "${t}" for column "${key}"` }
      }
      if (t === 'string' && (value as string).length > MAX_VALUE_LENGTH) {
        return {
          error: `Value for column "${key}" is too long (${(value as string).length} chars). Maximum is ${MAX_VALUE_LENGTH}.`,
        }
      }
    }
  }

  return { entries }
}

// ---------------------------------------------------------------------------
// Value formatting for raw SQL
// ---------------------------------------------------------------------------

function formatValue(value: unknown): string {
  if (value === null || value === undefined) return 'NULL'
  if (typeof value === 'boolean') return value ? 'TRUE' : 'FALSE'
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new Error('Non-finite numbers are not allowed')
    return String(value)
  }
  if (typeof value === 'object') return `'${JSON.stringify(value).replace(/'/g, "''")}'::jsonb`
  return `'${String(value).replace(/'/g, "''")}'`
}

// ---------------------------------------------------------------------------
// Foreign-key constraint detection for delete safety
// ---------------------------------------------------------------------------

async function checkDependentRecords(
  safeTable: string,
  safePk: string,
  pkValue: string
): Promise<string | null> {
  // Find all foreign keys that reference this table.
  const refs = await prisma.$queryRawUnsafe<
    { source_table: string; source_column: string; target_column: string }[]
  >(
    `SELECT
       kcu.table_name   AS source_table,
       kcu.column_name  AS source_column,
       ccu.column_name  AS target_column
     FROM information_schema.referential_constraints rc
     JOIN information_schema.key_column_usage kcu
       ON rc.constraint_name = kcu.constraint_name
       AND kcu.constraint_schema = 'public'
     JOIN information_schema.constraint_column_usage ccu
       ON rc.unique_constraint_name = ccu.constraint_name
       AND ccu.constraint_schema = 'public'
     WHERE ccu.table_name = '${safeTable}'
       AND ccu.table_schema = 'public'`
  )

  if (refs.length === 0) return null

  const blocking: string[] = []
  for (const ref of refs) {
    const srcTable = sanitizeName(ref.source_table)
    const srcCol = sanitizeName(ref.source_column)
    const countResult = await prisma.$queryRawUnsafe<{ cnt: bigint }[]>(
      `SELECT COUNT(*) AS cnt FROM "${srcTable}" WHERE "${srcCol}" = ${formatValue(pkValue)}`
    )
    const cnt = Number(countResult[0]?.cnt ?? 0)
    if (cnt > 0) {
      blocking.push(`${ref.source_table} (${cnt} record${cnt > 1 ? 's' : ''})`)
    }
  }

  if (blocking.length === 0) return null

  return (
    `Cannot delete this record because it is referenced by: ${blocking.join(', ')}. ` +
    'Please remove or reassign the dependent records first.'
  )
}

// ---------------------------------------------------------------------------
// CRUD operations
// ---------------------------------------------------------------------------

export async function createRecord(
  tableName: string,
  data: Record<string, unknown>
): Promise<{ success: true } | { error: string }> {
  const admin = await getAdminUser()
  if (!admin) return { error: 'Unauthorized' }

  try {
    const safeTable = sanitizeName(tableName)

    const validation = validateRecordData(data)
    if (validation.error) return { error: validation.error }
    const entries = validation.entries!

    const columns = entries.map(([col]) => `"${sanitizeName(col)}"`).join(', ')
    const values = entries.map(([, val]) => formatValue(val)).join(', ')

    const sql = `INSERT INTO "${safeTable}" (${columns}) VALUES (${values})`
    await prisma.$executeRawUnsafe(sql)

    auditLog(admin, 'create', `${tableName}`, {
      columns: entries.map(([col]) => col),
    })

    return { success: true }
  } catch (err) {
    return { error: err instanceof Error ? err.message : 'Unknown error' }
  }
}

export async function updateRecord(
  tableName: string,
  pkColumn: string,
  pkValue: string,
  data: Record<string, unknown>
): Promise<{ success: true } | { error: string }> {
  const admin = await getAdminUser()
  if (!admin) return { error: 'Unauthorized' }

  try {
    const safeTable = sanitizeName(tableName)
    const safePk = sanitizeName(pkColumn)

    const validation = validateRecordData(data)
    if (validation.error) return { error: validation.error }
    const entries = validation.entries!

    const setClauses = entries
      .map(([col, val]) => `"${sanitizeName(col)}" = ${formatValue(val)}`)
      .join(', ')

    const sql = `UPDATE "${safeTable}" SET ${setClauses} WHERE "${safePk}" = ${formatValue(pkValue)}`
    await prisma.$executeRawUnsafe(sql)

    auditLog(admin, 'update', `${tableName}/${pkValue}`, {
      columns: entries.map(([col]) => col),
    })

    return { success: true }
  } catch (err) {
    return { error: err instanceof Error ? err.message : 'Unknown error' }
  }
}

export async function deleteRecord(
  tableName: string,
  pkColumn: string,
  pkValue: string
): Promise<{ success: true } | { error: string }> {
  const admin = await getAdminUser()
  if (!admin) return { error: 'Unauthorized' }

  try {
    const safeTable = sanitizeName(tableName)
    const safePk = sanitizeName(pkColumn)

    // Pre-flight check: look for dependent records that would cause an FK violation.
    const fkWarning = await checkDependentRecords(safeTable, safePk, pkValue)
    if (fkWarning) return { error: fkWarning }

    const sql = `DELETE FROM "${safeTable}" WHERE "${safePk}" = ${formatValue(pkValue)}`
    await prisma.$executeRawUnsafe(sql)

    auditLog(admin, 'delete', `${tableName}/${pkValue}`)

    return { success: true }
  } catch (err) {
    // Catch any FK error that slipped past the pre-flight check (e.g. race condition).
    if (err instanceof Error && err.message.includes('foreign key constraint')) {
      return {
        error:
          'Cannot delete this record because other records depend on it. ' +
          'Please remove or reassign the dependent records first.',
      }
    }
    return { error: err instanceof Error ? err.message : 'Unknown error' }
  }
}
