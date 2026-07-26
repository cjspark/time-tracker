'use client'

// Generates all 15-minute slots for a day: ["00:00", "00:15", ...]
const SLOTS: string[] = []
for (let h = 0; h < 24; h++) {
  for (const m of [0, 15, 30, 45]) {
    SLOTS.push(`${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`)
  }
}

// Round a HH:MM string to nearest 15-min slot
export function snapTo15(time: string): string {
  const [h, m] = time.split(':').map(Number)
  const snapped = Math.round(m / 15) * 15
  if (snapped === 60) return `${String(h + 1).padStart(2, '0')}:00`
  return `${String(h).padStart(2, '0')}:${String(snapped).padStart(2, '0')}`
}

type Props = {
  value: string       // HH:MM
  onChange: (v: string) => void
  className?: string
}

export default function TimeSelect({ value, onChange, className = '' }: Props) {
  // Display 12h format label
  function label(t: string) {
    const [h, m] = t.split(':').map(Number)
    const period = h < 12 ? 'AM' : 'PM'
    const h12 = h === 0 ? 12 : h > 12 ? h - 12 : h
    return `${h12}:${String(m).padStart(2, '0')} ${period}`
  }

  const snapped = snapTo15(value)

  return (
    <select
      value={snapped}
      onChange={e => onChange(e.target.value)}
      className={`px-2 py-1.5 border border-gray-200 rounded-lg text-xs focus:outline-none focus:ring-1 focus:ring-blue-500 bg-white ${className}`}
    >
      {SLOTS.map(s => (
        <option key={s} value={s}>{label(s)}</option>
      ))}
    </select>
  )
}
