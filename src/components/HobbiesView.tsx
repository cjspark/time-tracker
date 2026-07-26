'use client'

import { useState, useRef, useEffect } from 'react'
import { createPortal } from 'react-dom'
import { ChevronDown, ChevronRight, Pencil, Check, Plus, X, PauseCircle, PlayCircle } from 'lucide-react'
import { useHobbyStats } from './calendar/useHobbyStats'
import WeeklyHabitGrid from './tree/WeeklyHabitGrid'
import { getPref, setPref } from '@/lib/prefs'

const BASE_CATEGORIES = ['工作', '输入', '输出', '健康', '投资', '瞎忙'] as const

export type TimeCategory = 'productive' | 'consuming' | 'enjoyable' | 'unconscious'

export const TIME_CATEGORIES: { key: TimeCategory; label: string; color: string }[] = [
  { key: 'productive',   label: '生产时间', color: '#8B5CF6' },
  { key: 'consuming',    label: '消耗时间', color: '#F97316' },
  { key: 'enjoyable',    label: '享受时间', color: '#10B981' },
  { key: 'unconscious',  label: '无意识',   color: '#3B82F6' },
]

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
type PendingDelete = { label: string; customData?: CustomHobby; deletedAt: number }

function ls<T>(key: string, fallback: T): T {
  try { return JSON.parse(localStorage.getItem(key) ?? 'null') ?? fallback } catch { return fallback }
}
function lsSave(key: string, val: unknown) {
  setPref(key, val)
}

