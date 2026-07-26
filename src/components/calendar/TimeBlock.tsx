'use client'

import { TimeEntry, PX_PER_MINUTE, GRID_START_HOUR, timeToMinutes, minutesToHHMM } from './useTimeEntries'
import { TIME_CATEGORIES } from '@/components/HobbiesView'
import type { TimeCategory } from '@/components/HobbiesView'

function hexToRgba(hex: string, alpha: number): string {
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return `rgba(${r},${g},${b},${alpha})`
}

function resolveColor(hobby: string, fallback: string): string {
  try {
    const timeCatMap: Record<string, TimeCategory> = JSON.parse(localStorage.getItem('hobby_time_category') ?? '{}')
    const timecat = timeCatMap[hobby]
    if (timecat) {
      const found = TIME_CATEGORIES.find(t => t.key === timecat)
      if (found) return found.color
    }
    const overrides: Record<string, string> = JSON.parse(localStorage.getItem('hobby_color_overrides') ?? '{}')
    return overrides[hobby] ?? fallback
  } catch { return fallback }
}

type Props = {
  entry: TimeEntry
  onTap: () => void
}

export default function TimeBlock({ entry, onTap }: Props) {
  const startMin = timeToMinutes(entry.start_time)
  const endMin = timeToMinutes(entry.end_time)
  const durationMin = Math.max(endMin - startMin, 1)
  const top = (startMin - GRID_START_HOUR * 60) * PX_PER_MINUTE
  const height = Math.max(durationMin * PX_PER_MINUTE, 4)
  const color = resolveColor(entry.hobby, entry.color)

  // mood 1=darkest, 5=lightest, null=default
  const moodOpacity: Record<number, number> = { 1: 0.95, 2: 0.75, 3: 0.55, 4: 0.35, 5: 0.18 }
  const bgOpacity = entry.mood ? moodOpacity[entry.mood] : 0.18
  const borderOpacity = entry.mood ? Math.min(1, bgOpacity + 0.3) : 0.6

  return (
    <div
      onClick={(e) => { e.stopPropagation(); onTap() }}
      className="absolute rounded-lg overflow-hidden cursor-pointer active:opacity-70 select-none"
      style={{
        top,
        height,
        left: 2,
        right: 2,
        backgroundColor: hexToRgba(color, bgOpacity),
        borderLeft: `3px solid ${hexToRgba(color, borderOpacity)}`,
      }}
    >
      {height >= 16 && (
        <p className="text-xs font-semibold leading-tight truncate px-1.5 pt-0.5"
          style={{ color: bgOpacity > 0.5 ? 'white' : color }}>
          {entry.notes || entry.hobby}
        </p>
      )}
      {height >= 32 && durationMin >= 30 && (
        <p className="text-xs leading-tight px-1.5"
          style={{ color: bgOpacity > 0.5 ? 'rgba(255,255,255,0.75)' : '#9CA3AF' }}>
          {minutesToHHMM(startMin)}–{minutesToHHMM(endMin)}
        </p>
      )}
    </div>
  )
}
