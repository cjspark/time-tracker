import { useState, useEffect } from 'react'
import { HOBBY_LIST } from '@/components/calendar/useTimeEntries'
import { TIME_CATEGORIES } from '@/components/HobbiesView'
import type { TimeCategory } from '@/components/HobbiesView'

export type HobbyItem = { label: string; displayLabel: string; color: string }

function ls<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback
  try { return JSON.parse(localStorage.getItem(key) ?? 'null') ?? fallback } catch { return fallback }
}

function resolveColor(label: string, baseColor: string): string {
  const overrides: Record<string, string> = ls('hobby_color_overrides', {})
  const timeCatMap: Record<string, TimeCategory> = ls('hobby_time_category', {})
  const timecat = timeCatMap[label]
  if (timecat) {
    const found = TIME_CATEGORIES.find(t => t.key === timecat)
    if (found) return found.color
  }
  return overrides[label] ?? baseColor
}

export function useAllHobbies(): HobbyItem[] {
  const [list, setList] = useState<HobbyItem[]>(() =>
    HOBBY_LIST.map(h => ({ label: h.label, displayLabel: h.label, color: h.color }))
  )

  useEffect(() => {
    function build() {
      const custom: { label: string; color: string }[] = ls('hobby_custom_hobbies', [])
      const hidden: string[]   = ls('hobby_hidden', [])
      const inactive: string[] = ls('hobby_inactive', [])
      const renames: Record<string, string> = ls('hobby_label_renames', {})

      const base = [...HOBBY_LIST].map(h => ({
        label: h.label,
        displayLabel: renames[h.label] ?? h.label,
        color: resolveColor(h.label, h.color),
      }))

      const customItems = custom
        .filter(h => !base.some(b => b.label === h.label))
        .map(h => ({
          label: h.label,
          displayLabel: renames[h.label] ?? h.label,
          color: resolveColor(h.label, h.color),
        }))

      const all = [...base, ...customItems].filter(
        h => !hidden.includes(h.label) && !inactive.includes(h.label)
      )
      setList(all)
    }

    build()
    window.addEventListener('storage', build)
    return () => window.removeEventListener('storage', build)
  }, [])

  return list
}
