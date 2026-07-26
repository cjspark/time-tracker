'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { localDateString } from '@/lib/dateUtils'
import type { Achievement } from '@/components/tree/useTreeData'

export type HabitCheckIn = {
  id: string
  achievement_id: string
  date: string // YYYY-MM-DD
  note: string | null
}

// Returns Mon-Sun dates for the week containing `date`
export function getWeekDays(date: Date): string[] {
  const d = new Date(date)
  const day = d.getDay() // 0=Sun
  const diff = day === 0 ? -6 : 1 - day // shift to Monday
  d.setDate(d.getDate() + diff)
  return Array.from({ length: 7 }, (_, i) => {
    const dd = new Date(d)
    dd.setDate(d.getDate() + i)
    return localDateString(dd)
  })
}

export function useHabitData(year: number) {
  const supabase = createClient()
  const [habits, setHabits] = useState<Achievement[]>([])
  const [checkIns, setCheckIns] = useState<HabitCheckIn[]>([])
  const [loading, setLoading] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) { setLoading(false); return }

    const [{ data: achievements }, { data: records }] = await Promise.all([
      supabase.from('achievements').select('*').eq('user_id', user.id).eq('year', year).eq('template', 'habit'),
      supabase.from('achievement_records').select('*').eq('user_id', user.id),
    ])

    const recordsMap: Record<string, { value: number; records: HabitCheckIn[] }> = {}
    for (const r of records ?? []) {
      if (!recordsMap[r.achievement_id]) recordsMap[r.achievement_id] = { value: 0, records: [] }
      recordsMap[r.achievement_id].value += r.value
      recordsMap[r.achievement_id].records.push({ id: r.id, achievement_id: r.achievement_id, date: r.date, note: r.note })
    }

    const enriched = (achievements ?? []).map(a => ({
      ...a,
      template: 'habit' as const,
      metadata: a.metadata ?? null,
      parent_id: a.parent_id ?? null,
      records: recordsMap[a.id]?.records ?? [],
      current_value: recordsMap[a.id]?.value ?? 0,
      progress: a.target_value > 0 ? Math.min(1, (recordsMap[a.id]?.value ?? 0) / a.target_value) : 0,
      children: [],
    }))

    setHabits(enriched)
    setCheckIns((achievements ?? []).flatMap(a => recordsMap[a.id]?.records ?? []))
    setLoading(false)
  }, [year]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { load() }, [load])

  async function checkIn(achievement_id: string, date: string, note = '') {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    await supabase.from('achievement_records').insert({
      achievement_id, user_id: user.id, value: 1, note, date,
    })
    await load()
  }

  async function undoCheckIn(record_id: string) {
    await supabase.from('achievement_records').delete().eq('id', record_id)
    await load()
  }

  return { habits, checkIns, loading, checkIn, undoCheckIn, reload: load }
}
