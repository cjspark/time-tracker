'use client'

import { useRef, useEffect, forwardRef, useImperativeHandle } from 'react'
import { TimeEntry, PX_PER_MINUTE, GRID_START_HOUR, GRID_END_HOUR, GRID_TOTAL_MINUTES, todayStr } from './useTimeEntries'
import DayColumn from './DayColumn'

const HOURS = Array.from({ length: GRID_END_HOUR - GRID_START_HOUR }, (_, i) => GRID_START_HOUR + i)
const GUTTER_W = 44
const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六']
const NAV_COOLDOWN_MS = 800

export type TimeGridHandle = {
  scrollToTime: (minutes: number) => void
}

type Props = {
  dates: string[]
  entries: TimeEntry[]
  anchor: string
  onBlockTap: (entry: TimeEntry) => void
  onGridInteract: (date: string, minuteOffset: number, clientX: number, clientY: number) => void
  onReachTop?: () => void
  onReachBottom?: () => void
}

function DayHeader({ dates, anchor }: { dates: string[]; anchor: string }) {
  const today = todayStr()
  return (
    <div className="flex shrink-0 border-b border-gray-200 bg-white" style={{ paddingLeft: GUTTER_W }}>
      {dates.map((date) => {
        const [y, mo, day] = date.split('-').map(Number)
        const d = new Date(y, mo - 1, day)
        const isAnchor = date === anchor
        const isTodayOnly = date === today && !isAnchor
        return (
          <div key={date} className="flex-1 flex flex-col items-center py-1.5 border-r border-gray-100 last:border-r-0">
            <span className="text-xs text-gray-400">{WEEKDAYS[d.getDay()]}</span>
            <div className={`w-7 h-7 rounded-full flex items-center justify-center text-sm font-medium mt-0.5 ${
              isAnchor
                ? 'bg-blue-600 text-white'
                : isTodayOnly
                ? 'ring-2 ring-blue-400 text-blue-600'
                : 'text-gray-700'
            }`}>
              {d.getDate()}
            </div>
          </div>
        )
      })}
    </div>
  )
}

function CurrentTimeLine() {
  const now = new Date()
  const minutes = now.getHours() * 60 + now.getMinutes()
  if (minutes < GRID_START_HOUR * 60 || minutes > GRID_END_HOUR * 60) return null
  const top = (minutes - GRID_START_HOUR * 60) * PX_PER_MINUTE
  return (
    <div className="absolute left-0 right-0 z-10 flex items-center pointer-events-none" style={{ top: top - 1 }}>
      <div className="w-2 h-2 rounded-full bg-red-500 -ml-1 shrink-0" />
      <div className="flex-1 h-px bg-red-500" />
    </div>
  )
}

const TimeGrid = forwardRef<TimeGridHandle, Props>(function TimeGrid(
  { dates, entries, anchor, onBlockTap, onGridInteract, onReachTop, onReachBottom },
  ref
) {
  const scrollRef = useRef<HTMLDivElement>(null)
  const today = todayStr()
  const totalHeight = GRID_TOTAL_MINUTES * PX_PER_MINUTE
  const lastNavTime = useRef(0)

  useImperativeHandle(ref, () => ({
    scrollToTime(minutes: number) {
      if (!scrollRef.current) return
      scrollRef.current.scrollTop = Math.max(0, (minutes - GRID_START_HOUR * 60) * PX_PER_MINUTE - 80)
    },
  }))

  // Scroll to current time on initial mount
  useEffect(() => {
    if (!scrollRef.current) return
    const now = new Date()
    const minutes = now.getHours() * 60 + now.getMinutes() - GRID_START_HOUR * 60
    scrollRef.current.scrollTop = Math.max(0, minutes * PX_PER_MINUTE - 100)
  }, [])

  // Wheel navigation: scroll past top → prev day, scroll past bottom → next day
  useEffect(() => {
    const el = scrollRef.current
    if (!el) return

    function handleWheel(e: WheelEvent) {
      const now = Date.now()
      if (now - lastNavTime.current < NAV_COOLDOWN_MS) return
      if (!el) return
      if (e.deltaY < 0 && el.scrollTop <= 0) {
        lastNavTime.current = now
        onReachTop?.()
      } else if (e.deltaY > 0 && el.scrollTop + el.clientHeight >= el.scrollHeight - 2) {
        lastNavTime.current = now
        onReachBottom?.()
      }
    }

    el.addEventListener('wheel', handleWheel, { passive: true })
    return () => el.removeEventListener('wheel', handleWheel)
  }, [onReachTop, onReachBottom])

  const entriesByDate = (date: string) => entries.filter((e) => e.date === date)

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <DayHeader dates={dates} anchor={anchor} />
      <div ref={scrollRef} className="flex-1 overflow-y-auto">
        <div className="flex" style={{ height: totalHeight }}>
          {/* Time gutter */}
          <div className="shrink-0 relative" style={{ width: GUTTER_W, height: totalHeight }}>
            {HOURS.map((h) => (
              <div
                key={h}
                className="absolute right-2 text-xs text-gray-400 -translate-y-2"
                style={{ top: (h - GRID_START_HOUR) * 60 * PX_PER_MINUTE }}
              >
                {h}:00
              </div>
            ))}
          </div>

          {/* Grid area */}
          <div className="relative flex flex-1 border-l border-gray-100" style={{ height: totalHeight }}>
            {HOURS.map((h) => (
              <div
                key={h}
                className="absolute left-0 right-0 border-t border-gray-100 pointer-events-none"
                style={{ top: (h - GRID_START_HOUR) * 60 * PX_PER_MINUTE }}
              />
            ))}
            {dates.includes(today) && <CurrentTimeLine />}
            {dates.map((date) => (
              <DayColumn
                key={date}
                date={date}
                entries={entriesByDate(date)}
                onBlockTap={onBlockTap}
                onGridInteract={onGridInteract}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
})

export default TimeGrid
