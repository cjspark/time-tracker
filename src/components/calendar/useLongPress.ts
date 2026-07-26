import { useRef } from 'react'

export function useLongPress(
  onLongPress: (e: React.TouchEvent) => void,
  onTap?: (e: React.TouchEvent) => void,
  delay = 400
) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const startPos = useRef<{ x: number; y: number } | null>(null)
  const fired = useRef(false)
  const moved = useRef(false)

  function onTouchStart(e: React.TouchEvent) {
    fired.current = false
    moved.current = false
    startPos.current = { x: e.touches[0].clientX, y: e.touches[0].clientY }
    timer.current = setTimeout(() => {
      if (!moved.current) {
        fired.current = true
        onLongPress(e)
      }
    }, delay)
  }

  function onTouchMove(e: React.TouchEvent) {
    if (!startPos.current) return
    const dx = Math.abs(e.touches[0].clientX - startPos.current.x)
    const dy = Math.abs(e.touches[0].clientY - startPos.current.y)
    if (dx > 8 || dy > 8) {
      moved.current = true
      if (timer.current) {
        clearTimeout(timer.current)
        timer.current = null
      }
    }
  }

  function onTouchEnd(e: React.TouchEvent) {
    if (timer.current) {
      clearTimeout(timer.current)
      timer.current = null
    }
    if (!fired.current && !moved.current && onTap) onTap(e)
    fired.current = false
    moved.current = false
  }

  return { onTouchStart, onTouchMove, onTouchEnd }
}
