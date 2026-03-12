import { getAdminUser } from '@/lib/auth'
import { redirect } from 'next/navigation'
import { ValidationClient } from './validation-client'

export default async function ValidationPage() {
  const admin = await getAdminUser()
  if (!admin) redirect('/login')

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Item Validation</h1>
        <p className="text-muted-foreground">
          Detect overpowered, underpowered, or broken items and apply balance suggestions.
        </p>
      </div>
      <ValidationClient adminId={admin.id} />
    </div>
  )
}
