'use client'

import Link from 'next/link'
import type { LucideIcon } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'

interface QuickLink {
  label: string
  href: string
  icon: LucideIcon
  description: string
}

export function QuickLinks({ links }: { links: QuickLink[] }) {
  return (
    <div className="grid gap-3 grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      {links.map(link => {
        const Icon = link.icon
        return (
          <Link key={link.href} href={link.href}>
            <Card className="hover:bg-zinc-800/50 transition-colors h-full">
              <CardContent className="py-3 px-4 flex items-start gap-3">
                <Icon className="h-4 w-4 mt-0.5 text-muted-foreground flex-shrink-0" />
                <div>
                  <p className="text-sm font-medium">{link.label}</p>
                  <p className="text-xs text-muted-foreground">{link.description}</p>
                </div>
              </CardContent>
            </Card>
          </Link>
        )
      })}
    </div>
  )
}
