import { useState, useEffect } from 'react'
import { HOBBY_LIST } from '@/components/calendar/useTimeEntries'
import { TIME_CATEGORIES } from '@/components/HobbiesView'
import type { TimeCategory } from '@/components/HobbiesView'
import { getPref } from '@/lib/prefs'

export type HobbyItem = { label: string; displayLabel: string; color: string }

function resolveColorFromMaps(
  label: string,
  baseColor: string,
  timeCatMap: Record<string, TimeCategory>,
  overrides: Record<string, string>
): string {
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
    async function build() {
      const [custom, hidden, inactive, overrides, renames, timeCatMap] = await Promise.all([
        getPref('hobby_custom_hobbies', [] as { label: string; color: string }[]),
        getPref('hobby_hidden', [] as string[]),
        getPref('hobby_inactive', [] as string[]),
        getPref('hobby_color_overrides', {} as Record<string, string>),
        getPref('hobby_label_renames', {} as Record<string, string>),
        getPref('hobby_time_category', {} as Record<string, TimeCategory>),
      ])

      const base = [...HOBBY_LIST].map(h => ({
        label: h.label,
        displayLabel: renames[h.label] ?? h.label,
        color: resolveColorFromMaps(h.label, h.color, timeCatMap, overrides),
      }))

      const customItems = custom
        .filter(h => !base.some(b => b.label === h.label))
        .map(h => ({
          label: h.label,
          displayLabel: renames[h.label] ?? h.label,
          color: resolveColorFromMaps(h.label, h.color, timeCatMap, overrides),
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
