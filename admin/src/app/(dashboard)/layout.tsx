import { redirect } from 'next/navigation'
import { getAdminUser } from '@/lib/auth'
import { Sidebar } from '@/components/layout/sidebar'
import { Header } from '@/components/layout/header'

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const admin = await getAdminUser()

  if (!admin) {
    redirect('/login')
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex flex-1 flex-col pl-64">
        <Header email={admin.email} role={admin.role} />
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
