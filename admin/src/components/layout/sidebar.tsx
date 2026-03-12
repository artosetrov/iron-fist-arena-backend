'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { navItems } from './nav-items'
import { Separator } from '@/components/ui/separator'

export function Sidebar() {
  const pathname = usePathname()

  return (
    <aside className="fixed left-0 top-0 z-40 flex h-screen w-64 flex-col border-r border-border bg-card">
      <div className="flex h-14 items-center px-6">
        <Link href="/" className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground font-bold text-sm">
            HB
          </div>
          <span className="font-semibold text-sm">Hexbound Admin</span>
        </Link>
      </div>
      <Separator />
      <nav className="flex-1 overflow-y-auto px-3 py-4">
        <ul className="space-y-1">
          {navItems.map((item) => {
            const isActive = item.href === '/'
              ? pathname === '/'
              : pathname.startsWith(item.href)
            const Icon = item.icon
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors',
                    isActive
                      ? 'bg-primary/10 text-primary font-medium'
                      : 'text-muted-foreground hover:bg-accent hover:text-foreground'
                  )}
                >
                  <Icon className="h-4 w-4" />
                  {item.label}
                </Link>
              </li>
            )
          })}
        </ul>
      </nav>
      <div className="border-t border-border p-4">
        <p className="text-xs text-muted-foreground">Hexbound</p>
        <p className="text-xs text-muted-foreground">LiveOps Dashboard v1.0</p>
      </div>
    </aside>
  )
}
