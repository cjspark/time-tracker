'use client'

export type View = 'day' | '2day' | 'week'

type Props = {
  view: View
  onChange: (v: View) => void
}

const OPTIONS: { value: View; label: string }[] = [
  { value: 'day',  label: '日' },
  { value: '2day', label: '两日' },
  { value: 'week', label: '周' },
]

export default function ViewSwitcher({ view, onChange }: Props) {
  return (
    <div className="flex bg-gray-100 rounded-xl p-0.5">
      {OPTIONS.map((o) => (
        <button
          key={o.value}
          onClick={() => onChange(o.value)}
          className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
            view === o.value ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500'
          }`}
        >
          {o.label}
        </button>
      ))}
    </div>
  )
}
