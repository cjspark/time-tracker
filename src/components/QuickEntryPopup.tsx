'use client'

import { useEffect, useRef } from 'react'
import { X } from 'lucide-react'
import { TimeEntryForm, minutesToHHMM, timeToMinutes } from './calendar/useTimeEntries'
import { useAllHobbies } from '@/lib/useAllHobbies'
import TimeSelect from './TimeSelect'

const POPUP_W = 232

type Props = {
  clientX: number
  clientY: number
  form: TimeEntryForm
  saving: boolean
  onChange: (f: TimeEntryForm) => void
  onSave: () => void
  onClose: () => void
}

export default function QuickEntryPopup({ clientX, clientY, form, saving, onChange, onSave, onClose }: Props) {
  const ref = useRef<HTMLDivElement>(null)
  const hobbyList = useAllHobbies()

  // Click outside to close
  useEffect(() => {
    function onDown(e: MouseEvent | TouchEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) onClose()
    }
    document.addEventListener('mousedown', onDown)
    document.addEventListener('touchstart', onDown)
    return () => {
      document.removeEventListener('mousedown', onDown)
      document.removeEventListener('touchstart', onDown)
    }
  }, [onClose])

  // Calculate popup position, stay within viewport
  const margin = 8
  const popupH = 360
  let left = clientX - POPUP_W / 2
  let top = clientY - popupH - 12  // prefer above

  if (typeof window !== 'undefined') {
    if (left < margin) left = margin
    if (left + POPUP_W > window.innerWidth - margin) left = window.innerWidth - POPUP_W - margin
    if (top < margin) top = clientY + 12  // flip below
    if (top + popupH > window.innerHeight - margin) top = window.innerHeight - popupH - margin
  }

  const startMin = timeToMinutes(form.start_time)
  const endMin = timeToMinutes(form.end_time)
  const duration = endMin - startMin

  return (
    <div
      ref={ref}
      className="fixed z-50 bg-white rounded-2xl shadow-xl border border-gray-100 p-4"
      style={{ left, top, width: POPUP_W }}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs font-medium text-gray-500">
          {minutesToHHMM(startMin)} – {minutesToHHMM(endMin)}
          <span className="ml-1.5 text-gray-300">{duration}分钟</span>
        </span>
        <button onClick={onClose} className="p-0.5 rounded-lg text-gray-300 hover:text-gray-500">
          <X size={14} />
        </button>
      </div>

      {/* 爱好选择 */}
      <div className="grid grid-cols-3 gap-1.5 mb-3">
        {hobbyList.map((h) => (
          <button
            key={h.label}
            type="button"
            onClick={() => onChange({ ...form, hobby: h.label, color: h.color })}
            className="flex items-center gap-1.5 px-2 py-1.5 rounded-xl text-xs transition-colors"
            style={form.hobby === h.label ? {
              backgroundColor: h.color + '18',
              color: h.color,
              outline: `1.5px solid ${h.color}`,
            } : {
              backgroundColor: '#f9fafb',
              color: '#6b7280',
            }}
          >
            <span className="w-1.5 h-1.5 rounded-full shrink-0" style={{ backgroundColor: h.color }} />
            {h.displayLabel}
          </button>
        ))}
      </div>

      {/* 时间调整 */}
      <div className="grid grid-cols-2 gap-2 mb-3">
        <div>
          <label className="block text-xs text-gray-400 mb-0.5">开始</label>
          <TimeSelect value={form.start_time} onChange={v => onChange({ ...form, start_time: v })} className="w-full" />
        </div>
        <div>
          <label className="block text-xs text-gray-400 mb-0.5">结束</label>
          <TimeSelect value={form.end_time} onChange={v => onChange({ ...form, end_time: v })} className="w-full" />
        </div>
      </div>

      {/* 备注 + 心情 */}
      <div className="flex gap-1.5 items-center mb-3">
        <input
          type="text"
          placeholder="备注（选填）"
          value={form.notes}
          onChange={(e) => onChange({ ...form, notes: e.target.value })}
          className="flex-1 px-2.5 py-1.5 border border-gray-200 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
        />
        <div className="flex gap-0.5 border border-gray-200 rounded-lg px-1.5 py-1 bg-gray-50 shrink-0">
          {([
            { v: 1, e: '😩' },
            { v: 2, e: '😕' },
            { v: 3, e: '😐' },
            { v: 4, e: '🙂' },
            { v: 5, e: '😄' },
          ] as const).map(({ v, e }) => (
            <button
              key={v}
              type="button"
              onClick={() => onChange({ ...form, mood: (form.mood ?? 0) === v ? null : v })}
              className="text-sm leading-none transition-all"
              style={{ opacity: form.mood === null ? 0.35 : form.mood === v ? 1 : 0.2, transform: form.mood === v ? 'scale(1.2)' : 'scale(1)' }}
            >
              {e}
            </button>
          ))}
        </div>
      </div>

      {/* 保存 */}
      <button
        onClick={onSave}
        disabled={saving || !form.hobby}
        className="w-full py-2 rounded-xl text-sm font-medium text-white transition-colors disabled:opacity-50"
        style={{ backgroundColor: form.color }}
      >
        {saving ? '保存中...' : '保存'}
      </button>
    </div>
  )
}
