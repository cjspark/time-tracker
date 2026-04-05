'use client'

import { useEffect, useRef } from 'react'
import { X } from 'lucide-react'
import { TimeEntryForm, HOBBY_LIST, minutesToHHMM, timeToMinutes } from './calendar/useTimeEntries'

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
        {HOBBY_LIST.map((h) => (
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
            {h.label}
          </button>
        ))}
      </div>

      {/* 时间调整 */}
      <div className="grid grid-cols-2 gap-2 mb-3">
        <div>
          <label className="block text-xs text-gray-400 mb-0.5">开始</label>
          <input
            type="time"
            value={form.start_time}
            onChange={(e) => onChange({ ...form, start_time: e.target.value })}
            className="w-full px-2 py-1.5 border border-gray-200 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-400 mb-0.5">结束</label>
          <input
            type="time"
            value={form.end_time}
            onChange={(e) => onChange({ ...form, end_time: e.target.value })}
            className="w-full px-2 py-1.5 border border-gray-200 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-blue-500"
          />
        </div>
      </div>

      {/* 备注 */}
      <input
        type="text"
        placeholder="备注（选填）"
        value={form.notes}
        onChange={(e) => onChange({ ...form, notes: e.target.value })}
        className="w-full px-2.5 py-1.5 border border-gray-200 rounded-lg text-xs mb-3 focus:outline-none focus:ring-1 focus:ring-blue-500"
      />

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
