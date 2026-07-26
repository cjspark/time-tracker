'use client'

import { useState } from 'react'
import { Play, X } from 'lucide-react'
import { useTimer } from '@/lib/timer-context'
import { useAllHobbies } from '@/lib/useAllHobbies'

export default function TimelineFooter() {
  const { timer, startTimer } = useTimer()
  const [picking, setPicking] = useState(false)
  const hobbyList = useAllHobbies()

  if (timer) return null

  return (
    <>
      {/* Start button */}
      <div className="fixed bottom-20 right-4 z-40">
        <button
          onClick={() => setPicking(true)}
          className="w-14 h-14 flex items-center justify-center rounded-full bg-green-500 text-white shadow-lg active:bg-green-600 transition-colors"
          aria-label="开始记录"
        >
          <Play size={22} fill="white" />
        </button>
      </div>

      {/* Hobby picker sheet */}
      {picking && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
          <div className="absolute inset-0 bg-black/30" onClick={() => setPicking(false)} />
          <div className="relative w-full bg-white rounded-3xl px-4 pt-4 pb-6 max-w-sm max-h-[70vh] overflow-y-auto shadow-xl">
            <div className="flex items-center justify-between mb-4">
              <span className="font-semibold text-gray-800">选择爱好开始计时</span>
              <button onClick={() => setPicking(false)} className="p-1 text-gray-400">
                <X size={20} />
              </button>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {hobbyList.map((h) => (
                <button
                  key={h.label}
                  onClick={() => { startTimer(h.label, h.color); setPicking(false) }}
                  className="flex items-center gap-2 px-3 py-3 rounded-xl text-sm font-medium transition-colors"
                  style={{ backgroundColor: h.color + '15', color: h.color }}
                >
                  <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: h.color }} />
                  {h.displayLabel}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  )
}
