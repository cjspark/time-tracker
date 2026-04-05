'use client'

import { useEffect, useRef } from 'react'
import { X } from 'lucide-react'
import { TimeEntryForm, HOBBY_LIST } from './calendar/useTimeEntries'

type Props = {
  open: boolean
  form: TimeEntryForm
  saving: boolean
  isEditing: boolean
  onChange: (f: TimeEntryForm) => void
  onSave: () => void
  onDelete?: () => void
  onClose: () => void
}

export default function TimeEntryModal({
  open, form, saving, isEditing,
  onChange, onSave, onDelete, onClose,
}: Props) {
  const firstRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (open) setTimeout(() => firstRef.current?.focus(), 100)
  }, [open])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative bg-white rounded-t-2xl px-4 pt-4 pb-8 max-w-lg w-full mx-auto max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-base font-semibold text-gray-900">
            {isEditing ? '编辑记录' : '添加时间记录'}
          </h2>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 text-gray-400">
            <X size={20} />
          </button>
        </div>

        <div className="space-y-4">
          {/* 爱好选择 */}
          <div>
            <label className="block text-xs text-gray-500 mb-2">爱好</label>
            <div className="grid grid-cols-3 gap-2">
              {HOBBY_LIST.map((h) => (
                <button
                  key={h.label}
                  type="button"
                  onClick={() => onChange({ ...form, hobby: h.label, color: h.color })}
                  className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm transition-colors ${
                    form.hobby === h.label
                      ? 'ring-2 ring-offset-1'
                      : 'bg-gray-50 text-gray-600 hover:bg-gray-100'
                  }`}
                  style={form.hobby === h.label ? {
                    backgroundColor: h.color + '18',
                    color: h.color,
                    outlineColor: h.color,
                  } : undefined}
                >
                  <span
                    className="w-2 h-2 rounded-full shrink-0"
                    style={{ backgroundColor: h.color }}
                  />
                  {h.label}
                </button>
              ))}
            </div>
          </div>

          {/* 日期 */}
          <div>
            <label className="block text-xs text-gray-500 mb-1">日期</label>
            <input
              type="date"
              ref={firstRef}
              value={form.date}
              onChange={(e) => onChange({ ...form, date: e.target.value })}
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* 开始 / 结束时间 */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs text-gray-500 mb-1">开始时间</label>
              <input
                type="time"
                value={form.start_time}
                onChange={(e) => onChange({ ...form, start_time: e.target.value })}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-xs text-gray-500 mb-1">结束时间</label>
              <input
                type="time"
                value={form.end_time}
                onChange={(e) => onChange({ ...form, end_time: e.target.value })}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {/* 备注 */}
          <div>
            <label className="block text-xs text-gray-500 mb-1">
              备注 <span className="text-gray-400">（选填）</span>
            </label>
            <input
              type="text"
              placeholder="如：跑步5km，心率145"
              value={form.notes}
              onChange={(e) => onChange({ ...form, notes: e.target.value })}
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* 操作按钮 */}
          <div className="flex gap-2 pt-1">
            {isEditing && onDelete && (
              <button
                onClick={onDelete}
                className="px-4 py-3 rounded-xl text-sm text-red-500 hover:bg-red-50 transition-colors"
              >
                删除
              </button>
            )}
            <button
              onClick={onSave}
              disabled={saving || !form.hobby || !form.date || !form.start_time || !form.end_time}
              className="flex-1 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-3 rounded-xl text-sm transition-colors"
            >
              {saving ? '保存中...' : '保存'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
