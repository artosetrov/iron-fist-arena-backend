'use client'

import { useState, useCallback } from 'react'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { cn } from '@/lib/utils'

interface JsonEditorProps {
  value: string
  onChange: (value: string) => void
  label?: string
  disabled?: boolean
}

export function JsonEditor({ value, onChange, label, disabled }: JsonEditorProps) {
  const [error, setError] = useState<string | null>(null)
  const [localValue, setLocalValue] = useState(value)

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      const raw = e.target.value
      setLocalValue(raw)
      onChange(raw)
    },
    [onChange]
  )

  const handleBlur = useCallback(() => {
    if (!localValue.trim()) {
      setError(null)
      return
    }
    try {
      const parsed = JSON.parse(localValue)
      const pretty = JSON.stringify(parsed, null, 2)
      setLocalValue(pretty)
      onChange(pretty)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Invalid JSON')
    }
  }, [localValue, onChange])

  return (
    <div className="space-y-1.5">
      {label && <Label>{label}</Label>}
      <Textarea
        value={localValue}
        onChange={handleChange}
        onBlur={handleBlur}
        disabled={disabled}
        rows={6}
        className={cn(
          'font-mono text-xs',
          error && 'border-destructive focus-visible:ring-destructive'
        )}
        placeholder='{ "key": "value" }'
      />
      {error && (
        <p className="text-xs text-destructive">{error}</p>
      )}
    </div>
  )
}
