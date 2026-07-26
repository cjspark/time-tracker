'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { CalendarDays, Heart, TreePine, BarChart2 } from 'lucide-react'

const tabs = [
  { href: '/dashboard/calendar', label: '日历', icon: CalendarDays },
  { href: '/dashboard/tree', label: '生命树', icon: TreePine },
  { href: '/dashboard/hobbies', label: '活动', icon: Heart },
  { href: '/dashboard/review', label: '复盘', icon: BarChart2 },
]

export default function BottomNav() {
  const pathname = usePathname()

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50">
      <div className="flex max-w-lg mx-auto">
        {tabs.map(({ href, label, icon: Icon }) => {
          const isActive = pathname.startsWith(href)
          return (
            <Link key={href} href={href}
              className={`flex-1 flex flex-col items-center py-2 gap-0.5 text-xs transition-colors ${isActive ? 'text-blue-600' : 'text-gray-400'}`}>
              <Icon size={22} strokeWidth={isActive ? 2.5 : 1.5} />
              <span className={isActive ? 'font-medium' : ''}>{label}</span>
            </Link>
          )
        })}
      </div>
    </nav>
  )
}
