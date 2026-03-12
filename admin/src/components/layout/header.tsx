'use client'

import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { LogOut } from 'lucide-react'

export function Header({ email, role }: { email?: string | null; role?: string }) {
  const router = useRouter()

  async function handleLogout() {
    await fetch('/api/auth/logout', { method: 'POST' })
    router.push('/login')
    router.refresh()
  }

  return (
    <header className="sticky top-0 z-30 flex h-14 items-center justify-between border-b border-border bg-background/95 px-6 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div />
      <div className="flex items-center gap-4">
        <div className="text-right">
          <p className="text-sm font-medium">{email || 'Admin'}</p>
          <p className="text-xs text-muted-foreground capitalize">{role || 'admin'}</p>
        </div>
        <Button variant="ghost" size="icon" onClick={handleLogout}>
          <LogOut className="h-4 w-4" />
        </Button>
      </div>
    </header>
  )
}
