import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'

// ── Types ──────────────────────────────────────────────
export type TimeEntry = {
  id: string
  user_id: string
  date: string        // 'YYYY-MM-DD'
  start_time: string  // 'HH:MM:00'
  end_time: string    // 'HH:MM:00'
  hobby: string
  color: string
  notes: string | null
  mood: number | null  // 1-5
  created_at: string
}

export type TimeEntryForm = {
  date: string
  start_time: string  // 'HH:MM'
  end_time: string    // 'HH:MM'
  hobby: string
  color: string
  notes: string
  mood: number | null
}

export function emptyTimeEntryForm(date = '', startMin = 540): TimeEntryForm {
  const snap = Math.round(startMin / 15) * 15
  const toHHMM = (m: number) => `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`
  return {
    date,
    start_time: toHHMM(snap),
    end_time: toHHMM(Math.min(snap + 60, GRID_END_HOUR * 60 - 15)),
    hobby: HOBBY_LIST[0].label,
    color: HOBBY_LIST[0].color,
    notes: '',
    mood: null,
  }
}

// ── Constants ──────────────────────────────────────────
export const HOBBY_LIST = [
  { label: '锻炼',   color: '#EF4444' },
  { label: '日语',   color: '#F97316' },
  { label: '钢琴',   color: '#8B5CF6' },
  { label: '英语',   color: '#3B82F6' },
  { label: '炒股',   color: '#10B981' },
  { label: '西语',   color: '#F59E0B' },
  { label: '写作',   color: '#6366F1' },
  { label: '书影音', color: '#EC4899' },
  { label: '饮食管理', color: '#14B8A6' },
] as const

export const GRID_START_HOUR = 0
export const GRID_END_HOUR = 24
export const GRID_TOTAL_MINUTES = (GRID_END_HOUR - GRID_START_HOUR) * 60  // 1440
export const PX_PER_MINUTE = 1.2   // 1152px total height
export const SNAP_MINUTES = 15

// ── Helpers ────────────────────────────────────────────
export function timeToMinutes(t: string): number {
  const [h, m] = t.split(':').map(Number)
  return h * 60 + m
}

export function minutesToHHMM(m: number): string {
  return `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`
}

export function addDays(dateStr: string, n: number): string {
  const [y, m, d] = dateStr.split('-').map(Number)
  const date = new Date(y, m - 1, d + n)
  return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`
}

export function todayStr(): string {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
}

export function getMonday(dateStr: string): string {
  const [y, m, d] = dateStr.split('-').map(Number)
  const date = new Date(y, m - 1, d)
  const day = date.getDay()
  const diff = (day === 0 ? -6 : 1 - day)
  date.setDate(date.getDate() + diff)
  return `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,'0')}-${String(date.getDate()).padStart(2,'0')}`
}

// ── Data Hook ──────────────────────────────────────────
export function useTimeEntries(dates: string[]) {
  const supabase = createClient()
  const [entries, setEntries] = useState<TimeEntry[]>([])
  const [loading, setLoading] = useState(false)

  const load = useCallback(async () => {
    if (dates.length === 0) return
    setLoading(true)
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) { setLoading(false); return }
    const { data } = await supabase
      .from('time_entries')
      .select('*')
      .eq('user_id', user.id)
      .in('date', dates)
      .order('start_time')
    setEntries(data ?? [])
    setLoading(false)
  }, [dates.join(',')])  // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { load() }, [load])

  async function saveEntry(form: TimeEntryForm, id?: string): Promise<boolean> {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return false
    const payload = {
      user_id: user.id,
      date: form.date,
      start_time: form.start_time + ':00',
      end_time: form.end_time + ':00',
      hobby: form.hobby,
      color: form.color,
      notes: form.notes || null,
      mood: form.mood ?? null,
    }
    if (id) {
      const { error } = await supabase.from('time_entries').update(payload).eq('id', id)
      if (error) return false
    } else {
      const { error } = await supabase.from('time_entries').insert(payload)
      if (error) return false
    }
    await load()
    return true
  }

  async function deleteEntry(id: string): Promise<boolean> {
    const { error } = await supabase.from('time_entries').delete().eq('id', id)
    if (error) return false
    await load()
    return true
  }

  return { entries, loading, saveEntry, deleteEntry, reload: load }
}
