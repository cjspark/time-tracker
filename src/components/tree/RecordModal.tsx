'use client'

import { useState } from 'react'
import { X, Trash2, Pencil, Check } from 'lucide-react'
import { localDateString } from '@/lib/dateUtils'
import type { Achievement, AchievementRecord, DividendMeta, DepositMeta, StockMeta } from './useTreeData'

function MetaSummary({ achievement }: { achievement: Achievement }) {
  if (!achievement.metadata || achievement.template === 'general') return null
  const m = achievement.metadata
  const symbol = (m as DividendMeta | DepositMeta | StockMeta).currency === 'USD' ? '$' : '¥'

  if (achievement.template === 'dividend') {
    const d = m as DividendMeta
    return (
      <div className="bg-gray-50 rounded-xl px-3 py-2 text-xs text-gray-500 space-y-0.5">
        <div className="flex justify-between"><span>持股数</span><span className="font-medium">{d.shares} 股</span></div>
        <div className="flex justify-between"><span>每10股分红</span><span className="font-medium">{symbol}{d.dividendPer10}</span></div>
      </div>
    )
  }
  if (achievement.template === 'deposit') {
    const d = m as DepositMeta
    return (
      <div className="bg-gray-50 rounded-xl px-3 py-2 text-xs text-gray-500 space-y-0.5">
        <div className="flex justify-between"><span>本金</span><span className="font-medium">{symbol}{d.principal.toLocaleString()}</span></div>
        <div className="flex justify-between"><span>年化利率</span><span className="font-medium">{d.rate}%</span></div>
      </div>
    )
  }
  if (achievement.template === 'stock_profit') {
    const d = m as StockMeta
    return d.costBasis ? (
      <div className="bg-gray-50 rounded-xl px-3 py-2 text-xs text-gray-500">
        <div className="flex justify-between"><span>持有成本</span><span className="font-medium">{symbol}{d.costBasis.toLocaleString()}</span></div>
      </div>
    ) : null
  }
  return null
}

type Props = {
  achievement: Achievement
  maxMinutes: number
  onAddRecord: (data: { value: number; note: string; date: string }) => Promise<void>
  onDeleteRecord: (id: string) => Promise<void>
  onDeleteAchievement: () => Promise<void>
  onUpdateTarget: (target_value: number) => Promise<void>
  onArchive: () => Promise<void>
  onClose: () => void
}

function formatDate(d: string) {
  return d.replace(/-/g, '/')
}

