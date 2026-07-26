'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { localDateString } from '@/lib/dateUtils'
import type { TimeCategory } from '@/components/HobbiesView'
import { TIME_CATEGORIES } from '@/components/HobbiesView'

export type WeekStats = {
  weekLabel: string
  weekStart: string
  totalMinutes: number
  byCategory: Record<TimeCategory, number>
  untracked: number  // minutes not recorded in calendar
  byDay: { date: string; byCategory: Record<TimeCategory, number>; untracked: number }[]
}

function getWeekStart(date: Date): Date {
  const d = new Date(date)
  const day = d.getDay()
  const diff = day === 0 ? -6 : 1 - day
  d.setDate(d.getDate() + diff)
  d.setHours(0, 0, 0, 0)
  return d
}

function addDaysToDate(d: Date, n: number): Date {
  const r = new Date(d)
  r.setDate(r.getDate() + n)
  return r
}

function dateStr(d: Date): string {
  return localDateString(d)
}

function emptyByCategory(): Record<TimeCategory, number> {
  return Object.fromEntries(TIME_CATEGORIES.map(t => [t.key, 0])) as Record<TimeCategory, number>
}
export function useReviewData() {
  const supabase = createClient()
  const [weekOffset, setWeekOffset] = useState(0) // 0 = current week, -1 = last week
  const [currentWeek, setCurrentWeek] = useState<WeekStats | null>(null)
  const [avgWeek, setAvgWeek] = useState<WeekStats | null>(null)
  const [loading, setLoading] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) { setLoading(false); return }

    // Load time category map from localStorage
    let timeCategoryMap: Record<string, TimeCategory> = {}
    try { timeCategoryMap = JSON.parse(localStorage.getItem('hobby_time_category') ?? '{}') } catch { /* */ }
    let hobbyRenames: Record<string, string> = {}
    try { hobbyRenames = JSON.parse(localStorage.getItem('hobby_label_renames') ?? '{}') } catch { /* */ }

    // Current week dates
    const today = new Date()
    const targetWeekStart = getWeekStart(addDaysToDate(today, weekOffset * 7))
    const weekDays = Array.from({ length: 7 }, (_, i) => dateStr(addDaysToDate(targetWeekStart, i)))
    const weekEnd = weekDays[6]

    // Past 4 weeks for average (excluding current target week)
    const past4Starts = Array.from({ length: 4 }, (_, i) =>
      getWeekStart(addDaysToDate(targetWeekStart, -(i + 1) * 7))
    )
    const past4Days = past4Starts.flatMap(ws =>
      Array.from({ length: 7 }, (_, i) => dateStr(addDaysToDate(ws, i)))
    )

    const allDates = [...weekDays, ...past4Days]

    const { data: entries } = await supabase
      .from('time_entries')
      .select('date, start_time, end_time, hobby')
      .eq('user_id', user.id)
      .in('date', allDates)

    function getCategory(hobby: string): TimeCategory | null {
      const cat = timeCategoryMap[hobby]
      if (cat) return cat as TimeCategory
      const originalKey = Object.entries(hobbyRenames).find(([, v]) => v === hobby)?.[0]
      if (originalKey) return (timeCategoryMap[originalKey] as TimeCategory) ?? null
      return null
    }

    function calcMinutes(start: string, end: string): number {
      const [sh, sm] = start.split(':').map(Number)
      const [eh, em] = end.split(':').map(Number)
      return Math.max(0, (eh * 60 + em) - (sh * 60 + sm))
    }

    const todayStr = localDateString()

    // Build current week stats
    const byDay = weekDays.map(date => {
      const dayEntries = (entries ?? []).filter(e => e.date === date)
      const byCat = emptyByCategory()
      let recorded = 0
      for (const e of dayEntries) {
        const mins = calcMinutes(e.start_time, e.end_time)
        const cat = getCategory(e.hobby)
        if (cat) {
          byCat[cat] += mins
          recorded += mins
        }
        // uncategorized entries don't count as recorded → become untracked
      }
      const untracked = date <= todayStr ? Math.max(0, 24 * 60 - recorded) : 0
      return { date, byCategory: byCat, untracked }
    })

    const currentByCat = emptyByCategory()
    for (const day of byDay) {
      for (const cat of Object.keys(day.byCategory) as TimeCategory[]) {
        currentByCat[cat] += day.byCategory[cat]
      }
    }

    const fmtDate = (d: string) => {
      const [, m, day] = d.split('-')
      return `${parseInt(m)}/${parseInt(day)}`
    }

    setCurrentWeek({
      weekLabel: `${fmtDate(weekDays[0])} – ${fmtDate(weekEnd)}`,
      weekStart: weekDays[0],
      totalMinutes: Object.values(currentByCat).reduce((a, b) => a + b, 0),
      byCategory: currentByCat,
      untracked: byDay.reduce((s, d) => s + d.untracked, 0),
      byDay,
    })

    // Build 4-week average
    const avgByCat = emptyByCategory()
    for (const entry of (entries ?? []).filter(e => past4Days.includes(e.date))) {
      const cat = getCategory(entry.hobby)
      if (cat) avgByCat[cat] += calcMinutes(entry.start_time, entry.end_time)
    }
    // Divide by 4
    for (const cat of Object.keys(avgByCat) as TimeCategory[]) {
      avgByCat[cat] = Math.round(avgByCat[cat] / 4)
    }

    setAvgWeek({
      weekLabel: '近4周均',
      weekStart: '',
      totalMinutes: Object.values(avgByCat).reduce((a, b) => a + b, 0),
      byCategory: avgByCat,
      untracked: 0,
      byDay: [],
    })

    setLoading(false)
  }, [weekOffset]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { load() }, [load])

  return { currentWeek, avgWeek, loading, weekOffset, setWeekOffset }
}
