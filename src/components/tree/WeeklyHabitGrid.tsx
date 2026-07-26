'use client'

import { useState } from 'react'
import { ChevronLeft, ChevronRight, Plus, X, Pencil } from 'lucide-react'
import { useHabitData, getWeekDays } from './useHabitData'
import { localDateString } from '@/lib/dateUtils'
import { createClient } from '@/lib/supabase/client'
import type { Achievement } from './useTreeData'

const DAY_LABELS = ['一', '二', '三', '四', '五', '六', '日']
const TODAY = localDateString()

const HABIT_UNIT_SUGGESTIONS: Record<string, number[]> = {
  '天': [30, 90, 180, 330, 365],
  '周': [12, 26, 48, 52],
  '年': [1, 2, 3, 5],
}

function isSameWeek(d1: Date, d2: Date) {
  const days1 = getWeekDays(d1)
  return days1.includes(localDateString(d2))
}

// ── Add Habit Modal ───────────────────────────────────────────────────
function AddHabitModal({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const supabase = createClient()
  const [name, setName] = useState('')
  const [unit, setUnit] = useState<'天' | '周' | '年'>('天')
  const [period, setPeriod] = useState('330')
  const [category, setCategory] = useState('')
  const [saving, setSaving] = useState(false)

  // Read categories from localStorage
  const BASE_CATS = ['工作', '输入', '输出', '健康', '投资', '瞎忙']
  const customCats: string[] = (() => {
    try { return JSON.parse(localStorage.getItem('hobby_custom_categories') ?? '[]') } catch { return [] }
  })()
  const hiddenCats: string[] = (() => {
    try { return JSON.parse(localStorage.getItem('hobby_hidden_categories') ?? '[]') } catch { return [] }
  })()
  const catRenames: Record<string, string> = (() => {
    try { return JSON.parse(localStorage.getItem('hobby_cat_renames') ?? '{}') } catch { return {} }
  })()
  const allCats = [...BASE_CATS, ...customCats].filter(c => !hiddenCats.includes(c))
  if (!category && allCats.length > 0) setTimeout(() => setCategory(allCats[0]), 0)

  async function handleSave() {
    if (!name.trim() || !period || !category) return
    setSaving(true)
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) { setSaving(false); return }
    const year = new Date().getFullYear()
    await supabase.from('achievements').insert({
      user_id: user.id,
      category,
      name: name.trim(),
      unit,
      target_value: parseInt(period),
      template: 'habit',
      metadata: { unit, period: parseInt(period) },
      year,
    })
    setSaving(false)
    onSaved()
    onClose()
  }

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center bg-black/40" onClick={onClose}>
      <div className="w-full max-w-lg bg-white rounded-t-3xl p-5 space-y-4 mb-16 max-h-[80vh] overflow-y-auto"
        onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold text-gray-800">新增打卡习惯</h2>
          <button onClick={onClose}><X size={18} className="text-gray-400" /></button>
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">习惯名称</label>
          <input type="text" value={name} onChange={e => setName(e.target.value)} autoFocus
            placeholder="如：早睡、健康饮食、冥想"
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">计量单位</label>
          <div className="flex gap-2">
            {(['天', '周', '年'] as const).map(u => (
              <button key={u} onClick={() => { setUnit(u); setPeriod(String(HABIT_UNIT_SUGGESTIONS[u][3] ?? HABIT_UNIT_SUGGESTIONS[u][0])) }}
                className={`flex-1 py-2 rounded-xl text-sm font-medium border transition-colors ${unit === u ? 'bg-green-500 text-white border-green-500' : 'border-gray-200 text-gray-600'}`}>
                {u}
              </button>
            ))}
          </div>
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">目标次数（{unit}）</label>
          <div className="flex flex-wrap gap-2 mb-2">
            {HABIT_UNIT_SUGGESTIONS[unit].map(v => (
              <button key={v} onClick={() => setPeriod(String(v))}
                className={`px-3 py-1 rounded-full text-sm border transition-colors ${period === String(v) ? 'bg-green-500 text-white border-green-500' : 'border-gray-200 text-gray-600'}`}>
                {v}{unit}
              </button>
            ))}
          </div>
          <input type="number" value={period} onChange={e => setPeriod(e.target.value)}
            placeholder="或自定义数字"
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">归属大类（生命树）</label>
          <select value={category} onChange={e => setCategory(e.target.value)}
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none bg-white">
            {allCats.map(c => <option key={c} value={c}>{catRenames[c] ?? c}</option>)}
          </select>
        </div>

        {name && period && (
          <div className="bg-green-50 rounded-xl px-4 py-3 text-sm text-green-700">
            目标：{name} 坚持 <strong>{period}{unit}</strong>，每次完成点 +1
          </div>
        )}

        <button onClick={handleSave} disabled={saving || !name.trim() || !period || !category}
          className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
          {saving ? '保存中...' : '添加习惯'}
        </button>
      </div>
    </div>
  )
}