export default function RecordModal({
  achievement, onAddRecord, onDeleteRecord, onDeleteAchievement, onUpdateTarget, onArchive, onClose
}: Props) {
  const [value, setValue] = useState('')
  const [note, setNote] = useState('')
  const [date, setDate] = useState(localDateString())
  const [saving, setSaving] = useState(false)
  const [checkInSaving, setCheckInSaving] = useState(false)

  const [editingTarget, setEditingTarget] = useState(false)
  const [targetVal, setTargetVal] = useState(String(achievement.target_value))
  const [savingTarget, setSavingTarget] = useState(false)

  const isHabit = achievement.template === 'habit'

  async function handleCheckIn() {
    setCheckInSaving(true)
    await onAddRecord({ value: 1, note, date })
    setNote('')
    setCheckInSaving(false)
  }

  async function handleAdd() {
    if (!value) return
    setSaving(true)
    await onAddRecord({ value: parseFloat(value), note, date })
    setValue('')
    setNote('')
    setSaving(false)
  }

  async function handleSaveTarget() {
    const v = parseFloat(targetVal)
    if (!v || v <= 0) return
    setSavingTarget(true)
    await onUpdateTarget(v)
    setSavingTarget(false)
    setEditingTarget(false)
  }

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center bg-black/40" onClick={onClose}>
      <div
        className="w-full max-w-lg bg-white rounded-t-3xl p-5 space-y-4 mb-16 max-h-[80vh] overflow-y-auto"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-semibold text-gray-800">{achievement.name}</h2>
            <div className="flex items-center gap-1 mt-0.5">
              <span className="text-xs text-gray-400">{achievement.category} · 目标</span>
              {editingTarget ? (
                <span className="flex items-center gap-1">
                  <input
                    type="number"
                    value={targetVal}
                    onChange={e => setTargetVal(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && handleSaveTarget()}
                    className="w-20 px-1.5 py-0.5 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-red-400"
                    autoFocus
                  />
                  <span className="text-xs text-gray-400">{achievement.unit}</span>
                  <button onClick={handleSaveTarget} disabled={savingTarget} className="text-red-400">
                    <Check size={13} />
                  </button>
                  <button onClick={() => { setEditingTarget(false); setTargetVal(String(achievement.target_value)) }} className="text-gray-300">
                    <X size={13} />
                  </button>
                </span>
              ) : (
                <span className="flex items-center gap-1">
                  <span className="text-xs text-gray-400">{achievement.target_value}{achievement.unit}</span>
                  <button onClick={() => setEditingTarget(true)} className="text-gray-300 hover:text-red-400">
                    <Pencil size={11} />
                  </button>
                </span>
              )}
            </div>
          </div>
          <button onClick={onClose}><X size={18} className="text-gray-400" /></button>
        </div>

        {/* Progress bar */}
        <div className="space-y-1.5">
          <div className="flex items-center justify-between text-xs text-gray-500">
            <span>当前 {achievement.current_value}{achievement.unit}</span>
            <span className={achievement.progress >= 1 ? 'text-amber-500 font-semibold' : ''}>
              {Math.round(achievement.progress * 100)}%
              {achievement.progress >= 1 && ' 🏅'}
            </span>
          </div>
          <div className="h-2.5 bg-gray-100 rounded-full overflow-hidden">
            <div
              className={`h-full rounded-full transition-all ${achievement.progress >= 1 ? 'bg-amber-400' : 'bg-red-400'}`}
              style={{ width: `${Math.min(100, achievement.progress * 100)}%` }}
            />
          </div>
        </div>

        {/* Meta summary */}
        <MetaSummary achievement={achievement} />

        {/* Add record form */}
        <div className="bg-gray-50 rounded-2xl p-4 space-y-3">
          {isHabit ? (
            <>
              <p className="text-xs font-medium text-gray-600">今日打卡</p>
              <div className="flex gap-2">
                <input
                  type="date" value={date} onChange={e => setDate(e.target.value)}
                  className="px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400 bg-white"
                />
                <input
                  type="text" value={note} onChange={e => setNote(e.target.value)}
                  placeholder="备注（可选）"
                  className="flex-1 px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400 bg-white"
                />
              </div>
              <button
                onClick={handleCheckIn} disabled={checkInSaving}
                className="w-full py-3 bg-green-500 text-white rounded-xl text-sm font-semibold disabled:opacity-40 flex items-center justify-center gap-2"
              >
                {checkInSaving ? '记录中...' : `✓ 打卡 +1${achievement.unit}`}
              </button>
            </>
          ) : (
            <>
              <p className="text-xs font-medium text-gray-600">添加记录</p>
              <div className="flex gap-2">
                <input
                  type="number" value={value} onChange={e => setValue(e.target.value)}
                  placeholder={`数值（${achievement.unit}）`}
                  className="flex-1 px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400 bg-white"
                />
                <input
                  type="date" value={date} onChange={e => setDate(e.target.value)}
                  className="px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400 bg-white"
                />
              </div>
              <input
                type="text" value={note} onChange={e => setNote(e.target.value)}
                placeholder="感想/备注（可选）"
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400 bg-white"
              />
              <button
                onClick={handleAdd} disabled={saving || !value}
                className="w-full py-2.5 bg-red-500 text-white rounded-xl text-sm font-medium disabled:opacity-40"
              >
                {saving ? '保存中...' : '添加'}
              </button>
            </>
          )}
        </div>

        {/* Records list */}
        {achievement.records.length > 0 && (
          <div className="space-y-2">
            <p className="text-xs font-medium text-gray-500">历史记录</p>
            {[...achievement.records]
              .sort((a, b) => b.date.localeCompare(a.date))
              .map((r: AchievementRecord) => (
                <div key={r.id} className="flex items-start justify-between bg-gray-50 rounded-xl px-3 py-2.5">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-semibold text-red-500">+{r.value}{achievement.unit}</span>
                      <span className="text-xs text-gray-400">{formatDate(r.date)}</span>
                    </div>
                    {r.note && <p className="text-xs text-gray-500 mt-0.5">{r.note}</p>}
                  </div>
                  <button
                    onClick={() => onDeleteRecord(r.id)}
                    className="text-gray-300 hover:text-red-400 mt-0.5"
                  >
                    <Trash2 size={13} />
                  </button>
                </div>
              ))}
          </div>
        )}

        {/* Archive / Delete */}
        <div className="space-y-1">
          {achievement.progress >= 1 && (
            <button
              onClick={onArchive}
              className="w-full py-2.5 bg-amber-50 text-amber-600 rounded-xl text-sm font-medium hover:bg-amber-100 transition-colors"
            >
              🏅 归档为里程碑
            </button>
          )}
          <button
            onClick={async () => { await onDeleteAchievement(); onClose() }}
            className="w-full py-2 text-xs text-red-400 hover:text-red-600 transition-colors"
          >
            删除此成就
          </button>
        </div>
      </div>
    </div>
  )
}
