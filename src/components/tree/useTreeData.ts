'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'

export type AchievementTemplate = 'general' | 'dividend' | 'deposit' | 'stock_profit' | 'habit'

export type DividendMeta = { name: string; currency: 'CNY' | 'USD'; shares: number; dividendPer10: number }
export type DepositMeta  = { name: string; currency: 'CNY' | 'USD'; principal: number; rate: number }
export type StockMeta    = { name: string; currency: 'CNY' | 'USD'; costBasis: number }
export type HabitMeta    = { unit: '天' | '周' | '年'; period: number } // e.g. 330天, 52周
export type AchievementMeta = DividendMeta | DepositMeta | StockMeta | HabitMeta | null

export function isInvestmentCategory(name: string) {
  return /投资|理财/.test(name)
}

export type Achievement = {
  id: string
  category: string
  name: string
  unit: string
  target_value: number
  year: number
  template: AchievementTemplate
  metadata: AchievementMeta
  parent_id: string | null
  archived_at: string | null
  created_at: string
  records: AchievementRecord[]
  current_value: number  // for parent: sum of children target_values; for child: sum of records
  progress: number       // 0-1
  children: Achievement[]
}

export type AchievementRecord = {
  id: string
  achievement_id: string
  value: number
  note: string | null
  date: string
}

export type BranchData = {
  category: string
  displayName: string
  hobbies: HobbyLeaf[]
  achievements: Achievement[] // only top-level (parent_id = null)
  maxMinutes: number
}

export type HobbyLeaf = {
  label: string
  color: string
  totalMinutes: number
}

