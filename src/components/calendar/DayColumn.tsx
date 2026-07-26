'use client'

import { TimeEntry, PX_PER_MINUTE, GRID_START_HOUR, GRID_TOTAL_MINUTES, SNAP_MINUTES } from './useTimeEntries'
import { useLongPress } from './useLongPress'
import TimeBlock from './TimeBlock'

type Props = {
  date: string
  entries: TimeEntry[]
  onBlockTap: (entry: TimeEntry) => void
  onGridInteract: (date: string, minuteOffset: number, clientX: number, clientY: number) => void
}

function calcMinutes(relY: number): number {
  const raw = Math.floor(relY / PX_PER_MINUTE)
  const snapped = Math.round(raw / SNAP_MINUTES) * SNAP_MINUTES
  return GRID_START_HOUR * 60 + Math.max(0, Math.min(snapped, GRID_TOTAL_MINUTES - SNAP_MINUTES))
}

export default function DayColumn({ date, entries, onBlockTap, onGridInteract }: Props) {
  const totalHeight = GRID_TOTAL_MINUTES * PX_PER_MINUTE

  const longPress = useLongPress((e) => {
    const touch = e.changedTouches[0] ?? e.touches[0]
    const el = e.currentTarget as HTMLDivElement
    const rect = el.getBoundingClientRect()
    onGridInteract(date, calcMinutes(touch.clientY - rect.top), touch.clientX, touch.clientY)
  })

  function handleContextMenu(e: React.MouseEvent<HTMLDivElement>) {
    e.preventDefault()
    const rect = e.currentTarget.getBoundingClientRect()
    onGridInteract(date, calcMinutes(e.clientY - rect.top), e.clientX, e.clientY)
  }

  return (
    <div
      className="relative flex-1 border-r border-gray-100 last:border-r-0 select-none"
      style={{ height: totalHeight, WebkitUserSelect: 'none', userSelect: 'none', WebkitTouchCallout: 'none' } as React.CSSProperties}
      onContextMenu={handleContextMenu}
      {...longPress}
    >
      {entries.map((entry) => (
        <TimeBlock key={entry.id} entry={entry} onTap={() => onBlockTap(entry)} />
      ))}
    </div>
  )
}
