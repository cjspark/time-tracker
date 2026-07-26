'use client'

import { useState, useRef, useEffect } from 'react'
import { Play, X } from 'lucide-react'
import { useTimer } from '@/lib/timer-context'
import { useAllHobbies } from '@/lib/useAllHobbies'

export default function TimelineFooter() {
  const { timer, startTimer } = useTimer()
  const [picking, setPicking] = useState(false)
  const hobbyList = useAllHobbies()

  // Draggable FAB state
  const [pos, setPos] = useState({ x: -1, y: -1 }) // -1 = not initialized
  const [dragging, setDragging] = useState(false)
  const dragStart = useRef({ mx: 0, my: 0, bx: 0, by: 0 })
  const btnRef = useRef<HTMLDivElement>(null)
  const SIZE = 56

  // Initialize position after mount
  useEffect(() => {
    const initX = window.innerWidth - SIZE - 16
    const initY = window.innerHeight - SIZE - 90 // above bottom nav
    setPos({ x: initX, y: initY })
  }, [])

  function clamp(x: number, y: number) {
    const maxX = window.innerWidth - SIZE
    const maxY = window.innerHeight - SIZE - 60 // keep above bottom nav
    return {
      x: Math.max(0, Math.min(x, maxX)),
      y: Math.max(60, Math.min(y, maxY)),
    }
  }

  function onPointerDown(e: React.PointerEvent) {
    e.preventDefault()
    dragStart.current = { mx: e.clientX, my: e.clientY, bx: pos.x, by: pos.y }
    setDragging(true)
    ;(e.target as HTMLElement).setPointerCapture(e.pointerId)
  }

  function onPointerMove(e: React.PointerEvent) {
    if (!dragging) return
    const dx = e.clientX - dragStart.current.mx
    const dy = e.clientY - dragStart.current.my
    setPos(clamp(dragStart.current.bx + dx, dragStart.current.by + dy))
  }

  function onPointerUp(e: React.PointerEvent) {
    if (!dragging) return
    setDragging(false)
    const dx = Math.abs(e.clientX - dragStart.current.mx)
    const dy = Math.abs(e.clientY - dragStart.current.my)
    // Only open picker if it was a tap, not a drag
    if (dx < 5 && dy < 5) setPicking(true)
  }

  if (timer) return null
  if (pos.x === -1) return null

  return (
    <>
      {/* Draggable FAB */}
      <div
        ref={btnRef}
        className="fixed z-40 select-none touch-none"
        style={{
          left: pos.x,
          top: pos.y,
          width: SIZE,
          height: SIZE,
          opacity: dragging ? 0.5 : 1,
          transition: dragging ? 'none' : 'opacity 0.2s',
          cursor: dragging ? 'grabbing' : 'grab',
        }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
      >
        <div className="w-full h-full flex items-center justify-center rounded-full bg-green-500 text-white shadow-lg">
          <Play size={22} fill="white" />
        </div>
      </div>

      {/* Hobby picker */}
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
