'use client'

import { useState, useRef, useCallback } from 'react'
import { TimeEntry, PX_PER_MINUTE, GRID_START_HOUR, GRID_TOTAL_MINUTES, SNAP_MINUTES } from './useTimeEntries'
import TimeBlock from './TimeBlock'

type Props = {
  date: string
  entries: TimeEntry[]
  onBlockTap: (entry: TimeEntry) => void
  onGridInteract: (date: string, minuteOffset: number, clientX: number, clientY: number, endMinutes?: number) => void
}

function snapMinutes(raw: number): number {
  return Math.round(raw / SNAP_MINUTES) * SNAP_MINUTES
}

function calcMinutes(relY: number): number {
  const raw = Math.floor(relY / PX_PER_MINUTE)
  const snapped = snapMinutes(raw)
  return GRID_START_HOUR * 60 + Math.max(0, Math.min(snapped, GRID_TOTAL_MINUTES - SNAP_MINUTES))
}

function minutesToY(minutes: number): number {
  return (minutes - GRID_START_HOUR * 60) * PX_PER_MINUTE
}

function formatTime(minutes: number): string {
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

export default function DayColumn({ date, entries, onBlockTap, onGridInteract }: Props) {
  const totalHeight = GRID_TOTAL_MINUTES * PX_PER_MINUTE
  const containerRef = useRef<HTMLDivElement>(null)

  // Drag-to-create state
  const [draft, setDraft] = useState<{ startMin: number; endMin: number } | null>(null)
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const pointerStartY = useRef(0)
  const pointerStartMin = useRef(0)
  const isDragging = useRef(false)
  const pointerId = useRef<number | null>(null)

  function getRelY(clientY: number): number {
    if (!containerRef.current) return 0
    return clientY - containerRef.current.getBoundingClientRect().top
  }

  function onPointerDown(e: React.PointerEvent<HTMLDivElement>) {
    if (e.button !== 0 && e.pointerType === 'mouse') return
    const relY = getRelY(e.clientY)
    const startMin = calcMinutes(relY)
    pointerStartY.current = e.clientY
    pointerStartMin.current = startMin
    pointerId.current = e.pointerId
    isDragging.current = false

    // Start long press timer
    longPressTimer.current = setTimeout(() => {
      isDragging.current = true
      setDraft({ startMin, endMin: startMin + 60 })
      // haptic feedback via vibration API if available
      if (navigator.vibrate) navigator.vibrate(10)
      ;(e.target as HTMLElement).setPointerCapture?.(e.pointerId)
    }, 400)
  }

  function onPointerMove(e: React.PointerEvent<HTMLDivElement>) {
    if (!isDragging.current || !draft) return
    const relY = getRelY(e.clientY)
    const currentMin = calcMinutes(relY)
    const endMin = Math.max(pointerStartMin.current + SNAP_MINUTES, currentMin)
    setDraft({ startMin: pointerStartMin.current, endMin })
  }

  function onPointerUp(e: React.PointerEvent<HTMLDivElement>) {
    if (longPressTimer.current) {
      clearTimeout(longPressTimer.current)
      longPressTimer.current = null
    }

    if (isDragging.current && draft) {
      // Open form with the selected time range
      const rect = containerRef.current?.getBoundingClientRect()
      const centerX = rect ? rect.left + rect.width / 2 : e.clientX
      onGridInteract(date, draft.startMin, centerX, e.clientY, draft.endMin)
      setDraft(null)
      isDragging.current = false
    }
  }

  function onPointerCancel() {
    if (longPressTimer.current) clearTimeout(longPressTimer.current)
    setDraft(null)
    isDragging.current = false
  }

  function handleContextMenu(e: React.MouseEvent<HTMLDivElement>) {
    e.preventDefault()
    const rect = e.currentTarget.getBoundingClientRect()
    onGridInteract(date, calcMinutes(e.clientY - rect.top), e.clientX, e.clientY)
  }

  const draftTop = draft ? minutesToY(draft.startMin) : 0
  const draftHeight = draft ? Math.max((draft.endMin - draft.startMin) * PX_PER_MINUTE, 20) : 0

  return (
    <div
      ref={containerRef}
      className="relative flex-1 border-r border-gray-100 last:border-r-0 select-none"
      style={{ height: totalHeight, WebkitUserSelect: 'none' } as React.CSSProperties}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerCancel}
      onContextMenu={handleContextMenu}
    >
      {entries.map((entry) => (
        <TimeBlock key={entry.id} entry={entry} onTap={() => onBlockTap(entry)} />
      ))}

      {/* Draft block shown while dragging */}
      {draft && (
        <div
          className="absolute left-1 right-1 rounded-lg pointer-events-none z-10 flex flex-col items-center justify-center"
          style={{
            top: draftTop,
            height: draftHeight,
            backgroundColor: '#22c55e44',
            border: '2px solid #22c55e',
          }}
        >
          <span className="text-xs font-semibold text-green-700">
            {formatTime(draft.startMin)} – {formatTime(draft.endMin)}
          </span>
        </div>
      )}
    </div>
  )
}
