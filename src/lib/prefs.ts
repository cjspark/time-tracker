'use client'

import { createClient } from '@/lib/supabase/client'

const supabase = createClient()

// Read a preference key (from Supabase, fallback to localStorage for migration)
export async function getPref<T>(key: string, fallback: T): Promise<T> {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return localGet(key, fallback)

    const { data } = await supabase
      .from('user_preferences')
      .select('value')
      .eq('user_id', user.id)
      .eq('key', key)
      .maybeSingle()

    if (data) return data.value as T

    // Migrate from localStorage if exists
    const local = localGet<T | null>(key, null)
    if (local !== null) {
      await setPref(key, local)
      return local
    }
    return fallback
  } catch {
    return localGet(key, fallback)
  }
}

// Write a preference key to Supabase (and keep localStorage in sync)
export async function setPref<T>(key: string, value: T): Promise<void> {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      await supabase.from('user_preferences').upsert(
        { user_id: user.id, key, value },
        { onConflict: 'user_id,key' }
      )
    }
  } catch { /* ignore */ }
  // Always keep localStorage in sync for immediate reads
  localSet(key, value)
}

function localGet<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback
  try { return JSON.parse(localStorage.getItem(key) ?? 'null') ?? fallback } catch { return fallback }
}

function localSet<T>(key: string, value: T) {
  if (typeof window === 'undefined') return
  localStorage.setItem(key, JSON.stringify(value))
  window.dispatchEvent(new Event('storage'))
}
