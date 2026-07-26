import { useRef } from 'react'

export function useLongPress(
  onLongPress: (e: React.TouchEvent) => void,
  onTap?: (e: React.TouchEvent) => void,
  delay = 500
) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const startPos = useRef<{ x: number; y: number } | null>(null)
  const fired = useRef(false)

  function onTouchStart(e: React.TouchEvent) {
    // Prevent iOS context menu / text selection on long press
    e.preventDefault()
    fired.current = false
    startPos.current = { x: e.touches[0].clientX, y: e.touches[0].clientY }
    timer.current = setTimeout(() => {
      fired.current = true
      onLongPress(e)
    }, delay)
  }

  function onTouchMove(e: React.TouchEvent) {
    if (!startPos.current || !timer.current) return
    const dx = Math.abs(e.touches[0].clientX - startPos.current.x)
    const dy = Math.abs(e.touches[0].clientY - startPos.current.y)
    if (dx > 10 || dy > 10) {
      clearTimeout(timer.current)
      timer.current = null
    }
  }

  function onTouchEnd(e: React.TouchEvent) {
    if (timer.current) {
      clearTimeout(timer.current)
      timer.current = null
    }
    if (!fired.current && onTap) onTap(e)
    fired.current = false
  }

  return { onTouchStart, onTouchMove, onTouchEnd }
}
