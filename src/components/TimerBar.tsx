'use client'

import { Square, X } from 'lucide-react'
import { useTimer } from '@/lib/timer-context'

function formatElapsed(s: number): string {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  const sec = s % 60
  if (h > 0) return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(sec).padStart(2,'0')}`
  return `${String(m).padStart(2,'0')}:${String(sec).padStart(2,'0')}`
}

export default function TimerBar() {
  const { timer, elapsed, stopTimer } = useTimer()
  if (!timer) return null

  return (
    <div className="fixed bottom-16 left-0 right-0 z-40 flex justify-center px-4 pointer-events-none">
      <div
        className="flex items-center gap-3 px-4 py-3 rounded-2xl shadow-lg pointer-events-auto w-full max-w-lg"
        style={{ backgroundColor: timer.color + '18', border: `1.5px solid ${timer.color}50` }}
      >
        <span className="w-2 h-2 rounded-full animate-pulse shrink-0" style={{ backgroundColor: timer.color }} />
        <span className="text-sm font-medium flex-1" style={{ color: timer.color }}>{timer.hobby}</span>
        <span className="text-xl font-mono font-semibold tabular-nums" style={{ color: timer.color }}>
          {formatElapsed(elapsed)}
        </span>
        {/* Discard */}
        <button
          onClick={() => stopTimer(false)}
          className="w-8 h-8 rounded-full flex items-center justify-center bg-gray-100 text-gray-400 hover:bg-gray-200"
        >
          <X size={14} />
        </button>
        {/* Save & stop */}
        <button
          onClick={() => stopTimer(true)}
          className="w-8 h-8 rounded-full flex items-center justify-center text-white shadow-sm"
          style={{ backgroundColor: timer.color }}
        >
          <Square size={13} fill="white" />
        </button>
      </div>
    </div>
  )
}
