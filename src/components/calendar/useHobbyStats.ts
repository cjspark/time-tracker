import { useState, useEffect, useCallback, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { HOBBY_LIST } from './useTimeEntries'

export type HobbyStats = {
  label: string
  color: string
  historicalMinutes: number
  calendarMinutes: number
  totalMinutes: number
  category: string
}

export function useHobbyStats(
  extraHobbies: readonly { label: string; color: string }[] = [],
  hiddenLabels: readonly string[] = []
) {
  const supabase = createClient()
  const [stats, setStats] = useState<HobbyStats[]>([])
  const [loading, setLoading] = useState(false)
  const extraRef = useRef(extraHobbies)
  extraRef.current = extraHobbies
  const hiddenRef = useRef(hiddenLabels)
  hiddenRef.current = hiddenLabels

  const load = useCallback(async () => {
    setLoading(true)
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) { setLoading(false); return }
    const allHobbies = [...HOBBY_LIST, ...extraRef.current].filter(
      h => !hiddenRef.current.includes(h.label)
    )

    const [{ data: history }, { data: entries }, { data: prefs }] = await Promise.all([
      supabase.from('hobby_history').select('hobby, historical_minutes').eq('user_id', user.id),
      supabase.from('time_entries').select('hobby, start_time, end_time').eq('user_id', user.id),
      supabase.from('hobby_preferences').select('hobby, category').eq('user_id', user.id),
    ])

    const histMap: Record<string, number> = {}
    for (const h of history ?? []) histMap[h.hobby] = h.historical_minutes

    const calMap: Record<string, number> = {}
    for (const e of entries ?? []) {
      const [sh, sm] = e.start_time.split(':').map(Number)
      const [eh, em] = e.end_time.split(':').map(Number)
      const mins = (eh * 60 + em) - (sh * 60 + sm)
      calMap[e.hobby] = (calMap[e.hobby] ?? 0) + Math.max(0, mins)
    }

    const catMap: Record<string, string> = {}
    for (const p of prefs ?? []) catMap[p.hobby] = p.category

    setStats(allHobbies.map(h => ({
      label: h.label,
      color: h.color,
      historicalMinutes: histMap[h.label] ?? 0,
      calendarMinutes: calMap[h.label] ?? 0,
      totalMinutes: (histMap[h.label] ?? 0) + (calMap[h.label] ?? 0),
      category: catMap[h.label] ?? '未分类',
    })))
    setLoading(false)
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { load() }, [load])
  useEffect(() => { load() }, [extraHobbies.length]) // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => { load() }, [hiddenLabels.length]) // eslint-disable-line react-hooks/exhaustive-deps

  async function updateHistorical(hobby: string, minutes: number): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    await supabase.from('hobby_history').upsert(
      { user_id: user.id, hobby, historical_minutes: minutes },
      { onConflict: 'user_id,hobby' }
    )
    await load()
  }

  async function updateCategory(hobby: string, category: string): Promise<void> {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    await supabase.from('hobby_preferences').upsert(
      { user_id: user.id, hobby, category },
      { onConflict: 'user_id,hobby' }
    )
    await load()
  }

  return { stats, loading, updateHistorical, updateCategory }
}
