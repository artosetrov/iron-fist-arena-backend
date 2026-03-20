'use client'

import { useState, useEffect, useRef, useCallback } from 'react'
import { Button } from '@/components/ui/button'
import { Save, RotateCcw, MapPin } from 'lucide-react'

// Default dungeon positions (matches iOS DungeonMapBuildingConfig.swift)
const DEFAULT_DUNGEONS = [
  { id: 'training_camp', label: 'Training Camp', minLevel: 1, x: 0.08, y: 0.70, size: 0.18, color: '#E68C33' },
  { id: 'desecrated_catacombs', label: 'Catacombs', minLevel: 10, x: 0.20, y: 0.45, size: 0.18, color: '#8040B0' },
  { id: 'volcanic_forge', label: 'Volcanic Forge', minLevel: 20, x: 0.32, y: 0.65, size: 0.18, color: '#FF6626' },
  { id: 'fungal_grotto', label: 'Fungal Grotto', minLevel: 30, x: 0.42, y: 0.35, size: 0.18, color: '#4CAF50' },
  { id: 'scorched_mines', label: 'Scorched Mines', minLevel: 40, x: 0.52, y: 0.60, size: 0.18, color: '#E65100' },
  { id: 'frozen_abyss', label: 'Frozen Abyss', minLevel: 50, x: 0.62, y: 0.30, size: 0.18, color: '#42A5F5' },
  { id: 'realm_of_light', label: 'Realm of Light', minLevel: 60, x: 0.72, y: 0.55, size: 0.18, color: '#FFD54F' },
  { id: 'shadow_depths', label: 'Shadow Depths', minLevel: 70, x: 0.80, y: 0.40, size: 0.18, color: '#424242' },
  { id: 'clockwork_citadel', label: 'Clockwork Citadel', minLevel: 80, x: 0.88, y: 0.60, size: 0.18, color: '#78909C' },
  { id: 'infernal_throne', label: 'Infernal Throne', minLevel: 90, x: 0.94, y: 0.35, size: 0.20, color: '#B71C1C' },
]

type DungeonNode = {
  id: string
  label: string
  minLevel: number
  x: number
  y: number
  size: number
  color: string
}

