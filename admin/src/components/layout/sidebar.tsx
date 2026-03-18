'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { navGroups } from './nav-items'
import type { NavGroup, NavItem } from './nav-items'
import { Separator } from '@/components/ui/separator'
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet'
import { Menu, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { useState } from 'react'

function NavLink({ item, onNavigate }: { item: NavItem; onNavigate?: () => void }) {
  const pathname = usePathname()
  const isActive = item.href === '/'
    ? pathname === '/'
    : pathname.startsWith(item.href)
  const Icon = item.icon

  return (
    <li>
      <Link
        href={item.href}
        onClick={onNavigate}
        className={cn(
          'flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors min-h-[36px]',
          isActive
            ? 'bg-primary/10 text-primary font-medium'
            : 'text-muted-foreground hover:bg-accent hover:text-foreground'
        )}
      >
        <Icon className="h-4 w-4 shrink-0" />
        {item.label}
      </Link>
    </li>
  )
}

function NavSection({ group, onNavigate, defaultOpen }: { group: NavGroup; onNavigate?: () => void; defaultOpen: boolean }) {
  const pathname = usePathname()
  const hasActiveChild = group.items.some((item) =>
    item.href === '/' ? pathname === '/' : pathname.startsWith(item.href)
  )
  const [open, setOpen] = useState(defaultOpen || hasActiveChild)

  return (
    <div>
      <button
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        className="flex w-full items-center justify-between px-3 py-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground/70 hover:text-muted-foreground transition-colors"
      >
        {group.label}
        <ChevronRight
          className={cn(
            'h-3 w-3 transition-transform duration-200',
            open && 'rotate-90'
          )}
        />
      </button>
      {open && (
        <ul className="mt-0.5 space-y-0.5">
          {group.items.map((item) => (
            <NavLink key={item.href} item={item} onNavigate={onNavigate} />
          ))}
        </ul>
      )}
    </div>
  )
}

function SidebarNav({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <nav className="flex-1 overflow-y-auto px-3 py-3" aria-label="Main navigation">
      <div className="space-y-3">
        {navGroups.map((group, idx) => (
          <NavSection
            key={group.label}
            group={group}
            onNavigate={onNavigate}
            defaultOpen={idx === 0} /* Overview always open by default */
          />
        ))}
      </div>
    </nav>
  )
}

function SidebarHeader() {
  return (
    <>
      <div className="flex h-14 items-center px-6">
        <Link href="/" className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground font-bold text-sm">
            HB
          </div>
          <span className="font-semibold text-sm">Hexbound Admin</span>
        </Link>
      </div>
      <Separator />
    </>
  )
}

function SidebarFooter() {
  return (
    <div className="border-t border-border p-4">
      <p className="text-xs text-muted-foreground">Hexbound</p>
      <p className="text-xs text-muted-foreground">LiveOps Dashboard v1.0</p>
    </div>
  )
}

/** Desktop sidebar — hidden on mobile */
export function Sidebar() {
  return (
    <aside className="fixed left-0 top-0 z-40 hidden h-screen w-64 flex-col border-r border-border bg-card md:flex">
      <SidebarHeader />
      <SidebarNav />
      <SidebarFooter />
    </aside>
  )
}

/** Mobile sidebar — hamburger that opens a Sheet drawer */
export function MobileSidebar() {
  const [open, setOpen] = useState(false)

  return (
    <Sheet open={open} onOpenChange={setOpen}>
      <SheetTrigger asChild>
        <Button variant="ghost" size="icon" className="md:hidden min-h-[44px] min-w-[44px]" aria-label="Open navigation menu">
          <Menu className="h-5 w-5" />
        </Button>
      </SheetTrigger>
      <SheetContent>
        <SidebarHeader />
        <SidebarNav onNavigate={() => setOpen(false)} />
        <SidebarFooter />
      </SheetContent>
    </Sheet>
  )
}
