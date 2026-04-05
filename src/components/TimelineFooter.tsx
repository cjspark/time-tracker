'use client'

import { useState } from 'react'
import { Play, X } from 'lucide-react'
import { useTimer } from '@/lib/timer-context'
import { HOBBY_LIST } from '@/components/calendar/useTimeEntries'

type CustomHobby = { label: string; color: string }

function getCustomHobbies(): CustomHobby[] {
  if (typeof window === 'undefined') return []
  try { return JSON.parse(localStorage.getItem('hobby_custom_hobbies') ?? '[]') } catch { return [] }
}

export default function TimelineFooter() {
  const { timer, startTimer } = useTimer()
  const [picking, setPicking] = useState(false)

  if (timer) return null // TimerBar handles UI when running

  const allHobbies = [...HOBBY_LIST, ...getCustomHobbies()]

  return (
    <>
      {/* Start button */}
      <div className="fixed bottom-16 left-0 right-0 z-40 flex justify-center px-4">
        <button
          onClick={() => setPicking(true)}
          className="w-full max-w-lg flex items-center justify-center gap-2 py-3 rounded-2xl bg-green-500 text-white font-medium shadow-lg active:bg-green-600 transition-colors"
        >
          <Play size={16} fill="white" />
          开始记录
        </button>
      </div>

      {/* Hobby picker sheet */}
      {picking && (
        <div className="fixed inset-0 z-50 flex items-end">
          <div className="absolute inset-0 bg-black/30" onClick={() => setPicking(false)} />
          <div className="relative w-full bg-white rounded-t-3xl px-4 pt-4 pb-8 max-w-lg mx-auto">
            <div className="flex items-center justify-between mb-4">
              <span className="font-semibold text-gray-800">选择爱好开始计时</span>
              <button onClick={() => setPicking(false)} className="p-1 text-gray-400">
                <X size={20} />
              </button>
            </div>
            <div className="grid grid-cols-3 gap-2">
              {allHobbies.map((h) => (
                <button
                  key={h.label}
                  onClick={() => { startTimer(h.label, h.color); setPicking(false) }}
                  className="flex items-center gap-2 px-3 py-3 rounded-xl text-sm font-medium transition-colors"
                  style={{ backgroundColor: h.color + '15', color: h.color }}
                >
                  <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: h.color }} />
                  {h.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  )
}
