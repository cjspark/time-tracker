import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import AppHeader from '@/components/AppHeader'
import BottomNav from '@/components/BottomNav'
import { TimerProvider } from '@/lib/timer-context'
import TimerBar from '@/components/TimerBar'
import TimelineFooter from '@/components/TimelineFooter'

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  return (
    <TimerProvider>
      <div className="min-h-screen bg-gray-50">
        <div className="sticky top-0 z-40 bg-white">
          <AppHeader />
        </div>
        <main className="pb-20 max-w-lg mx-auto">
          {children}
        </main>
        <TimerBar />
        <TimelineFooter />
        <BottomNav />
      </div>
    </TimerProvider>
  )
}