type CellProps = {
  habit: Achievement
  date: string
  isToday: boolean
  isFuture: boolean
  checkedIn: boolean
  recordId: string | null
  onCheckIn: () => void
  onUndo: () => void
}

function Cell({ date, isToday, isFuture, checkedIn, onCheckIn, onUndo }: CellProps) {
  const [loading, setLoading] = useState(false)

  async function handleClick() {
    if (isFuture || loading) return
    setLoading(true)
    if (checkedIn) await onUndo()
    else await onCheckIn()
    setLoading(false)
  }

  if (isFuture) {
    return <div className="w-6 h-6 rounded-full bg-gray-50" />
  }

  return (
    <button
      onClick={handleClick}
      disabled={loading}
      className={`w-6 h-6 rounded-full flex items-center justify-center transition-all text-xs
        ${checkedIn
          ? 'bg-green-500 text-white shadow-sm'
          : isToday
            ? 'bg-white ring-2 ring-green-400 text-gray-300'
            : 'bg-gray-100 text-gray-300 hover:bg-gray-200'
        }
        ${loading ? 'opacity-50' : ''}
      `}
    >
      {checkedIn ? '✓' : ''}
    </button>
  )
}

// ── Edit Habit Modal ───────────────────────────────────────────────────
function EditHabitModal({ habit, onClose, onSaved }: {
  habit: { id: string; name: string; unit: string; target_value: number }
  onClose: () => void
  onSaved: () => void
}) {
  const supabase = createClient()
  const [name, setName] = useState(habit.name)
  const [period, setPeriod] = useState(String(habit.target_value))
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const unit = habit.unit as '天' | '周' | '年'

  async function handleSave() {
    if (!name.trim() || !period) return
    setSaving(true)
    await supabase.from('achievements').update({
      name: name.trim(),
      target_value: parseInt(period),
    }).eq('id', habit.id)
    setSaving(false)
    onSaved()
    onClose()
  }

  async function handleDelete() {
    if (!confirm(`确认删除「${habit.name}」及所有打卡记录？`)) return
    setDeleting(true)
    await supabase.from('achievements').delete().eq('id', habit.id)
    setDeleting(false)
    onSaved()
    onClose()
  }

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center bg-black/40" onClick={onClose}>
      <div className="w-full max-w-lg bg-white rounded-t-3xl p-5 space-y-4 mb-16"
        onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold text-gray-800">编辑习惯</h2>
          <button onClick={onClose}><X size={18} className="text-gray-400" /></button>
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">习惯名称</label>
          <input type="text" value={name} onChange={e => setName(e.target.value)} autoFocus
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">目标次数（{unit}）</label>
          <div className="flex flex-wrap gap-2 mb-2">
            {HABIT_UNIT_SUGGESTIONS[unit].map(v => (
              <button key={v} onClick={() => setPeriod(String(v))}
                className={`px-3 py-1 rounded-full text-sm border transition-colors ${period === String(v) ? 'bg-green-500 text-white border-green-500' : 'border-gray-200 text-gray-600'}`}>
                {v}{unit}
              </button>
            ))}
          </div>
          <input type="number" value={period} onChange={e => setPeriod(e.target.value)}
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
        </div>

        <button onClick={handleSave} disabled={saving || !name.trim() || !period}
          className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
          {saving ? '保存中...' : '保存'}
        </button>

        <button onClick={handleDelete} disabled={deleting}
          className="w-full py-2 text-xs text-red-400 hover:text-red-600 transition-colors">
          {deleting ? '删除中...' : '删除此习惯及所有记录'}
        </button>
      </div>
    </div>
  )
}

