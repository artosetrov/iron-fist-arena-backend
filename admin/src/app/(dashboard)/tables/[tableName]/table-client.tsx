'use client'

import { useState, useCallback, useEffect, useTransition } from 'react'
import { useRouter, useSearchParams, usePathname } from 'next/navigation'
import type { ColumnInfo } from '@/types/schema'
import { DataTable } from '@/components/data-table/data-table'
import { DynamicForm } from '@/components/forms/dynamic-form'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog'
import { createRecord, updateRecord, deleteRecord } from '@/actions/crud'
import { Plus, AlertTriangle } from 'lucide-react'

interface TableClientProps {
  tableName: string
  columns: ColumnInfo[]
  rows: Record<string, unknown>[]
  totalRows: number
  page: number
  pageSize: number
  primaryKeyColumn: string
  searchValue: string
  searchColumn: string
  sortColumn: string
  sortDir: 'asc' | 'desc'
}

export function TableClient({
  tableName,
  columns,
  rows,
  totalRows,
  page,
  pageSize,
  primaryKeyColumn,
  searchValue: initialSearch,
  searchColumn: initialSearchCol,
  sortColumn: initialSortCol,
  sortDir: initialSortDir,
}: TableClientProps) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [isPending, startTransition] = useTransition()

  // Modal state
  const [editingRow, setEditingRow] = useState<Record<string, unknown> | null>(null)
  const [creatingNew, setCreatingNew] = useState(false)
  const [deletingPk, setDeletingPk] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [isMutating, setIsMutating] = useState(false)

  // Search debounce state
  const [searchInput, setSearchInput] = useState(initialSearch)
  const [currentSearchCol, setCurrentSearchCol] = useState(initialSearchCol)

  // Debounced search
  useEffect(() => {
    const timer = setTimeout(() => {
      if (searchInput !== initialSearch || currentSearchCol !== initialSearchCol) {
        updateParams({ search: searchInput, searchColumn: currentSearchCol, page: '1' })
      }
    }, 400)
    return () => clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchInput, currentSearchCol])

  const updateParams = useCallback(
    (updates: Record<string, string>) => {
      const params = new URLSearchParams(searchParams.toString())
      for (const [key, value] of Object.entries(updates)) {
        if (value) {
          params.set(key, value)
        } else {
          params.delete(key)
        }
      }
      startTransition(() => {
        router.push(`${pathname}?${params.toString()}`)
      })
    },
    [searchParams, pathname, router]
  )

  const handlePageChange = useCallback(
    (newPage: number) => {
      updateParams({ page: String(newPage) })
    },
    [updateParams]
  )

  const handleSort = useCallback(
    (column: string, dir: 'asc' | 'desc') => {
      updateParams({ orderBy: column, orderDir: dir, page: '1' })
    },
    [updateParams]
  )

  const handleSearch = useCallback(
    (search: string, column: string) => {
      setSearchInput(search)
      setCurrentSearchCol(column)
    },
    []
  )

  const handleCreate = useCallback(
    async (data: Record<string, unknown>) => {
      setIsMutating(true)
      setError(null)
      const result = await createRecord(tableName, data)
      setIsMutating(false)

      if ('error' in result) {
        setError(result.error)
        return
      }

      setCreatingNew(false)
      startTransition(() => {
        router.refresh()
      })
    },
    [tableName, router]
  )

  const handleUpdate = useCallback(
    async (data: Record<string, unknown>) => {
      if (!editingRow) return
      setIsMutating(true)
      setError(null)

      const pkValue = String(editingRow[primaryKeyColumn])
      const result = await updateRecord(tableName, primaryKeyColumn, pkValue, data)
      setIsMutating(false)

      if ('error' in result) {
        setError(result.error)
        return
      }

      setEditingRow(null)
      startTransition(() => {
        router.refresh()
      })
    },
    [editingRow, tableName, primaryKeyColumn, router]
  )

  const handleDelete = useCallback(async () => {
    if (!deletingPk) return
    setIsMutating(true)
    setError(null)

    const result = await deleteRecord(tableName, primaryKeyColumn, deletingPk)
    setIsMutating(false)

    if ('error' in result) {
      setError(result.error)
      return
    }

    setDeletingPk(null)
    startTransition(() => {
      router.refresh()
    })
  }, [deletingPk, tableName, primaryKeyColumn, router])

  return (
    <div className="space-y-4">
      {/* Header actions */}
      <div className="flex items-center justify-between">
        <div />
        <Button onClick={() => { setCreatingNew(true); setError(null) }}>
          <Plus className="mr-2 h-4 w-4" />
          New Record
        </Button>
      </div>

      {/* Data table */}
      <div className={isPending ? 'opacity-60 pointer-events-none transition-opacity' : ''}>
        <DataTable
          columns={columns}
          rows={rows}
          totalRows={totalRows}
          page={page}
          pageSize={pageSize}
          onPageChange={handlePageChange}
          onSort={handleSort}
          onSearch={handleSearch}
          searchValue={searchInput}
          searchColumn={currentSearchCol}
          sortColumn={initialSortCol}
          sortDir={initialSortDir}
          onEdit={(row) => { setEditingRow(row); setError(null) }}
          onDelete={(pkVal) => { setDeletingPk(pkVal); setError(null) }}
          tableName={tableName}
          primaryKeyColumn={primaryKeyColumn}
        />
      </div>

      {/* Create dialog */}
      <Dialog open={creatingNew} onOpenChange={setCreatingNew}>
        <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Create New Record</DialogTitle>
            <DialogDescription>
              Add a new row to the {tableName} table.
            </DialogDescription>
          </DialogHeader>
          {error && (
            <div className="rounded-md border border-destructive/50 bg-destructive/10 px-4 py-3 text-sm text-destructive">
              {error}
            </div>
          )}
          <DynamicForm
            columns={columns}
            onSubmit={handleCreate}
            isEdit={false}
            isLoading={isMutating}
          />
        </DialogContent>
      </Dialog>

      {/* Edit dialog */}
      <Dialog
        open={editingRow !== null}
        onOpenChange={(open) => { if (!open) setEditingRow(null) }}
      >
        <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit Record</DialogTitle>
            <DialogDescription>
              Update the row in {tableName}.
            </DialogDescription>
          </DialogHeader>
          {error && (
            <div className="rounded-md border border-destructive/50 bg-destructive/10 px-4 py-3 text-sm text-destructive">
              {error}
            </div>
          )}
          {editingRow && (
            <DynamicForm
              key={String(editingRow[primaryKeyColumn])}
              columns={columns}
              initialData={editingRow}
              onSubmit={handleUpdate}
              isEdit={true}
              isLoading={isMutating}
            />
          )}
        </DialogContent>
      </Dialog>

      {/* Delete confirmation dialog */}
      <Dialog
        open={deletingPk !== null}
        onOpenChange={(open) => { if (!open) setDeletingPk(null) }}
      >
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-destructive" />
              Confirm Deletion
            </DialogTitle>
            <DialogDescription>
              Are you sure you want to delete the record with {primaryKeyColumn} = &quot;{deletingPk}&quot;? This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          {error && (
            <div className="rounded-md border border-destructive/50 bg-destructive/10 px-4 py-3 text-sm text-destructive">
              {error}
            </div>
          )}
          <div className="flex justify-end gap-3 pt-2">
            <Button
              variant="outline"
              onClick={() => setDeletingPk(null)}
              disabled={isMutating}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={isMutating}
            >
              {isMutating ? 'Deleting...' : 'Delete'}
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
