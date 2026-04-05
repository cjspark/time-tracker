'use client'

import { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'

const TIMER_KEY = 'active_timer_v1'

type TimerData = {
  hobby: string
  color: string
  startTime: string // ISO string
}

type TimerContextType = {
  timer: TimerData | null
  elapsed: number // seconds
  startTimer: (hobby: string, color: string) => void
  stopTimer: (save: boolean) => Promise<void>
}

const TimerContext = createContext<TimerContextType | null>(null)

export function TimerProvider({ children }: { children: React.ReactNode }) {
  const [timer, setTimer] = useState<TimerData | null>(null)
  const [elapsed, setElapsed] = useState(0)
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const supabase = createClient()

  // Load persisted timer on mount
  useEffect(() => {
    try {
      const saved = localStorage.getItem(TIMER_KEY)
      if (saved) {
        const data: TimerData = JSON.parse(saved)
        setTimer(data)
        setElapsed(Math.floor((Date.now() - new Date(data.startTime).getTime()) / 1000))
      }
    } catch { /* ignore */ }
  }, [])

  // Tick every second
  useEffect(() => {
    if (!timer) return
    intervalRef.current = setInterval(() => {
      setElapsed(Math.floor((Date.now() - new Date(timer.startTime).getTime()) / 1000))
    }, 1000)
    return () => { if (intervalRef.current) clearInterval(intervalRef.current) }
  }, [timer])

  function startTimer(hobby: string, color: string) {
    const data: TimerData = { hobby, color, startTime: new Date().toISOString() }
    setTimer(data)
    setElapsed(0)
    localStorage.setItem(TIMER_KEY, JSON.stringify(data))
  }

  const stopTimer = useCallback(async (save: boolean) => {
    if (!timer) return
    localStorage.removeItem(TIMER_KEY)
    const endDate = new Date()
    const startDate = new Date(timer.startTime)
    const savedTimer = { ...timer }
    setTimer(null)
    setElapsed(0)

    if (!save) return

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const pad = (n: number) => String(n).padStart(2, '0')
    const date = startDate.toISOString().slice(0, 10)
    const start_time = `${pad(startDate.getHours())}:${pad(startDate.getMinutes())}:00`
    const end_time = `${pad(endDate.getHours())}:${pad(endDate.getMinutes())}:00`

    // Only save if at least 1 minute elapsed
    if (endDate.getTime() - startDate.getTime() < 60000) return

    await supabase.from('time_entries').insert({
      user_id: user.id,
      date,
      start_time,
      end_time,
      hobby: savedTimer.hobby,
      color: savedTimer.color,
      notes: null,
    })
  }, [timer]) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <TimerContext.Provider value={{ timer, elapsed, startTimer, stopTimer }}>
      {children}
    </TimerContext.Provider>
  )
}

export function useTimer() {
  const ctx = useContext(TimerContext)
  if (!ctx) throw new Error('useTimer must be used within TimerProvider')
  return ctx
}
