'use client'

import { useState } from 'react'
import CalendarView from '@/components/calendar/CalendarView'
import ViewSwitcher, { View } from '@/components/calendar/ViewSwitcher'

export default function CalendarPage() {
  const [view, setView] = useState<View>('day')

  return (
    <div className="flex flex-col" style={{ height: 'calc(100dvh - 112px)' }}>
      <div className="flex items-center justify-end px-4 py-2 bg-white border-b border-gray-100 shrink-0">
        <ViewSwitcher view={view} onChange={setView} />
      </div>
      <CalendarView view={view} />
    </div>
  )
}