export default function DungeonMapEditorClient() {
  const [dungeons, setDungeons] = useState<DungeonNode[]>(DEFAULT_DUNGEONS)
  const [selected, setSelected] = useState<string | null>(null)
  const [dragging, setDragging] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [toast, setToast] = useState<string | null>(null)
  const [loaded, setLoaded] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)
  const imageRef = useRef<HTMLImageElement>(null)

  // Load saved layout from server
  useEffect(() => {
    fetch('/api/dungeon-map-layout')
      .then(res => res.json())
      .then(data => {
        if (data.layout && typeof data.layout === 'object') {
          setDungeons(prev =>
            prev.map(d => {
              const override = data.layout[d.id]
              if (override) {
                return {
                  ...d,
                  x: override.x ?? d.x,
                  y: override.y ?? d.y,
                  size: override.size ?? d.size,
                }
              }
              return d
            })
          )
        }
        setLoaded(true)
      })
      .catch(() => setLoaded(true))
  }, [])

  // Handle mouse move for dragging
  const handleMouseMove = useCallback(
    (e: MouseEvent) => {
      if (!dragging || !imageRef.current) return
      const rect = imageRef.current.getBoundingClientRect()
      const relX = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width))
      const relY = Math.max(0, Math.min(1, (e.clientY - rect.top) / rect.height))
      setDungeons(prev =>
        prev.map(d => (d.id === dragging ? { ...d, x: relX, y: relY } : d))
      )
    },
    [dragging]
  )

  const handleMouseUp = useCallback(() => {
    setDragging(null)
  }, [])

  useEffect(() => {
    if (dragging) {
      window.addEventListener('mousemove', handleMouseMove)
      window.addEventListener('mouseup', handleMouseUp)
      return () => {
        window.removeEventListener('mousemove', handleMouseMove)
        window.removeEventListener('mouseup', handleMouseUp)
      }
    }
  }, [dragging, handleMouseMove, handleMouseUp])

  const handleSave = async () => {
    setSaving(true)
    try {
      const layout: Record<string, { x: number; y: number; size: number }> = {}
      for (const d of dungeons) {
        layout[d.id] = { x: +d.x.toFixed(3), y: +d.y.toFixed(3), size: +d.size.toFixed(3) }
      }
      const res = await fetch('/api/dungeon-map-layout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ layout }),
      })
      if (res.ok) {
        showToast('Saved successfully!')
      } else {
        showToast('Save failed')
      }
    } catch {
      showToast('Save failed')
    } finally {
      setSaving(false)
    }
  }

  const handleReset = () => {
    setDungeons(DEFAULT_DUNGEONS)
    setSelected(null)
    showToast('Reset to defaults')
  }

  const handleSizeChange = (id: string, newSize: number) => {
    setDungeons(prev =>
      prev.map(d => (d.id === id ? { ...d, size: newSize } : d))
    )
  }

  const showToast = (msg: string) => {
    setToast(msg)
    setTimeout(() => setToast(null), 2500)
  }

  const selectedDungeon = dungeons.find(d => d.id === selected)

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-zinc-800">
        <div className="flex items-center gap-3">
          <MapPin className="w-5 h-5 text-amber-400" />
          <h1 className="text-xl font-bold text-zinc-100">Dungeon Map Editor</h1>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleReset}>
            <RotateCcw className="w-4 h-4 mr-1" /> Reset
          </Button>
          <Button size="sm" onClick={handleSave} disabled={saving}>
            <Save className="w-4 h-4 mr-1" /> {saving ? 'Saving...' : 'Save to Server'}
          </Button>
        </div>
      </div>

      {/* Map area */}
      <div className="flex-1 overflow-auto bg-zinc-950 p-4">
        <div ref={containerRef} className="relative inline-block" style={{ minWidth: '100%' }}>
          {/* Background image */}
          <img
            ref={imageRef}
            src="/dange.jpg"
            alt="Dungeon Map"
            className="block w-full max-w-[1400px] select-none"
            draggable={false}
            style={{ imageRendering: 'auto' }}
          />

          {/* Grid overlay */}
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none"
            style={{ opacity: 0.15 }}
          >
            {Array.from({ length: 10 }, (_, i) => (
              <line
                key={`vl-${i}`}
                x1={`${(i + 1) * 10}%`}
                y1="0"
                x2={`${(i + 1) * 10}%`}
                y2="100%"
                stroke="white"
                strokeWidth="0.5"
              />
            ))}
            {Array.from({ length: 10 }, (_, i) => (
              <line
                key={`hl-${i}`}
                x1="0"
                y1={`${(i + 1) * 10}%`}
                x2="100%"
                y2={`${(i + 1) * 10}%`}
                stroke="white"
                strokeWidth="0.5"
              />
            ))}
          </svg>

          {/* Dungeon nodes */}
          {loaded &&
            dungeons.map(d => (
              <div
                key={d.id}
                className="absolute flex flex-col items-center cursor-grab active:cursor-grabbing"
                style={{
                  left: `${d.x * 100}%`,
                  top: `${d.y * 100}%`,
                  transform: 'translate(-50%, -50%)',
                  zIndex: selected === d.id ? 50 : 10,
                }}
                onMouseDown={e => {
                  e.preventDefault()
                  setSelected(d.id)
                  setDragging(d.id)
                }}
              >
                {/* Label */}
                <div
                  className="px-2 py-0.5 rounded text-[10px] font-bold whitespace-nowrap mb-1"
                  style={{
                    backgroundColor: selected === d.id ? '#ef4444cc' : '#000000bb',
                    color: 'white',
                    border: selected === d.id ? '1px solid #ef4444' : `1px solid ${d.color}88`,
                  }}
                >
                  {d.label} (Lvl {d.minLevel})
                </div>

                {/* Node circle */}
                <div
                  className="rounded-full flex items-center justify-center text-white font-bold text-xs"
                  style={{
                    width: 40,
                    height: 40,
                    backgroundColor: `${d.color}cc`,
                    border: selected === d.id ? '3px solid #ef4444' : `2px solid ${d.color}`,
                    boxShadow: `0 0 12px ${d.color}66`,
                  }}
                >
                  {d.minLevel}
                </div>

                {/* Coordinates */}
                <div className="text-[9px] font-mono text-zinc-400 mt-0.5">
                  ({d.x.toFixed(2)}, {d.y.toFixed(2)})
                </div>
              </div>
            ))}
        </div>
      </div>

      {/* Control panel */}
      <div className="px-6 py-3 border-t border-zinc-800 bg-zinc-900">
        {selectedDungeon ? (
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <div
                className="w-3 h-3 rounded-full"
                style={{ backgroundColor: selectedDungeon.color }}
              />
              <span className="text-sm font-semibold text-zinc-200">{selectedDungeon.label}</span>
              <span className="text-xs text-zinc-500">Lvl {selectedDungeon.minLevel}</span>
            </div>

            <div className="flex items-center gap-2 text-xs text-zinc-400 font-mono">
              <span>X: {selectedDungeon.x.toFixed(3)}</span>
              <span>Y: {selectedDungeon.y.toFixed(3)}</span>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-xs text-zinc-500">Size:</span>
              <input
                type="range"
                min={0.05}
                max={0.40}
                step={0.01}
                value={selectedDungeon.size}
                onChange={e => handleSizeChange(selectedDungeon.id, +e.target.value)}
                className="w-32 accent-amber-500"
              />
              <span className="text-xs text-zinc-400 font-mono">{selectedDungeon.size.toFixed(2)}</span>
            </div>
          </div>
        ) : (
          <p className="text-sm text-zinc-500">Click a dungeon node to select, drag to reposition</p>
        )}
      </div>

      {/* Toast */}
      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 px-4 py-2 bg-emerald-600 text-white text-sm rounded-full shadow-lg z-50 animate-in fade-in">
          {toast}
        </div>
      )}
    </div>
  )
}
