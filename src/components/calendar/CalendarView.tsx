'use client'

import { useState, useMemo, useRef, useEffect } from 'react'
import { View } from './ViewSwitcher'
import DateNavigator from './DateNavigator'
import TimeGrid, { TimeGridHandle } from './TimeGrid'
import TimeEntryModal from '@/components/TimeEntryModal'
import QuickEntryPopup from '@/components/QuickEntryPopup'
import {
  TimeEntry, TimeEntryForm,
  useTimeEntries, emptyTimeEntryForm,
  addDays, getMonday, todayStr,
  GRID_START_HOUR, GRID_END_HOUR,
} from './useTimeEntries'

type Props = { view: View }

function getDates(anchor: string, view: View): string[] {
  if (view === 'day') return [anchor]
  if (view === '2day') return [anchor, addDays(anchor, 1)]
  const monday = getMonday(anchor)
  return Array.from({ length: 7 }, (_, i) => addDays(monday, i))
}

function navStep(view: View): number {
  if (view === 'day') return 1
  if (view === '2day') return 2
  return 7
}

export default function CalendarView({ view }: Props) {
  const [today, setToday] = useState<string>('')
  const [anchor, setAnchor] = useState<string>('')
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [form, setForm] = useState<TimeEntryForm>(() => emptyTimeEntryForm(''))
  const [saving, setSaving] = useState(false)
  const [popupPos, setPopupPos] = useState<{ x: number; y: number } | null>(null)
  const [pendingScroll, setPendingScroll] = useState<number | null>(null)
  const gridRef = useRef<TimeGridHandle>(null)

  // Client-only: compute today in local timezone
  useEffect(() => {
    const t = todayStr()
    setToday(t)
    setAnchor(t)
    setForm(emptyTimeEntryForm(t))
    const update = () => setToday(todayStr())
    window.addEventListener('focus', update)
    return () => window.removeEventListener('focus', update)
  }, [])

  const dates = useMemo(() => anchor ? getDates(anchor, view) : [], [anchor, view])
  const { entries, saveEntry, deleteEntry } = useTimeEntries(dates)

  const isToday = anchor ? (view === 'day' ? anchor === today : dates.includes(today)) : false

  // Execute pending scroll after anchor/dates change
  useEffect(() => {
    if (pendingScroll === null) return
    gridRef.current?.scrollToTime(pendingScroll)
    setPendingScroll(null)
  }, [anchor, pendingScroll])

  if (!anchor) return null

  function openCreate(date: string, startMinutes: number, clientX: number, clientY: number, endMinutes?: number) {
    setEditingId(null)
    setForm(emptyTimeEntryForm(date, startMinutes, endMinutes))
    setPopupPos({ x: clientX, y: clientY })
  }

  function openEdit(entry: TimeEntry) {
    setEditingId(entry.id)
    setForm({
      date: entry.date,
      start_time: entry.start_time.slice(0, 5),
      end_time: entry.end_time.slice(0, 5),
      hobby: entry.hobby,
      color: entry.color,
      notes: entry.notes ?? '',
      mood: entry.mood ?? null,
    })
    setModalOpen(true)
  }

  async function handleSave() {
    setSaving(true)
    await saveEntry(form, editingId ?? undefined)
    setSaving(false)
    setModalOpen(false)
  }

  async function handlePopupSave() {
    setSaving(true)
    await saveEntry(form, undefined)
    setSaving(false)
    setPopupPos(null)
  }

  async function handleDelete() {
    if (!editingId) return
    setSaving(true)
    await deleteEntry(editingId)
    setSaving(false)
    setModalOpen(false)
  }

  function navigate(dir: 'prev' | 'next') {
    const step = navStep(view)
    setAnchor((a) => addDays(a, dir === 'next' ? step : -step))
  }

  function handleReachTop() {
    navigate('prev')
    setPendingScroll((GRID_END_HOUR - 1) * 60) // scroll to ~22:00
  }

  function handleReachBottom() {
    navigate('next')
    setPendingScroll(GRID_START_HOUR * 60) // scroll to 7:00
  }

  return (
    <div className="flex flex-col flex-1 overflow-hidden">
      <DateNavigator
        view={view}
        anchorDate={anchor}
        onPrev={() => navigate('prev')}
        onNext={() => navigate('next')}
        onToday={() => setAnchor(today)}
        onDatePick={setAnchor}
        isToday={isToday}
      />

      <TimeGrid
        ref={gridRef}
        dates={dates}
        entries={entries}
        anchor={anchor}
        onBlockTap={openEdit}
        onGridInteract={openCreate}
        onReachTop={handleReachTop}
        onReachBottom={handleReachBottom}
      />

      {popupPos && (
        <QuickEntryPopup
          clientX={popupPos.x}
          clientY={popupPos.y}
          form={form}
          saving={saving}
          onChange={setForm}
          onSave={handlePopupSave}
          onClose={() => setPopupPos(null)}
        />
      )}

      <TimeEntryModal
        open={modalOpen}
        form={form}
        saving={saving}
        isEditing={!!editingId}
        onChange={setForm}
        onSave={handleSave}
        onDelete={editingId ? handleDelete : undefined}
        onClose={() => setModalOpen(false)}
      />
    </div>
  )
}