export default function HobbiesView() {
  const [customCats, setCustomCats] = useState<string[]>([])
  const [customHobbies, setCustomHobbies] = useState<CustomHobby[]>([])
  const [hiddenHobbies, setHiddenHobbies] = useState<string[]>([])
  const [hiddenCategories, setHiddenCategories] = useState<string[]>([])
  // display-name overrides: original_key → display_name
  const [catRenames, setCatRenames] = useState<Record<string, string>>({})
  // color overrides for any hobby
  const [colorOverrides, setColorOverrides] = useState<Record<string, string>>({})
  const [hobbyRenames, setHobbyRenames] = useState<Record<string, string>>({})
  const [inactiveHobbies, setInactiveHobbies] = useState<string[]>([])
  const [inactiveExpanded, setInactiveExpanded] = useState(false)
  const [catOrder, setCatOrder] = useState<string[]>([])
  const [timeCategoryMap, setTimeCategoryMap] = useState<Record<string, TimeCategory>>({})
  const draggedCat = useRef<string | null>(null)

  useEffect(() => {
    async function loadPrefs() {
      const [
        customCatsVal, customHobbiesVal, hiddenHobbiesVal, hiddenCatsVal,
        catRenamesVal, colorOverridesVal, hobbyRenamesVal, inactiveVal,
        catOrderVal, timeCatVal,
      ] = await Promise.all([
        getPref('hobby_custom_categories', [] as string[]),
        getPref('hobby_custom_hobbies', [] as {label:string;color:string}[]),
        getPref('hobby_hidden', [] as string[]),
        getPref('hobby_hidden_categories', [] as string[]),
        getPref('hobby_cat_renames', {} as Record<string,string>),
        getPref('hobby_color_overrides', {} as Record<string,string>),
        getPref('hobby_label_renames', {} as Record<string,string>),
        getPref('hobby_inactive', [] as string[]),
        getPref('hobby_cat_order', [] as string[]),
        getPref('hobby_time_category', {} as Record<string,TimeCategory>),
      ])
      setCustomCats(customCatsVal)
      setCustomHobbies(customHobbiesVal)
      setHiddenHobbies(hiddenHobbiesVal)
      setHiddenCategories(hiddenCatsVal)
      setCatRenames(catRenamesVal)
      setColorOverrides(colorOverridesVal)
      setHobbyRenames(hobbyRenamesVal)
      setInactiveHobbies(inactiveVal)
      setCatOrder(catOrderVal)
      setTimeCategoryMap(timeCatVal)
    }
    loadPrefs()
  }, [])

  const { stats, loading, updateHistorical, updateCategory } = useHobbyStats(customHobbies, hiddenHobbies)

  // Apply color overrides, label renames, and time category colors to stats
  const statsWithColors = stats.map(s => {
    const timecat = timeCategoryMap[s.label]
    const timecatColor = timecat
      ? TIME_CATEGORIES.find(t => t.key === timecat)?.color
      : undefined
    return {
      ...s,
      color: timecatColor ?? colorOverrides[s.label] ?? s.color,
      displayLabel: hobbyRenames[s.label] ?? s.label,
      timeCategory: timecat ?? null,
    }
  })

  // Build ordered category list respecting saved order
  const rawCatKeys = [...BASE_CATEGORIES, ...customCats].filter(c => !hiddenCategories.includes(c))
  const allCatKeys = [
    ...catOrder.filter(c => rawCatKeys.includes(c)),
    ...rawCatKeys.filter(c => !catOrder.includes(c)),
  ]

  // ── category editing ──────────────────────────────────────────────
  const [editingCat, setEditingCat] = useState<string | null>(null)
  const [editingCatVal, setEditingCatVal] = useState('')

  function startEditCat(e: React.MouseEvent, key: string) {
    e.stopPropagation()
    setEditingCat(key)
    setEditingCatVal(catRenames[key] ?? key)
  }

  function saveEditCat(key: string) {
    const val = editingCatVal.trim()
    if (val && val !== key) {
      const updated = { ...catRenames, [key]: val }
      setCatRenames(updated)
      lsSave('hobby_cat_renames', updated)
    }
    setEditingCat(null)
  }

  // ── hobby editing ─────────────────────────────────────────────────
  const [editingHobby, setEditingHobby] = useState<string | null>(null)
  const [editHobbyName, setEditHobbyName] = useState('')
  const [editHobbyColor, setEditHobbyColor] = useState('')
  const [editTimeCategory, setEditTimeCategory] = useState<TimeCategory | null>(null)

  function openEditHobby(e: React.MouseEvent, label: string, color: string) {
    e.stopPropagation()
    setEditingHobby(label)
    setEditHobbyName(hobbyRenames[label] ?? label)
    setEditHobbyColor(colorOverrides[label] ?? color)
    setEditTimeCategory(timeCategoryMap[label] ?? null as unknown as TimeCategory)
  }

  function saveEditHobby(originalLabel: string) {
    const newName = editHobbyName.trim() || originalLabel

    // Save color override only if no time category is set
    if (!editTimeCategory) {
      const updatedColors = { ...colorOverrides, [originalLabel]: editHobbyColor }
      setColorOverrides(updatedColors)
      lsSave('hobby_color_overrides', updatedColors)
    }

    // Save time category
    if (editTimeCategory) {
      const updatedTimeCategory = { ...timeCategoryMap, [originalLabel]: editTimeCategory }
      setTimeCategoryMap(updatedTimeCategory)
      lsSave('hobby_time_category', updatedTimeCategory)
    } else {
      // Remove time category if none selected
      const updatedTimeCategory = { ...timeCategoryMap }
      delete updatedTimeCategory[originalLabel]
      setTimeCategoryMap(updatedTimeCategory)
      lsSave('hobby_time_category', updatedTimeCategory)
    }

    // Handle rename
    if (newName !== originalLabel) {
      const isCustom = customHobbies.some(h => h.label === originalLabel)
      if (isCustom) {
        // Custom hobby: rename in the customHobbies list
        const updatedCustom = customHobbies.map(h =>
          h.label === originalLabel ? { label: newName, color: editHobbyColor } : h
        )
        setCustomHobbies(updatedCustom)
        lsSave('hobby_custom_hobbies', updatedCustom)
      } else {
        // Built-in hobby: store display name override
        const updatedRenames = { ...hobbyRenames, [originalLabel]: newName }
        setHobbyRenames(updatedRenames)
        lsSave('hobby_label_renames', updatedRenames)
      }
    } else if (customHobbies.some(h => h.label === originalLabel)) {
      // No rename, just update color in customHobbies
      const updatedCustom = customHobbies.map(h =>
        h.label === originalLabel ? { ...h, color: editHobbyColor } : h
      )
      setCustomHobbies(updatedCustom)
      lsSave('hobby_custom_hobbies', updatedCustom)
    }

    setEditingHobby(null)
  }

  // ── misc state ────────────────────────────────────────────────────
  const [editing, setEditing] = useState<string | null>(null)
  const [inputVal, setInputVal] = useState('')
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({})
  const [dragOver, setDragOver] = useState<string | null>(null)
  // cat insert indicator: { cat: string, position: 'before' | 'after' }
  const [catInsert, setCatInsert] = useState<{ cat: string; position: 'before' | 'after' } | null>(null)
  const draggedHobby = useRef<string | null>(null)
  const [addingCat, setAddingCat] = useState(false)
  const [newCatName, setNewCatName] = useState('')
  const [addingHobby, setAddingHobby] = useState(false)
  const [newHobbyName, setNewHobbyName] = useState('')
  const [newHobbyColor, setNewHobbyColor] = useState(COLOR_PRESETS[0])
  const [newHobbyTimeCategory, setNewHobbyTimeCategory] = useState<TimeCategory | null>(null)
  const [newHobbyCategory, setNewHobbyCategory] = useState(allCatKeys[0] ?? '')
  const [pendingCategory, setPendingCategory] = useState<{ hobby: string; cat: string } | null>(null)
  const [pendingDelete, setPendingDelete] = useState<PendingDelete | null>(null)

  useEffect(() => {
    if (!pendingCategory) return
    updateCategory(pendingCategory.hobby, pendingCategory.cat)
    setPendingCategory(null)
  }, [customHobbies]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!pendingDelete) return
    const remaining = 5 * 60 * 1000 - (Date.now() - pendingDelete.deletedAt)
    if (remaining <= 0) { setPendingDelete(null); return }
    const t = setTimeout(() => setPendingDelete(null), remaining)
    return () => clearTimeout(t)
  }, [pendingDelete])

  const grouped = Object.fromEntries(
    allCatKeys.map(cat => [cat, statsWithColors.filter(s => s.category === cat)])
  ) as Record<string, typeof statsWithColors>

  const leftover = statsWithColors.filter(s => !allCatKeys.includes(s.category))

  function catTotal(cat: string) {
    return (grouped[cat] ?? []).reduce((sum, s) => sum + s.totalMinutes, 0)
  }

  function removeCategory(cat: string) {
    if (customCats.includes(cat)) {
      const updated = customCats.filter(c => c !== cat)
      setCustomCats(updated); lsSave('hobby_custom_categories', updated)
    } else {
      const updated = [...hiddenCategories, cat]
      setHiddenCategories(updated); lsSave('hobby_hidden_categories', updated)
    }
  }

  function confirmAddCategory() {
    const name = newCatName.trim()
    if (!name || allCatKeys.includes(name)) { setAddingCat(false); setNewCatName(''); return }
    const updated = [...customCats, name]
    setCustomCats(updated); lsSave('hobby_custom_categories', updated)
    setAddingCat(false); setNewCatName('')
  }

  function confirmAddHobby() {
    const name = newHobbyName.trim()
    if (!name) { setAddingHobby(false); return }
    const updated = [...customHobbies, { label: name, color: newHobbyColor }]
    setCustomHobbies(updated); lsSave('hobby_custom_hobbies', updated)
    if (newHobbyCategory) setPendingCategory({ hobby: name, cat: newHobbyCategory })
    if (newHobbyTimeCategory) {
      const updatedTC = { ...timeCategoryMap, [name]: newHobbyTimeCategory }
      setTimeCategoryMap(updatedTC); lsSave('hobby_time_category', updatedTC)
    }
    setAddingHobby(false); setNewHobbyName(''); setNewHobbyColor(COLOR_PRESETS[0]); setNewHobbyTimeCategory(null)
  }

  function toggleInactive(label: string) {
    const isInactive = inactiveHobbies.includes(label)
    const updated = isInactive
      ? inactiveHobbies.filter(l => l !== label)
      : [...inactiveHobbies, label]
    setInactiveHobbies(updated)
    lsSave('hobby_inactive', updated)
  }

  function deleteHobby(label: string) {
    const customData = customHobbies.find(h => h.label === label)
    if (customData) {
      const updated = customHobbies.filter(h => h.label !== label)
      setCustomHobbies(updated); lsSave('hobby_custom_hobbies', updated)
    }
    const updatedHidden = [...hiddenHobbies, label]
    setHiddenHobbies(updatedHidden); lsSave('hobby_hidden', updatedHidden)
    setPendingDelete({ label, customData, deletedAt: Date.now() })
  }

  function undoDelete() {
    if (!pendingDelete) return
    const updatedHidden = hiddenHobbies.filter(l => l !== pendingDelete.label)
    setHiddenHobbies(updatedHidden); lsSave('hobby_hidden', updatedHidden)
    if (pendingDelete.customData) {
      const updatedCustom = [...customHobbies, pendingDelete.customData]
      setCustomHobbies(updatedCustom); lsSave('hobby_custom_hobbies', updatedCustom)
    }
    setPendingDelete(null)
  }

  function startEdit(label: string, currentMinutes: number) {
    setEditing(label)
    setInputVal('')  // always start empty — first time sets, subsequent times adds
  }

  async function saveEdit(label: string, currentMinutes: number) {
    const addHours = parseFloat(inputVal)
    if (isNaN(addHours) || addHours === 0) { setEditing(null); return }
    const addMinutes = Math.round(addHours * 60)
    const newTotal = currentMinutes === 0 ? addMinutes : Math.max(0, currentMinutes + addMinutes)
    await updateHistorical(label, newTotal)
    setEditing(null)
  }

  function onDragStart(hobby: string) { draggedHobby.current = hobby }
  function onDragStartCat(cat: string) { draggedCat.current = cat }
  function onDragOverCat(e: React.DragEvent, cat: string) {
    e.preventDefault()
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
    const mid = rect.top + rect.height / 2
    setCatInsert({ cat, position: e.clientY < mid ? 'before' : 'after' })
  }
  function onDropCat(targetCat: string) {
    if (!draggedCat.current || draggedCat.current === targetCat) {
      setCatInsert(null); draggedCat.current = null; return
    }
    const from = draggedCat.current
    const pos = catInsert?.position ?? 'after'
    const newOrder = [...allCatKeys].filter(c => c !== from)
    const toIdx = newOrder.indexOf(targetCat)
    newOrder.splice(pos === 'before' ? toIdx : toIdx + 1, 0, from)
    setCatOrder(newOrder)
    lsSave('hobby_cat_order', newOrder)
    setCatInsert(null)
    draggedCat.current = null
  }
  function onDragOver(e: React.DragEvent, cat: string) { e.preventDefault(); setDragOver(cat) }
  async function onDrop(cat: string) {
    setDragOver(null)
    if (!draggedHobby.current) return
    await updateCategory(draggedHobby.current, cat)
    draggedHobby.current = null
  }

  if (loading) return <div className="flex items-center justify-center flex-1 text-gray-400 text-sm">加载中...</div>

  const isCustomHobby = (label: string) => customHobbies.some(h => h.label === label)

  const renderHobbyCard = (s: typeof statsWithColors[number], inactive = false) => (
    <div
      key={s.label}
      draggable={!inactive}
      onDragStart={() => !inactive && onDragStart(s.label)}
      className={`rounded-xl p-3 select-none ${inactive ? 'bg-gray-50/60 cursor-default' : 'bg-gray-50 cursor-grab active:cursor-grabbing'}`}
    >
      <div className="flex items-center justify-between mb-1.5">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full shrink-0"
            style={{ backgroundColor: inactive ? '#9CA3AF' : s.color }} />
          <span className={`text-sm font-medium ${inactive ? 'text-gray-400' : 'text-gray-700'}`}>{s.displayLabel}</span>
        </div>
        <div className="flex items-center gap-2">
          <span className={`text-sm font-semibold ${inactive ? 'text-gray-400' : ''}`}
            style={inactive ? undefined : { color: s.color }}>
            {formatMinutes(s.totalMinutes)}
          </span>
          {/* Active / Inactive toggle */}
          <button
            onClick={e => { e.stopPropagation(); toggleInactive(s.label) }}
            className={`cursor-pointer transition-colors ${inactive ? 'text-gray-300 hover:text-green-400' : 'text-gray-300 hover:text-orange-400'}`}
            title={inactive ? '激活' : '封存'}
          >
            {inactive ? <PlayCircle size={13} /> : <PauseCircle size={13} />}
          </button>
          {!inactive && (
            <button onClick={e => openEditHobby(e, s.label, s.color)} className="text-gray-300 hover:text-blue-400 cursor-pointer">
              <Pencil size={12} />
            </button>
          )}
          <button onClick={e => { e.stopPropagation(); deleteHobby(s.label) }} className="text-gray-300 hover:text-red-400 cursor-pointer">
            <X size={13} />
          </button>
        </div>
      </div>
      <div className={`flex items-center gap-2 text-xs ${inactive ? 'text-gray-300' : 'text-gray-400'}`}>
        <span>日历 {formatMinutes(s.calendarMinutes)}</span>
        <span>·</span>
        {!inactive && editing === s.label ? (
          <span className="flex items-center gap-1">
            {s.historicalMinutes > 0 ? '+' : '历史'}
            <input
              type="number" step="0.5" value={inputVal}
              onChange={e => setInputVal(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && saveEdit(s.label, s.historicalMinutes)}
              className="w-14 px-1.5 py-0.5 border border-gray-300 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-blue-400"
              autoFocus
            />
            小时
            <button onClick={() => saveEdit(s.label, s.historicalMinutes)} className="text-blue-500"><Check size={12} /></button>
          </span>
        ) : (
          <span className="flex items-center gap-1">
            历史 {formatMinutes(s.historicalMinutes)}
            {!inactive && (
              <button
                onClick={() => startEdit(s.label, s.historicalMinutes)}
                className="ml-0.5 text-gray-300 hover:text-gray-500"
                title={s.historicalMinutes > 0 ? '追加时间' : '设定历史时间'}
              >
                {s.historicalMinutes > 0 ? <Plus size={10} /> : <Pencil size={10} />}
              </button>
            )}
          </span>
        )}
      </div>
    </div>
  )

  return (
    <div className="flex-1 overflow-y-auto px-4 py-3 space-y-2 pb-32">

      {/* Weekly habit check-in grid */}
      <WeeklyHabitGrid />

      {allCatKeys.map((catKey) => {
        const displayName = catRenames[catKey] ?? catKey
        const hobbies = grouped[catKey] ?? []
        const isCollapsed = collapsed[catKey] === true
        const isOver = dragOver === catKey

        return (
          <div key={catKey} className="relative">
            {/* Insert line: before */}
            {catInsert?.cat === catKey && catInsert.position === 'before' && (
              <div className="absolute -top-1 left-2 right-2 h-0.5 bg-blue-500 rounded-full z-10 pointer-events-none" />
            )}
            <div
              onDragOver={e => { if (draggedCat.current) { onDragOverCat(e, catKey); return; } onDragOver(e, catKey) }}
              onDragLeave={() => { setCatInsert(null); setDragOver(null) }}
              onDrop={() => { if (draggedCat.current) onDropCat(catKey); else onDrop(catKey) }}
              onDragEnd={() => { setCatInsert(null); draggedCat.current = null }}
              className={`rounded-2xl border shadow-sm transition-colors ${
                dragOver === catKey && !draggedCat.current ? 'border-blue-400 bg-blue-50' : 'border-gray-100 bg-white'
              }`}
            >
            {/* Insert line: after */}
            {catInsert?.cat === catKey && catInsert.position === 'after' && (
              <div className="absolute -bottom-1 left-2 right-2 h-0.5 bg-blue-500 rounded-full z-10 pointer-events-none" />
            )}
            <div
              className="w-full flex items-center justify-between px-4 py-3 cursor-pointer"
              draggable
              onDragStart={e => { e.stopPropagation(); onDragStartCat(catKey) }}
              onClick={() => setCollapsed(prev => ({ ...prev, [catKey]: !prev[catKey] }))}
            >
              <div className="flex items-center gap-2 flex-1 min-w-0">
                {isCollapsed ? <ChevronRight size={15} className="text-gray-400 shrink-0" /> : <ChevronDown size={15} className="text-gray-400 shrink-0" />}
                {editingCat === catKey ? (
                  <input
                    type="text"
                    value={editingCatVal}
                    onChange={e => setEditingCatVal(e.target.value)}
                    onKeyDown={e => { if (e.key === 'Enter') saveEditCat(catKey); if (e.key === 'Escape') setEditingCat(null) }}
                    onBlur={() => saveEditCat(catKey)}
                    onClick={e => e.stopPropagation()}
                    className="font-medium text-gray-700 text-sm bg-transparent border-b border-blue-400 outline-none w-28"
                    autoFocus
                  />
                ) : (
                  <>
                    <span className="font-medium text-gray-700 text-sm">{displayName}</span>
                    <span
                      onClick={e => startEditCat(e, catKey)}
                      className="text-gray-200 hover:text-blue-400 transition-colors shrink-0 cursor-pointer"
                    >
                      <Pencil size={11} />
                    </span>
                  </>
                )}
                <span className="text-xs text-gray-300">{hobbies.length} 项</span>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                {catTotal(catKey) > 0 && <span className="text-xs font-medium text-gray-400">{formatMinutes(catTotal(catKey))}</span>}
                <span
                  onClick={e => { e.stopPropagation(); removeCategory(catKey) }}
                  className="text-gray-300 hover:text-red-400 cursor-pointer"
                >
                  <X size={13} />
                </span>
              </div>
            </div>
            {!isCollapsed && (
              <div className="px-3 pb-3 space-y-2">
                {/* Active hobbies */}
                {hobbies.filter(h => !inactiveHobbies.includes(h.label)).length === 0 &&
                  <div className="text-xs text-gray-300 text-center py-8 border-2 border-dashed border-gray-100 rounded-xl">
                    拖拽活动到此分类
                  </div>}
                {hobbies.filter(h => !inactiveHobbies.includes(h.label)).map(s => renderHobbyCard(s, false))}

                {/* Inactive hobbies — collapsed strip */}
                {hobbies.some(h => inactiveHobbies.includes(h.label)) && (
                  <div className="mt-1">
                    <button
                      onClick={() => setInactiveExpanded(e => !e)}
                      className="w-full flex items-center gap-1.5 px-2 py-1.5 text-xs text-gray-300 hover:text-gray-400 transition-colors"
                    >
                      {inactiveExpanded ? <ChevronDown size={11} /> : <ChevronRight size={11} />}
                      <span>已封存 {hobbies.filter(h => inactiveHobbies.includes(h.label)).length} 项</span>
                      <div className="flex-1 h-px bg-gray-100 ml-1" />
                    </button>
                    {inactiveExpanded && (
                      <div className="space-y-2 mt-1">
                        {hobbies.filter(h => inactiveHobbies.includes(h.label)).map(s => renderHobbyCard(s, true))}
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}
            </div>
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
          <div className="px-3 pb-3 space-y-2">{leftover.map(s => renderHobbyCard(s))}</div>
        </div>
      )}

      {/* 添加大类 */}
      {addingCat && (
        <div className="flex items-center gap-2 px-1">
          <input
            type="text" value={newCatName} onChange={e => setNewCatName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && confirmAddCategory()}
            placeholder="大类名称"
            className="flex-1 px-3 py-2 border border-gray-300 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-blue-400"
            autoFocus
          />
          <button onClick={confirmAddCategory} className="px-3 py-2 bg-blue-600 text-white rounded-xl text-sm">确定</button>
          <button onClick={() => { setAddingCat(false); setNewCatName('') }} className="p-2 text-gray-400"><X size={16} /></button>
        </div>
      )}

      {/* 添加小项 */}
      {addingHobby && (
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4 space-y-3">
          <p className="text-sm font-medium text-gray-700">添加爱好</p>
          <input
            type="text" value={newHobbyName} onChange={e => setNewHobbyName(e.target.value)}
            placeholder="爱好名称"
            className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-blue-400"
            autoFocus
          />
          <div>
            <p className="text-xs text-gray-400 mb-1.5">时间类型</p>
            <div className="grid grid-cols-2 gap-2">
              {TIME_CATEGORIES.map(tc => (
                <button key={tc.key} onClick={() => setNewHobbyTimeCategory(tc.key)}
                  className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm border transition-colors ${newHobbyTimeCategory === tc.key ? 'border-transparent text-white' : 'border-gray-200 text-gray-600 bg-gray-50'}`}
                  style={newHobbyTimeCategory === tc.key ? { backgroundColor: tc.color } : undefined}>
                  <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: tc.color }} />
                  {tc.label}
                </button>
              ))}
            </div>
          </div>
          <div>
            <p className="text-xs text-gray-400 mb-1.5">归入大类</p>
            <select value={newHobbyCategory} onChange={e => setNewHobbyCategory(e.target.value)}
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none bg-white">
              {allCatKeys.map(c => <option key={c} value={c}>{catRenames[c] ?? c}</option>)}
            </select>
          </div>
          <div className="flex gap-2">
            <button onClick={confirmAddHobby} className="flex-1 py-2 bg-blue-600 text-white rounded-xl text-sm font-medium">添加</button>
            <button onClick={() => setAddingHobby(false)} className="px-4 py-2 text-gray-400 rounded-xl text-sm">取消</button>
          </div>
        </div>
      )}

      {!addingCat && !addingHobby && (
        <div className="flex gap-3 pt-1">
          <button onClick={() => setAddingCat(true)}
            className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-2xl border border-dashed border-gray-300 text-sm text-gray-400 hover:border-blue-400 hover:text-blue-500 transition-colors">
            <Plus size={15} /> 添加大类
          </button>
          <button onClick={() => { setAddingHobby(true); setNewHobbyCategory(allCatKeys[0] ?? '') }}
            className="flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-2xl border border-dashed border-gray-300 text-sm text-gray-400 hover:border-blue-400 hover:text-blue-500 transition-colors">
            <Plus size={15} /> 添加小项
          </button>
        </div>
      )}

      {pendingDelete && (
        <div className="flex items-center justify-between px-4 py-3 bg-gray-800 text-white rounded-2xl text-sm">
          <span className="text-gray-300">已删除「<span className="text-white font-medium">{pendingDelete.label}</span>」</span>
          <button onClick={undoDelete} className="text-blue-300 font-medium ml-4 shrink-0">撤销</button>
        </div>
      )}

      {/* 编辑爱好 bottom sheet — portal to body to escape overflow clipping */}
      {editingHobby && typeof document !== 'undefined' && createPortal(
        <div className="fixed inset-0 z-[200] flex items-end justify-center bg-black/40"
          onClick={() => setEditingHobby(null)}>
          <div className="w-full max-w-lg bg-white rounded-t-3xl p-5 space-y-4 mb-16 max-h-[70vh] overflow-y-auto"
            onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-base font-semibold text-gray-800">编辑爱好</h2>
              <button onClick={() => setEditingHobby(null)}><X size={18} className="text-gray-400" /></button>
            </div>
            <div>
              <label className="text-xs text-gray-500 mb-1 block">名称</label>
              <input
                type="text" value={editHobbyName} onChange={e => setEditHobbyName(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-blue-400"
                autoFocus
              />
              {!isCustomHobby(editingHobby) && (
                <p className="text-xs text-gray-300 mt-1">修改后仅影响显示名称，数据仍以原始名称存储</p>
              )}
            </div>
            <div>
              <label className="text-xs text-gray-500 mb-1.5 block">时间类型</label>
              <div className="grid grid-cols-2 gap-2">
                {TIME_CATEGORIES.map(tc => (
                  <button
                    key={tc.key}
                    onClick={() => setEditTimeCategory(tc.key)}
                    className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm border transition-colors ${editTimeCategory === tc.key ? 'border-transparent text-white' : 'border-gray-200 text-gray-600 bg-gray-50'}`}
                    style={editTimeCategory === tc.key ? { backgroundColor: tc.color } : undefined}
                  >
                    <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: tc.color }} />
                    {tc.label}
                  </button>
                ))}
              </div>
            </div>
            <button
              onClick={() => saveEditHobby(editingHobby)}
              className="w-full py-3 bg-blue-600 text-white rounded-2xl text-sm font-medium"
            >
              保存
            </button>
          </div>
        </div>,
        document.body
      )}
    </div>
  )
}