export function useTreeData(year: number) {
  const supabase = createClient()
  const [branches, setBranches] = useState<BranchData[]>([])
  const [loading, setLoading] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) { setLoading(false); return }

    let catRenames: Record<string, string> = {}
    try { catRenames = JSON.parse(localStorage.getItem('hobby_cat_renames') ?? '{}') } catch { /* */ }

    const yearStart = `${year}-01-01`
    const yearEnd = `${year}-12-31`

    const [
      { data: prefs },
      { data: entries },
      { data: history },
      { data: achievements },
      { data: records },
    ] = await Promise.all([
      supabase.from('hobby_preferences').select('hobby, category').eq('user_id', user.id),
      supabase.from('time_entries').select('hobby, start_time, end_time, color').eq('user_id', user.id).gte('date', yearStart).lte('date', yearEnd),
      supabase.from('hobby_history').select('hobby, historical_minutes').eq('user_id', user.id),
      supabase.from('achievements').select('*').eq('user_id', user.id).eq('year', year),
      supabase.from('achievement_records').select('*').eq('user_id', user.id),
    ])

    const calMap: Record<string, number> = {}
    const colorMap: Record<string, string> = {}
    for (const e of entries ?? []) {
      const [sh, sm] = e.start_time.split(':').map(Number)
      const [eh, em] = e.end_time.split(':').map(Number)
      const mins = (eh * 60 + em) - (sh * 60 + sm)
      calMap[e.hobby] = (calMap[e.hobby] ?? 0) + Math.max(0, mins)
      colorMap[e.hobby] = e.color
    }
    const histMap: Record<string, number> = {}
    for (const h of history ?? []) histMap[h.hobby] = h.historical_minutes

    const catMap: Record<string, string> = {}
    for (const p of prefs ?? []) catMap[p.hobby] = p.category

    // attach records to achievements
    const recordsMap: Record<string, AchievementRecord[]> = {}
    for (const r of records ?? []) {
      if (!recordsMap[r.achievement_id]) recordsMap[r.achievement_id] = []
      recordsMap[r.achievement_id].push(r)
    }

    const allAchievements = achievements ?? []

    // First pass: enrich child achievements (parent_id != null)
    const childMap: Record<string, Achievement[]> = {}
    const enrichedMap: Record<string, Achievement> = {}

    for (const a of allAchievements) {
      const recs = recordsMap[a.id] ?? []
      const recSum = recs.reduce((s, r) => s + r.value, 0)
      const enriched: Achievement = {
        ...a,
        parent_id: a.parent_id ?? null,
        archived_at: a.archived_at ?? null,
        template: a.template ?? 'general',
        metadata: a.metadata ?? null,
        records: recs,
        current_value: recSum,
        progress: a.target_value > 0 ? Math.min(1, recSum / a.target_value) : 0,
        children: [],
      }
      enrichedMap[a.id] = enriched
      if (a.parent_id) {
        if (!childMap[a.parent_id]) childMap[a.parent_id] = []
        childMap[a.parent_id].push(enriched)
      }
    }

    // Second pass: attach children to parents, recalculate parent current_value
    const topLevel: Achievement[] = []
    for (const a of allAchievements) {
      if (a.parent_id) continue // skip children in top-level list
      const enriched = enrichedMap[a.id]
      const children = childMap[a.id] ?? []
      enriched.children = children
      // parent current_value = sum of children target_values (planned income)
      if (children.length > 0) {
        enriched.current_value = children.reduce((s, c) => s + c.target_value, 0)
        enriched.progress = a.target_value > 0 ? Math.min(1, enriched.current_value / a.target_value) : 0
      }
      topLevel.push(enriched)
    }

    // group by category
    const allHobbies = Object.keys({ ...calMap, ...histMap })
    const catGroups: Record<string, HobbyLeaf[]> = {}
    for (const h of allHobbies) {
      const cat = catMap[h] ?? '未分类'
      const total = (calMap[h] ?? 0) + (histMap[h] ?? 0)
      if (total === 0) continue
      if (!catGroups[cat]) catGroups[cat] = []
      catGroups[cat].push({ label: h, color: colorMap[h] ?? '#6366F1', totalMinutes: total })
    }

    for (const a of topLevel) {
      if (!catGroups[a.category]) catGroups[a.category] = []
    }

    const result: BranchData[] = Object.entries(catGroups).map(([category, hobbies]) => {
      const maxMinutes = Math.max(0, ...hobbies.map(h => h.totalMinutes))
      const catAchievements = topLevel.filter(a => a.category === category)
      return { category, displayName: catRenames[category] ?? category, hobbies, achievements: catAchievements, maxMinutes }
    })

    setBranches(result)
    setLoading(false)
  }, [year]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { load() }, [load])

  async function addAchievement(data: {
    category: string; name: string; unit: string; target_value: number
    template?: AchievementTemplate; metadata?: AchievementMeta; parent_id?: string
  }) {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    await supabase.from('achievements').insert({
      category: data.category,
      name: data.name,
      unit: data.unit,
      target_value: data.target_value,
      template: data.template ?? 'general',
      metadata: data.metadata ?? null,
      parent_id: data.parent_id ?? null,
      year,
      user_id: user.id,
    })
    await load()
  }

  async function updateAchievementTarget(id: string, target_value: number) {
    await supabase.from('achievements').update({ target_value }).eq('id', id)
    await load()
  }

  async function deleteAchievement(id: string) {
    await supabase.from('achievements').delete().eq('id', id)
    await load()
  }

  async function archiveAchievement(id: string) {
    await supabase.from('achievements').update({ archived_at: new Date().toISOString() }).eq('id', id)
    await load()
  }

  async function unarchiveAchievement(id: string) {
    await supabase.from('achievements').update({ archived_at: null }).eq('id', id)
    await load()
  }

  async function addRecord(achievement_id: string, data: { value: number; note: string; date: string }) {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    await supabase.from('achievement_records').insert({ ...data, achievement_id, user_id: user.id })
    await load()
  }

  async function deleteRecord(id: string) {
    await supabase.from('achievement_records').delete().eq('id', id)
    await load()
  }

  return { branches, loading, load, addAchievement, updateAchievementTarget, deleteAchievement, archiveAchievement, unarchiveAchievement, addRecord, deleteRecord }
}
