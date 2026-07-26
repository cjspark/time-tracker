'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import AppHeader from '@/components/AppHeader'
import BottomNav from '@/components/BottomNav'
import { TimerProvider } from '@/lib/timer-context'
import TimerBar from '@/components/TimerBar'
import TimelineFooter from '@/components/TimelineFooter'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter()
  const [checking, setChecking] = useState(true)

  useEffect(() => {
    const supabase = createClient()
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) router.replace('/login')
      else setChecking(false)
    })
  }, [router])

  if (checking) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-300 text-sm">加载中...</div>
      </div>
    )
  }

  return (
    <TimerProvider>
      <div className="fixed inset-0 flex flex-col bg-gray-50">
        {/* Fixed header - respects iOS status bar */}
        <div className="shrink-0 z-40 bg-white">
          <AppHeader />
        </div>

        {/* Scrollable content */}
        <main className="flex-1 overflow-y-auto max-w-lg w-full mx-auto pb-20">
          {children}
        </main>

        <TimerBar />
        <TimelineFooter />
        <BottomNav />
      </div>
    </TimerProvider>
  )
}
