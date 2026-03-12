import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getTableDetails, getTableData } from '@/actions/schema'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { ArrowLeft } from 'lucide-react'
import { TableClient } from './table-client'
import { mapColumnToFieldType } from '@/types/schema'

interface PageProps {
  params: Promise<{ tableName: string }>
  searchParams: Promise<{
    page?: string
    search?: string
    searchColumn?: string
    orderBy?: string
    orderDir?: string
  }>
}

export default async function TablePage({ params, searchParams }: PageProps) {
  const { tableName } = await params
  const sp = await searchParams

  let tableInfo
  try {
    tableInfo = await getTableDetails(tableName)
  } catch {
    notFound()
  }

  const columns = tableInfo.columns
  const primaryKeyCol = columns.find((c) => c.is_primary_key)

  if (!primaryKeyCol) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold">{tableName}</h1>
        <p className="text-destructive">
          This table has no primary key and cannot be managed through CRUD operations.
        </p>
      </div>
    )
  }

  // Resolve search column: use provided, or fall back to first text/uuid column, or PK
  const textColumns = columns.filter((c) => {
    const ft = mapColumnToFieldType(c)
    return ft === 'text' || ft === 'uuid' || ft === 'enum'
  })
  const defaultSearchCol = textColumns[0]?.column_name || primaryKeyCol.column_name

  const page = Math.max(1, parseInt(sp.page || '1', 10) || 1)
  const search = sp.search || ''
  const searchColumn = sp.searchColumn || defaultSearchCol
  const orderBy = sp.orderBy || ''
  const orderDir = (sp.orderDir === 'asc' ? 'asc' : 'desc') as 'asc' | 'desc'
  const pageSize = 20

  const data = await getTableData(tableName, {
    page,
    pageSize,
    search: search || undefined,
    searchColumn: search ? searchColumn : undefined,
    orderBy: orderBy || undefined,
    orderDir,
  })

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" asChild>
          <Link href="/tables">
            <ArrowLeft className="h-4 w-4" />
          </Link>
        </Button>
        <div>
          <h1 className="text-2xl font-bold tracking-tight">{tableName}</h1>
          <div className="flex items-center gap-2 mt-1">
            <Badge variant="secondary">
              {tableInfo.row_count.toLocaleString()} rows
            </Badge>
            <Badge variant="outline">
              {columns.length} columns
            </Badge>
            <Badge variant="outline">
              PK: {primaryKeyCol.column_name}
            </Badge>
          </div>
        </div>
      </div>

      {/* Client-side interactive table */}
      <TableClient
        tableName={tableName}
        columns={columns}
        rows={data.rows}
        totalRows={data.totalRows}
        page={data.page}
        pageSize={pageSize}
        primaryKeyColumn={primaryKeyCol.column_name}
        searchValue={search}
        searchColumn={searchColumn}
        sortColumn={orderBy}
        sortDir={orderDir}
      />
    </div>
  )
}
