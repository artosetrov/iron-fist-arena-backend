import Link from 'next/link'
import { getTablesList, getTableDetails } from '@/actions/schema'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Database, ArrowRight } from 'lucide-react'

export default async function TablesPage() {
  const tableNames = await getTablesList()

  const tables = await Promise.all(
    tableNames.map(async (name) => {
      const info = await getTableDetails(name)
      return info
    })
  )

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Database Tables</h1>
        <p className="text-muted-foreground">
          Browse and manage all {tables.length} tables in the database.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {tables.map((table) => (
          <Link
            key={table.table_name}
            href={`/tables/${table.table_name}`}
          >
            <Card className="group cursor-pointer transition-colors hover:border-primary/50">
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Database className="h-4 w-4 text-primary" />
                    <CardTitle className="text-sm font-medium">
                      {table.table_name}
                    </CardTitle>
                  </div>
                  <ArrowRight className="h-4 w-4 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" />
                </div>
              </CardHeader>
              <CardContent>
                <div className="flex items-center gap-3">
                  <Badge variant="secondary">
                    {table.row_count.toLocaleString()} rows
                  </Badge>
                  <Badge variant="outline">
                    {table.columns.length} columns
                  </Badge>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}
