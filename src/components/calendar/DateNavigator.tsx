'use client'

import { useRef } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { View } from './ViewSwitcher'
import { addDays, getMonday } from './useTimeEntries'

type Props = {
  view: View
  anchorDate: string
  onPrev: () => void
  onNext: () => void
  onToday: () => void
  onDatePick: (date: string) => void
  isToday: boolean
}

const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六']
const MONTHS = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']

function formatDate(dateStr: string) {
  const d = new Date(dateStr)
  return { month: MONTHS[d.getMonth()], day: d.getDate(), weekday: WEEKDAYS[d.getDay()] }
}

function getLabel(view: View, anchor: string): string {
  const a = formatDate(anchor)
  if (view === 'day') {
    return `${a.month}月${a.day}日 周${a.weekday}`
  }
  if (view === '2day') {
    const b = formatDate(addDays(anchor, 1))
    if (a.month === b.month) return `${a.month}月${a.day}–${b.day}日`
    return `${a.month}月${a.day}日 – ${b.month}月${b.day}日`
  }
  // week
  const monday = getMonday(anchor)
  const sunday = addDays(monday, 6)
  const m = formatDate(monday)
  const s = formatDate(sunday)
  if (m.month === s.month) return `${m.month}月${m.day}–${s.day}日`
  return `${m.month}月${m.day}日 – ${s.month}月${s.day}日`
}

export default function DateNavigator({ view, anchorDate, onPrev, onNext, onToday, onDatePick, isToday }: Props) {
  const label = getLabel(view, anchorDate)
  const inputRef = useRef<HTMLInputElement>(null)

  return (
    <div className="flex items-center gap-2 px-4 py-2 bg-white border-b border-gray-100">
      <button
        onClick={onToday}
        className={`text-xs px-2.5 py-1 rounded-lg font-medium transition-colors ${
          isToday ? 'bg-blue-50 text-blue-600' : 'bg-gray-100 text-gray-500'
        }`}
      >
        今天
      </button>
      <div className="flex items-center gap-1 flex-1 justify-center">
        <button onClick={onPrev} className="p-1 rounded-lg hover:bg-gray-100 text-gray-500">
          <ChevronLeft size={18} />
        </button>

        {/* Clickable label → opens native date picker */}
        <button
          onClick={() => inputRef.current?.showPicker?.() ?? inputRef.current?.click()}
          className="text-sm font-medium text-gray-800 min-w-[140px] text-center hover:text-blue-600 transition-colors"
        >
          {label}
        </button>
        <input
          ref={inputRef}
          type="date"
          value={anchorDate}
          onChange={(e) => e.target.value && onDatePick(e.target.value)}
          className="sr-only"
        />

        <button onClick={onNext} className="p-1 rounded-lg hover:bg-gray-100 text-gray-500">
          <ChevronRight size={18} />
        </button>
      </div>
    </div>
  )
}