export default function WeeklyHabitGrid() {
  const currentYear = new Date().getFullYear()
  const [weekAnchor, setWeekAnchor] = useState(new Date())
  const [showAdd, setShowAdd] = useState(false)
  const [editingHabit, setEditingHabit] = useState<{ id: string; name: string; unit: string; target_value: number } | null>(null)
  const { habits, checkIns, loading, checkIn, undoCheckIn, reload } = useHabitData(currentYear)

  const weekDays = getWeekDays(weekAnchor)
  const weekStart = weekDays[0]
  const weekEnd = weekDays[6]
  const isCurrentWeek = isSameWeek(weekAnchor, new Date())

  function prevWeek() {
    const d = new Date(weekAnchor)
    d.setDate(d.getDate() - 7)
    setWeekAnchor(d)
  }
  function nextWeek() {
    const d = new Date(weekAnchor)
    d.setDate(d.getDate() + 7)
    setWeekAnchor(d)
  }

  function fmtDate(d: string) {
    const [, m, day] = d.split('-')
    return `${parseInt(m)}/${parseInt(day)}`
  }

  if (loading) return null

  const checkInMap: Record<string, Record<string, string>> = {}
  for (const c of checkIns) {
    if (!checkInMap[c.achievement_id]) checkInMap[c.achievement_id] = {}
    checkInMap[c.achievement_id][c.date] = c.id
  }

  const totalCells = habits.length * weekDays.filter(d => d <= TODAY).length
  const doneCells = habits.reduce((sum, h) =>
    sum + weekDays.filter(d => d <= TODAY && checkInMap[h.id]?.[d]).length, 0)

  return (
    <>
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden mb-3">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-50">
          <div>
            <span className="text-sm font-semibold text-gray-700">本周打卡</span>
            <span className="text-xs text-gray-400 ml-2">{fmtDate(weekStart)} – {fmtDate(weekEnd)}</span>
          </div>
          <div className="flex items-center gap-2">
            {totalCells > 0 && (
              <span className="text-xs font-medium text-green-600">{doneCells}/{totalCells}</span>
            )}
            {habits.length > 0 && (
              <>
                <button onClick={prevWeek} className="p-1 text-gray-400 hover:text-gray-600">
                  <ChevronLeft size={15} />
                </button>
                <button onClick={nextWeek} disabled={isCurrentWeek} className="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30">
                  <ChevronRight size={15} />
                </button>
              </>
            )}
            <button onClick={() => setShowAdd(true)}
              className="p-1 text-green-500 hover:text-green-600 transition-colors">
              <Plus size={16} />
            </button>
          </div>
        </div>

        {habits.length === 0 ? (
          <div className="px-4 py-6 text-center">
            <p className="text-xs text-gray-300 mb-2">还没有打卡习惯</p>
            <button onClick={() => setShowAdd(true)}
              className="text-xs text-green-500 hover:text-green-600 font-medium">
              + 添加第一个习惯
            </button>
          </div>
        ) : (
          <>
            <div className="px-3 py-2 overflow-x-auto">
              <table className="w-full" style={{ minWidth: 260 }}>
                <thead>
                  <tr>
                    <th className="text-left pb-1.5 pr-2 w-16" />
                    {weekDays.map((d, i) => {
                      const isToday = d === TODAY
                      return (
                        <th key={d} className="pb-1.5 px-0.5" style={{ width: 30 }}>
                          <div className="flex flex-col items-center gap-0.5">
                            <span className={`text-xs leading-none ${isToday ? 'text-green-500 font-semibold' : 'text-gray-400'}`}>
                              {DAY_LABELS[i]}
                            </span>
                            <span className={`text-xs leading-none ${isToday ? 'text-green-500 font-bold' : 'text-gray-300'}`}>
                              {parseInt(d.split('-')[2])}
                            </span>
                          </div>
                        </th>
                      )
                    })}
                    <th className="pb-1.5 pl-1 w-8" />
                  </tr>
                </thead>
                <tbody>
                  {habits.map(habit => {
                    const weekChecked = weekDays.filter(d => checkInMap[habit.id]?.[d]).length
                    const weekTotal = weekDays.filter(d => d <= TODAY).length
                    return (
                      <tr key={habit.id}>
                        <td className="pr-2 py-1">
                          <div className="flex items-center gap-1 group">
                            <span className="text-xs text-gray-600 truncate" style={{ maxWidth: 48 }}>
                              {habit.name}
                            </span>
                            <button
                              onClick={() => setEditingHabit({ id: habit.id, name: habit.name, unit: habit.unit, target_value: habit.target_value })}
                              className="text-gray-200 hover:text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
                            >
                              <Pencil size={10} />
                            </button>
                          </div>
                        </td>
                        {weekDays.map(d => {
                          const isFuture = d > TODAY
                          const recordId = checkInMap[habit.id]?.[d] ?? null
                          return (
                            <td key={d} className="px-0.5 py-1">
                              <div className="flex items-center justify-center">
                                <Cell
                                  habit={habit} date={d} isToday={d === TODAY}
                                  isFuture={isFuture} checkedIn={!!recordId} recordId={recordId}
                                  onCheckIn={() => checkIn(habit.id, d)}
                                  onUndo={() => undoCheckIn(recordId!)}
                                />
                              </div>
                            </td>
                          )
                        })}
                        <td className="pl-1 py-1">
                          <span className="text-xs text-gray-300 whitespace-nowrap">
                            {weekChecked}/{weekTotal}
                          </span>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>

            <div className="px-4 pb-3 space-y-1.5 border-t border-gray-50 pt-2">
              {habits.map(habit => (
                <div key={habit.id} className="flex items-center gap-2">
                  <span className="text-xs text-gray-400 w-14 truncate">{habit.name}</span>
                  <div className="flex-1 h-1 bg-gray-100 rounded-full overflow-hidden">
                    <div className="h-full bg-green-400 rounded-full transition-all"
                      style={{ width: `${Math.min(100, habit.progress * 100)}%` }} />
                  </div>
                  <span className="text-xs text-gray-300 w-16 text-right">
                    {habit.current_value}/{habit.target_value}{habit.unit}
                  </span>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {showAdd && (
        <AddHabitModal onClose={() => setShowAdd(false)} onSaved={reload} />
      )}
      {editingHabit && (
        <EditHabitModal habit={editingHabit} onClose={() => setEditingHabit(null)} onSaved={reload} />
      )}
    </>
  )
}
