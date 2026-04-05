'use client'

import { useState, useRef, useEffect } from 'react'
import { ChevronDown, ChevronRight, Pencil, Check, Plus, X } from 'lucide-react'
import { useHobbyStats } from './calendar/useHobbyStats'

const BASE_CATEGORIES = ['工作', '输入', '输出', '健康', '投资', '瞎忙'] as const

const COLOR_PRESETS = [
  '#EF4444', '#F97316', '#F59E0B', '#84CC16',
  '#10B981', '#14B8A6', '#3B82F6', '#6366F1',
  '#8B5CF6', '#EC4899', '#F43F5E', '#0EA5E9',
]

function formatMinutes(m: number): string {
  if (m === 0) return '0 分钟'
  if (m < 60) return `${m} 分钟`
  const h = Math.floor(m / 60)
  const min = m % 60
  if (min === 0) return `${h} 小时`
  return `${h} 小时 ${min} 分钟`
}

type CustomHobby = { label: string; color: string }
type PendingDelete = {
  label: string
  customData?: CustomHobby   // present if it was a custom hobby
  deletedAt: number
}

function loadCustomCategories(): string[] {
  try { return JSON.parse(localStorage.getItem('hobby_custom_categories') ?? '[]') } catch { return [] }
}
function saveCustomCategories(cats: string[]) {
  localStorage.setItem('hobby_custom_categories', JSON.stringify(cats))
}
function loadCustomHobbies(): CustomHobby[] {
  try { return JSON.parse(localStorage.getItem('hobby_custom_hobbies') ?? '[]') } catch { return [] }
}
function saveCustomHobbies(hobbies: CustomHobby[]) {
  localStorage.setItem('hobby_custom_hobbies', JSON.stringify(hobbies))
}
function loadHiddenHobbies(): string[] {
  try { return JSON.parse(localStorage.getItem('hobby_hidden') ?? '[]') } catch { return [] }
}
function saveHiddenHobbies(hidden: string[]) {
  localStorage.setItem('hobby_hidden', JSON.stringify(hidden))
}

