'use client'

import { TimeEntry, PX_PER_MINUTE, GRID_START_HOUR, timeToMinutes, minutesToHHMM } from './useTimeEntries'

type Props = {
  entry: TimeEntry
  onTap: () => void
}

export default function TimeBlock({ entry, onTap }: Props) {
  const startMin = timeToMinutes(entry.start_time)
  const endMin = timeToMinutes(entry.end_time)
  const durationMin = Math.max(endMin - startMin, 15)
  const top = (startMin - GRID_START_HOUR * 60) * PX_PER_MINUTE
  const height = durationMin * PX_PER_MINUTE

  return (
    <div
      onClick={(e) => { e.stopPropagation(); onTap() }}
      className="absolute rounded-lg px-1.5 py-0.5 overflow-hidden cursor-pointer active:opacity-70 select-none"
      style={{
        top,
        height: Math.max(height, 20),
        left: 2,
        right: 2,
        backgroundColor: entry.color + '28',
        borderLeft: `3px solid ${entry.color}`,
      }}
    >
      <p className="text-xs font-semibold leading-tight truncate" style={{ color: entry.color }}>
        {entry.hobby}
      </p>
      {durationMin >= 30 && (
        <p className="text-xs text-gray-400 leading-tight">
          {minutesToHHMM(startMin)}–{minutesToHHMM(endMin)}
        </p>
      )}
    </div>
  )
}
