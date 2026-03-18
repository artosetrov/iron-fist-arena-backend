'use client'

import { useState } from 'react'
import type { ColumnInfo } from '@/types/schema'
import { mapColumnToFieldType } from '@/types/schema'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { formatDate, truncate } from '@/lib/utils'
import {
  ChevronUp,
  ChevronDown,
  ChevronsUpDown,
  Pencil,
  Trash2,
  Search,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react'

interface DataTableProps {
  columns: ColumnInfo[]
  rows: Record<string, unknown>[]
  totalRows: number
  page: number
  pageSize: number
  onPageChange: (page: number) => void
  onSort: (column: string, dir: 'asc' | 'desc') => void
  onSearch: (search: string, column: string) => void
  searchValue: string
  searchColumn: string
  sortColumn: string
  sortDir: 'asc' | 'desc'
  onEdit: (row: Record<string, unknown>) => void
  onDelete: (pkValue: string) => void
  tableName: string
  primaryKeyColumn: string
}

function CellValue({ value, column }: { value: unknown; column: ColumnInfo }) {
  if (value === null || value === undefined) {
    return <span className="text-muted-foreground italic text-xs">null</span>
  }

  const fieldType = mapColumnToFieldType(column)

  switch (fieldType) {
    case 'uuid':
      return (
        <span className="font-mono text-xs text-muted-foreground" title={String(value)}>
          {String(value).slice(0, 8)}...
        </span>
      )

    case 'boolean':
      return (
        <Badge variant={value ? 'success' : 'destructive'}>
          {value ? 'true' : 'false'}
        </Badge>
      )

    case 'json': {
      const jsonStr = typeof value === 'string' ? value : JSON.stringify(value)
      return (
        <CollapsibleJson value={jsonStr} />
      )
    }

    case 'datetime':
      return (
        <span className="text-xs whitespace-nowrap">
          {formatDate(value as string | Date)}
        </span>
      )

    case 'enum':
      return <Badge variant="secondary">{String(value)}</Badge>

    default:
      return (
        <span className="text-sm" title={String(value)}>
          {truncate(String(value), 80)}
        </span>
      )
  }
}

function CollapsibleJson({ value }: { value: string }) {
  const [expanded, setExpanded] = useState(false)

  let displayValue: string
  try {
    const parsed = JSON.parse(value)
    displayValue = JSON.stringify(parsed, null, 2)
  } catch {
    displayValue = value
  }

  const preview = truncate(value.replace(/\s+/g, ' '), 50)

  if (displayValue.length <= 50) {
    return <span className="font-mono text-xs">{preview}</span>
  }

  return (
    <div>
      <button
        onClick={() => setExpanded(!expanded)}
        aria-expanded={expanded}
        aria-label={expanded ? 'Collapse JSON preview' : 'Expand JSON preview'}
        className="font-mono text-xs text-primary hover:underline cursor-pointer text-left"
      >
        {expanded ? 'Collapse' : preview}
      </button>
      {expanded && (
        <pre className="mt-1 max-h-48 overflow-auto rounded bg-muted p-2 font-mono text-xs whitespace-pre-wrap">
          {displayValue}
        </pre>
      )}
    </div>
  )
}

function SortIcon({
  column,
  sortColumn,
  sortDir,
}: {
  column: string
  sortColumn: string
  sortDir: 'asc' | 'desc'
}) {
  if (sortColumn !== column) {
    return <ChevronsUpDown className="ml-1 inline h-3 w-3 text-muted-foreground" />
  }
  return sortDir === 'asc' ? (
    <ChevronUp className="ml-1 inline h-3 w-3 text-primary" />
  ) : (
    <ChevronDown className="ml-1 inline h-3 w-3 text-primary" />
  )
}

export function DataTable({
  columns,
  rows,
  totalRows,
  page,
  pageSize,
  onPageChange,
  onSort,
  onSearch,
  searchValue,
  searchColumn,
  sortColumn,
  sortDir,
  onEdit,
  onDelete,
  primaryKeyColumn,
}: DataTableProps) {
  const totalPages = Math.max(1, Math.ceil(totalRows / pageSize))
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null)

  const textColumns = columns.filter((c) => {
    const ft = mapColumnToFieldType(c)
    return ft === 'text' || ft === 'uuid' || ft === 'enum'
  })

  const handleSortClick = (colName: string) => {
    if (sortColumn === colName) {
      onSort(colName, sortDir === 'asc' ? 'desc' : 'asc')
    } else {
      onSort(colName, 'asc')
    }
  }

  const handleSortKeyDown = (e: React.KeyboardEvent, colName: string) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      handleSortClick(colName)
    }
  }

  const getSortAriaLabel = (colName: string) => {
    if (sortColumn !== colName) return `Sort by ${colName}`
    return sortDir === 'asc'
      ? `Sort by ${colName}, currently ascending`
      : `Sort by ${colName}, currently descending`
  }

  const confirmDelete = () => {
    if (deleteTarget) {
      onDelete(deleteTarget)
      setDeleteTarget(null)
    }
  }

  return (
    <div className="space-y-4">
      {/* Search bar */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-2.5 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" aria-hidden="true" />
          <Input
            placeholder="Search..."
            value={searchValue}
            onChange={(e) => onSearch(e.target.value, searchColumn)}
            className="pl-9"
            aria-label="Search table records"
          />
        </div>
        <Select
          value={searchColumn}
          onValueChange={(val) => onSearch(searchValue, val)}
        >
          <SelectTrigger className="w-full sm:w-[200px]" aria-label="Select column to search">
            <SelectValue placeholder="Search column" />
          </SelectTrigger>
          <SelectContent>
            {textColumns.map((col) => (
              <SelectItem key={col.column_name} value={col.column_name}>
                {col.column_name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <div className="rounded-lg border border-border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm" role="grid">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                {columns.map((col) => (
                  <th
                    key={col.column_name}
                    role="columnheader"
                    aria-sort={
                      sortColumn === col.column_name
                        ? sortDir === 'asc' ? 'ascending' : 'descending'
                        : 'none'
                    }
                    aria-label={getSortAriaLabel(col.column_name)}
                    tabIndex={0}
                    className="px-3 py-2.5 text-left text-xs font-medium text-muted-foreground uppercase tracking-wider cursor-pointer hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-inset transition-colors whitespace-nowrap select-none"
                    onClick={() => handleSortClick(col.column_name)}
                    onKeyDown={(e) => handleSortKeyDown(e, col.column_name)}
                  >
                    {col.column_name}
                    {col.is_primary_key && (
                      <span className="ml-1 text-primary" aria-label="Primary Key">PK</span>
                    )}
                    {col.is_foreign_key && (
                      <span
                        className="ml-1 text-warning"
                        aria-label={`Foreign Key to ${col.foreign_table}.${col.foreign_column}`}
                      >
                        FK
                      </span>
                    )}
                    <SortIcon
                      column={col.column_name}
                      sortColumn={sortColumn}
                      sortDir={sortDir}
                    />
                  </th>
                ))}
                <th className="px-3 py-2.5 text-right text-xs font-medium text-muted-foreground uppercase tracking-wider w-[100px]">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {rows.length === 0 ? (
                <tr>
                  <td
                    colSpan={columns.length + 1}
                    className="px-3 py-12 text-center text-muted-foreground"
                  >
                    No records found.
                  </td>
                </tr>
              ) : (
                rows.map((row, idx) => (
                  <tr
                    key={String(row[primaryKeyColumn] ?? idx)}
                    className="hover:bg-muted/30 transition-colors"
                  >
                    {columns.map((col) => (
                      <td
                        key={col.column_name}
                        className="px-3 py-2 max-w-[300px] truncate"
                      >
                        <CellValue value={row[col.column_name]} column={col} />
                      </td>
                    ))}
                    <td className="px-3 py-2 text-right whitespace-nowrap">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => onEdit(row)}
                        aria-label={`Edit record ${String(row[primaryKeyColumn] ?? idx)}`}
                        className="h-9 w-9 md:h-9 md:w-9 min-h-[44px] min-w-[44px] md:min-h-0 md:min-w-0"
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => setDeleteTarget(String(row[primaryKeyColumn]))}
                        aria-label={`Delete record ${String(row[primaryKeyColumn] ?? idx)}`}
                        className="text-destructive hover:text-destructive h-9 w-9 md:h-9 md:w-9 min-h-[44px] min-w-[44px] md:min-h-0 md:min-w-0"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-xs sm:text-sm text-muted-foreground text-center sm:text-left" aria-live="polite">
          Page {page} of {totalPages} &middot; {totalRows} rows
        </p>
        <div className="flex items-center justify-center gap-2" role="navigation" aria-label="Table pagination">
          <Button
            variant="outline"
            size="sm"
            disabled={page <= 1}
            onClick={() => onPageChange(page - 1)}
            aria-label="Go to previous page"
            className="min-h-[44px] md:min-h-0"
          >
            <ChevronLeft className="mr-1 h-4 w-4" />
            <span className="hidden sm:inline">Previous</span>
          </Button>
          <span className="text-sm text-muted-foreground sm:hidden" aria-hidden="true">{page}/{totalPages}</span>
          <Button
            variant="outline"
            size="sm"
            disabled={page >= totalPages}
            onClick={() => onPageChange(page + 1)}
            aria-label="Go to next page"
            className="min-h-[44px] md:min-h-0"
          >
            <span className="hidden sm:inline">Next</span>
            <ChevronRight className="ml-1 h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Delete Confirmation */}
      <AlertDialog open={deleteTarget !== null} onOpenChange={(open) => !open && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Record</AlertDialogTitle>
            <AlertDialogDescription>
              Are you sure you want to delete record <strong className="font-mono">{deleteTarget}</strong>? This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDelete}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