export default function HobbiesView() {
  const [customCats, setCustomCats] = useState<string[]>([])
  const [customHobbies, setCustomHobbies] = useState<CustomHobby[]>([])
  const [hiddenHobbies, setHiddenHobbies] = useState<string[]>([])

  useEffect(() => {
    setCustomCats(loadCustomCategories())
    setCustomHobbies(loadCustomHobbies())
    setHiddenHobbies(loadHiddenHobbies())
  }, [])

  const { stats, loading, updateHistorical, updateCategory } = useHobbyStats(customHobbies, hiddenHobbies)

  const allCategories = [...BASE_CATEGORIES, ...customCats]

  const [editing, setEditing] = useState<string | null>(null)
  const [inputVal, setInputVal] = useState('')
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({})
  const [dragOver, setDragOver] = useState<string | null>(null)
  const draggedHobby = useRef<string | null>(null)

  const [addingCat, setAddingCat] = useState(false)
  const [newCatName, setNewCatName] = useState('')

  const [addingHobby, setAddingHobby] = useState(false)
  const [newHobbyName, setNewHobbyName] = useState('')
  const [newHobbyColor, setNewHobbyColor] = useState(COLOR_PRESETS[0])
  const [newHobbyCategory, setNewHobbyCategory] = useState(allCategories[0] ?? '')

  const [pendingCategory, setPendingCategory] = useState<{ hobby: string; cat: string } | null>(null)
  useEffect(() => {
    if (!pendingCategory) return
    updateCategory(pendingCategory.hobby, pendingCategory.cat)
    setPendingCategory(null)
  }, [customHobbies]) // eslint-disable-line react-hooks/exhaustive-deps

  // Undo delete state
  const [pendingDelete, setPendingDelete] = useState<PendingDelete | null>(null)
  // Auto-expire undo window after 5 minutes
  useEffect(() => {
    if (!pendingDelete) return
    const remaining = 5 * 60 * 1000 - (Date.now() - pendingDelete.deletedAt)
    if (remaining <= 0) { setPendingDelete(null); return }
    const t = setTimeout(() => setPendingDelete(null), remaining)
    return () => clearTimeout(t)
  }, [pendingDelete])

  const grouped = Object.fromEntries(
    allCategories.map(cat => [cat, stats.filter(s => s.category === cat)])
  ) as Record<string, typeof stats>

  const leftover = stats.filter(s => !allCategories.includes(s.category))

  function catTotal(cat: string) {
    return (grouped[cat] ?? []).reduce((sum, s) => sum + s.totalMinutes, 0)
  }

  function confirmAddCategory() {
    const name = newCatName.trim()
    if (!name || allCategories.includes(name)) { setAddingCat(false); setNewCatName(''); return }
    const updated = [...customCats, name]
    setCustomCats(updated)
    saveCustomCategories(updated)
    setAddingCat(false)
    setNewCatName('')
  }

  function removeCategory(cat: string) {
    const updated = customCats.filter(c => c !== cat)
    setCustomCats(updated)
    saveCustomCategories(updated)
  }

  function confirmAddHobby() {
    const name = newHobbyName.trim()
    if (!name) { setAddingHobby(false); return }
    const updated = [...customHobbies, { label: name, color: newHobbyColor }]
    setCustomHobbies(updated)
    saveCustomHobbies(updated)
    if (newHobbyCategory) setPendingCategory({ hobby: name, cat: newHobbyCategory })
    setAddingHobby(false)
    setNewHobbyName('')
    setNewHobbyColor(COLOR_PRESETS[0])
  }

  function deleteHobby(label: string) {
    const customData = customHobbies.find(h => h.label === label)

    // Remove from custom list if it's a custom hobby
    if (customData) {
      const updatedCustom = customHobbies.filter(h => h.label !== label)
      setCustomHobbies(updatedCustom)
      saveCustomHobbies(updatedCustom)
    }

    // Hide it (works for both built-in and custom)
    const updatedHidden = [...hiddenHobbies, label]
    setHiddenHobbies(updatedHidden)
    saveHiddenHobbies(updatedHidden)

    setPendingDelete({ label, customData, deletedAt: Date.now() })
  }

  function undoDelete() {
    if (!pendingDelete) return
    // Unhide
    const updatedHidden = hiddenHobbies.filter(l => l !== pendingDelete.label)
    setHiddenHobbies(updatedHidden)
    saveHiddenHobbies(updatedHidden)
    // Restore custom hobby if needed
    if (pendingDelete.customData) {
      const updatedCustom = [...customHobbies, pendingDelete.customData]
      setCustomHobbies(updatedCustom)
      saveCustomHobbies(updatedCustom)
    }
    setPendingDelete(null)
  }

  function startEdit(label: string, currentMinutes: number) {
    setEditing(label)
    setInputVal(currentMinutes === 0 ? '' : String(Math.round(currentMinutes / 60 * 10) / 10))
  }

  async function saveEdit(label: string) {
    await updateHistorical(label, Math.round((parseFloat(inputVal) || 0) * 60))
    setEditing(null)
  }

  function onDragStart(hobby: string) { draggedHobby.current = hobby }
  function onDragOver(e: React.DragEvent, cat: string) { e.preventDefault(); setDragOver(cat) }
  async function onDrop(cat: string) {
    setDragOver(null)
    if (!draggedHobby.current) return
    await updateCategory(draggedHobby.current, cat)
    draggedHobby.current = null
  }

  if (loading) return <div className="flex items-center justify-center flex-1 text-gray-400 text-sm">加载中...</div>

  const renderHobbyCard = (s: typeof stats[number]) => (
    <div
      key={s.label}
      draggable
      onDragStart={() => onDragStart(s.label)}
      className="bg-gray-50 rounded-xl p-3 cursor-grab active:cursor-grabbing select-none"
    >
      <div className="flex items-center justify-between mb-1.5">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: s.color }} />
          <span className="text-sm font-medium text-gray-700">{s.label}</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm font-semibold" style={{ color: s.color }}>{formatMinutes(s.totalMinutes)}</span>
          <button
            onClick={e => { e.stopPropagation(); deleteHobby(s.label) }}
            className="text-gray-300 hover:text-red-400 cursor-pointer"
          >
            <X size={13} />
          </button>
        </div>
      </div>
      <div className="flex items-center gap-2 text-xs text-gray-400">
        <span>日历 {formatMinutes(s.calendarMinutes)}</span>
        <span>·</span>
        {editing === s.label ? (
          <span className="flex items-center gap-1">
            历史
            <input
              type="number" min="0" step="0.5" value={inputVal}
              onChange={e => setInputVal(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && saveEdit(s.label)}
              className="w-14 px-1.5 py-0.5 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-blue-400"
              autoFocus
            />
            小时
            <button onClick={() => saveEdit(s.label)} className="text-blue-500"><Check size={12} /></button>
          </span>
        ) : (
          <span className="flex items-center gap-1">
            历史 {formatMinutes(s.historicalMinutes)}
            <button onClick={() => startEdit(s.label, s.historicalMinutes)} className="ml-0.5 text-gray-300 hover:text-gray-500">
              <Pencil size={10} />
            </button>
          </span>
        )}
      </div>
    </div>
  )

  return (
    <div className="flex-1 overflow-y-auto px-4 py-3 space-y-2 pb-32">

      {/* 大类列表 */}
      {allCategories.map((cat) => {
        const hobbies = grouped[cat] ?? []
        const isCollapsed = collapsed[cat] === true
        const isOver = dragOver === cat
        const isCustom = customCats.includes(cat)

        return (
          <div
            key={cat}
            onDragOver={e => onDragOver(e, cat)}
            onDragLeave={() => setDragOver(null)}
            onDrop={() => onDrop(cat)}
            className={`rounded-2xl border shadow-sm transition-colors ${isOver ? 'border-blue-400 bg-blue-50' : 'border-gray-100 bg-white'}`}
          >
            <button
              className="w-full flex items-center justify-between px-4 py-3"
              onClick={() => setCollapsed(prev => ({ ...prev, [cat]: !prev[cat] }))}
            >
              <div className="flex items-center gap-2">
                {isCollapsed ? <ChevronRight size={15} className="text-gray-400" /> : <ChevronDown size={15} className="text-gray-400" />}
                <span className="font-medium text-gray-700 text-sm">{cat}</span>
                <span className="text-xs text-gray-300">{hobbies.length} 项</span>
              </div>
              <div className="flex items-center gap-2">
                {catTotal(cat) > 0 && <span className="text-xs font-medium text-gray-400">{formatMinutes(catTotal(cat))}</span>}
                {isCustom && (
                  <button
                    onClick={e => { e.stopPropagation(); removeCategory(cat) }}
                    className="text-gray-300 hover:text-red-400"
                  >
                    <X size={13} />
                  </button>
                )}
              </div>
            </button>
            {!isCollapsed && (
              <div className="px-3 pb-3 space-y-2">
                {hobbies.length === 0 && <p className="text-xs text-gray-300 text-center py-3">拖拽爱好到此分类</p>}
                {hobbies.map(renderHobbyCard)}
              </div>
            )}
          </div>
        )
      })}

      {/* 待归类 */}
      {leftover.length > 0 && (
        <div
          onDragOver={e => onDragOver(e, '未分类')}
          onDragLeave={() => setDragOver(null)}
          onDrop={() => onDrop('未分类')}
          className={`rounded-2xl border shadow-sm transition-colors ${dragOver === '未分类' ? 'border-blue-400 bg-blue-50' : 'border-dashed border-gray-200 bg-gray-50'}`}
        >
          <div className="px-4 py-2.5 flex items-center gap-2">
            <span className="text-xs text-gray-400 font-medium">待归类</span>
            <span className="text-xs text-gray-300">{leftover.length} 项</span>
          </div>
          <div className="px-3 pb-3 space-y-2">{leftover.map(renderHobbyCard)}</div>
        </div>
      )}

      {/* 添加大类 */}
      {addingCat ? (
        <div className="flex items-center gap-2 px-1">
          <input
            type="text"
            value={newCatName}
            onChange={e => setNewCatName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && confirmAddCategory()}
            placeholder="大类名称"
            className="flex-1 px-3 py-2 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-blue-400"
            autoFocus
          />
          <button onClick={confirmAddCategory} className="px-3 py-2 bg-blue-600 text-white rounded-xl text-sm">确定</button>
          <button onClick={() => { setAddingCat(false); setNewCatName('') }} className="p-2 text-gray-400"><X size={16} /></button>
        </div>
      ) : null}

      {/* 添加小项表单 */}
      {addingHobby ? (
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4 space-y-3">
          <p className="text-sm font-medium text-gray-700">添加爱好</p>
          <input
            type="text"
            value={newHobbyName}
            onChange={e => setNewHobbyName(e.target.value)}
            placeholder="爱好名称"
            className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-blue-400"
            autoFocus
          />
          <div>
            <p className="text-xs text-gray-400 mb-1.5">颜色</p>
            <div className="flex flex-wrap gap-2">
              {COLOR_PRESETS.map(c => (
                <button
                  key={c}
                  onClick={() => setNewHobbyColor(c)}
                  className={`w-7 h-7 rounded-full transition-transform ${newHobbyColor === c ? 'scale-125 ring-2 ring-offset-1 ring-gray-400' : ''}`}
                  style={{ backgroundColor: c }}
                />
              ))}
            </div>
          </div>
          <div>
            <p className="text-xs text-gray-400 mb-1.5">归入大类</p>
            <select
              value={newHobbyCategory}
              onChange={e => setNewHobbyCategory(e.target.value)}
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none bg-white"
            >
              {allCategories.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>
          <div className="flex gap-2">
            <button onClick={confirmAddHobby} className="flex-1 py-2 bg-blue-600 text-white rounded-xl text-sm font-medium">添加</button>
            <button onClick={() => setAddingHobby(false)} className="px-4 py-2 text-gray-400 rounded-xl text-sm">取消</button>
          </div>
        </div>
      ) : null}

      {/* 底部按钮 */}
      {!addingCat && !addingHobby && (
        <div className="flex gap-3 pt-1">
          <button
            onClick={() => setAddingCat(true)}
            className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-2xl border border-dashed border-gray-300 text-sm text-gray-400 hover:border-blue-400 hover:text-blue-500 transition-colors"
          >
            <Plus size={15} /> 添加大类
          </button>
          <button
            onClick={() => { setAddingHobby(true); setNewHobbyCategory(allCategories[0] ?? '') }}
            className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-2xl border border-dashed border-gray-300 text-sm text-gray-400 hover:border-blue-400 hover:text-blue-500 transition-colors"
          >
            <Plus size={15} /> 添加小项
          </button>
        </div>
      )}

      {/* 撤销删除提示 */}
      {pendingDelete && (
        <div className="flex items-center justify-between px-4 py-3 bg-gray-800 text-white rounded-2xl text-sm">
          <span className="text-gray-300">已删除「<span className="text-white font-medium">{pendingDelete.label}</span>」</span>
          <button
            onClick={undoDelete}
            className="text-blue-300 font-medium ml-4 shrink-0"
          >
            撤销
          </button>
        </div>
      )}
    </div>
  )
}
