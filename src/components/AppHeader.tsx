'use client'

import { usePathname } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'
import { LogOut } from 'lucide-react'

const pageTitles: Record<string, string> = {
  '/dashboard/calendar': '时间',
  '/dashboard/hobbies': '时间',
}

export default function AppHeader() {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()
  const title = pageTitles[pathname] ?? '时间'

  async function handleSignOut() {
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <header className="bg-white border-b border-gray-200">
      <div className="max-w-lg mx-auto px-4 h-14 flex items-center justify-between">
        <h1 className="text-lg font-bold text-gray-900">{title}</h1>
        <button onClick={handleSignOut} className="p-2 rounded-xl hover:bg-gray-100 text-gray-500 transition-colors">
          <LogOut size={20} />
        </button>
      </div>
    </header>
  )
}
