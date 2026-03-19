import { cn } from '@/lib/utils'

function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('animate-pulse rounded-md bg-muted', className)}
      {...props}
    />
  )
}

function TableSkeleton({ rows = 5, columns = 4 }: { rows?: number; columns?: number }) {
  return (
    <div className="space-y-4">
      {/* Search bar skeleton */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:gap-3">
        <Skeleton className="h-11 md:h-9 flex-1" />
        <Skeleton className="h-11 md:h-9 w-full sm:w-[200px]" />
      </div>

      {/* Table skeleton */}
      <div className="rounded-lg border border-border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                {Array.from({ length: columns }).map((_, i) => (
                  <th key={i} className="px-3 py-2.5">
                    <Skeleton className="h-3 w-20" />
                  </th>
                ))}
                <th className="px-3 py-2.5 w-[100px]">
                  <Skeleton className="h-3 w-12 ml-auto" />
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {Array.from({ length: rows }).map((_, rowIdx) => (
                <tr key={rowIdx}>
                  {Array.from({ length: columns }).map((_, colIdx) => (
                    <td key={colIdx} className="px-3 py-3">
                      <Skeleton className={cn('h-4', colIdx === 0 ? 'w-24' : 'w-16')} />
                    </td>
                  ))}
                  <td className="px-3 py-3 text-right">
                    <div className="flex justify-end gap-1">
                      <Skeleton className="h-8 w-8 rounded-md" />
                      <Skeleton className="h-8 w-8 rounded-md" />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination skeleton */}
      <div className="flex items-center justify-between">
        <Skeleton className="h-4 w-32" />
        <div className="flex gap-2">
          <Skeleton className="h-8 w-20" />
          <Skeleton className="h-8 w-16" />
        </div>
      </div>
    </div>
  )
}

function CardSkeleton() {
  return (
    <div className="rounded-lg border border-border p-6">
      <div className="flex items-center justify-between pb-2">
        <Skeleton className="h-4 w-24" />
        <Skeleton className="h-4 w-4 rounded" />
      </div>
      <Skeleton className="h-7 w-16 mt-2" />
    </div>
  )
}

function CardGridSkeleton({ count = 4 }: { count?: number }) {
  return (
    <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
      {Array.from({ length: count }).map((_, i) => (
        <CardSkeleton key={i} />
      ))}
    </div>
  )
}

export { Skeleton, TableSkeleton, CardSkeleton, CardGridSkeleton }
