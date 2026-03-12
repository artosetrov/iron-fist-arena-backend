import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: Date | string | null): string {
  if (!date) return '—'
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric', month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

export function truncate(str: string, len = 50): string {
  if (!str) return ''
  return str.length > len ? str.slice(0, len) + '…' : str
}

export function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1).replace(/_/g, ' ')
}
