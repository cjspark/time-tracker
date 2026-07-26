'use client'

import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useReviewData } from '@/lib/useReviewData'
import { TIME_CATEGORIES } from '@/components/HobbiesView'
import type { TimeCategory } from '@/components/HobbiesView'

const DAY_LABELS = ['一', '二', '三', '四', '五', '六', '日']

function formatMinutes(m: number): string {
  if (m === 0) return '0m'
  if (m < 60) return `${m}m`
  const h = Math.floor(m / 60)
  const min = m % 60
  return min === 0 ? `${h}h` : `${h}h${min}m`
}

// ── Pie Chart (SVG) ───────────────────────────────────────────────────
function PieChart({ byCategory, total, untracked }: {
  byCategory: Record<TimeCategory, number>
  total: number
  untracked: number
}) {
  const R = 70
  const CX = 90
  const CY = 90
  const size = 180
  const grandTotal = total + untracked

  if (grandTotal === 0) {
    return (
      <div className="flex flex-col items-center justify-center" style={{ width: size, height: size }}>
        <div className="w-36 h-36 rounded-full border-4 border-dashed border-gray-200 flex items-center justify-center">
          <span className="text-xs text-gray-300">暂无数据</span>
        </div>
      </div>
    )
  }

  let startAngle = -Math.PI / 2
  const slices: { path: string; color: string }[] = []

  const allSlices = [
    ...TIME_CATEGORIES.map(tc => ({ mins: byCategory[tc.key] ?? 0, color: tc.color })),
    { mins: untracked, color: '#E5E7EB' },
  ]

  for (const { mins, color } of allSlices) {
    if (mins === 0) continue
    const pct = mins / grandTotal
    const angle = pct * 2 * Math.PI
    const endAngle = startAngle + angle
    const x1 = CX + R * Math.cos(startAngle)
    const y1 = CY + R * Math.sin(startAngle)
    const x2 = CX + R * Math.cos(endAngle)
    const y2 = CY + R * Math.sin(endAngle)
    const largeArc = angle > Math.PI ? 1 : 0
    slices.push({
      path: `M ${CX} ${CY} L ${x1} ${y1} A ${R} ${R} 0 ${largeArc} 1 ${x2} ${y2} Z`,
      color,
    })
    startAngle = endAngle
  }

  return (
    <svg width={size} height={size}>
      {slices.map((s, i) => (
        <path key={i} d={s.path} fill={s.color} opacity={0.9} />
      ))}
      {/* Center hole */}
      <circle cx={CX} cy={CY} r={R * 0.45} fill="white" />
      <text x={CX} y={CY - 6} textAnchor="middle" fontSize={11} fill="#6B7280">已记录</text>
      <text x={CX} y={CY + 10} textAnchor="middle" fontSize={13} fontWeight="600" fill="#111827">
        {formatMinutes(total)}
      </text>
    </svg>
  )
}

// ── Bar Chart ─────────────────────────────────────────────────────────
function WeekBarChart({ byDay }: { byDay: { date: string; byCategory: Record<TimeCategory, number>; untracked: number }[] }) {
  const maxMinutes = Math.max(...byDay.map(d =>
    Object.values(d.byCategory).reduce((a, b) => a + b, 0) + d.untracked
  ), 1)
  const BAR_H = 100

  return (
    <div className="flex items-end justify-between gap-1 px-1" style={{ height: BAR_H + 32 }}>
      {byDay.map((day, i) => {
        const recorded = Object.values(day.byCategory).reduce((a, b) => a + b, 0)
        const total = recorded + day.untracked
        const barHeight = total > 0 ? Math.max(4, (total / maxMinutes) * BAR_H) : 0

        const segments: { color: string; height: number }[] = []
        if (recorded > 0) {
          TIME_CATEGORIES.forEach(tc => {
            const mins = day.byCategory[tc.key] ?? 0
            if (mins > 0) segments.push({ color: tc.color, height: (mins / total) * barHeight })
          })
        }
        if (day.untracked > 0) {
          segments.push({ color: '#E5E7EB', height: (day.untracked / total) * barHeight })
        }

        return (
          <div key={day.date} className="flex flex-col items-center gap-1 flex-1">
            <div className="w-full rounded-t-lg overflow-hidden flex flex-col-reverse" style={{ height: BAR_H }}>
              {total === 0 ? (
                <div className="w-full rounded-t-lg bg-gray-100" style={{ height: 4 }} />
              ) : (
                <div className="w-full flex flex-col-reverse" style={{ height: barHeight }}>
                  {segments.map((seg, si) => (
                    <div key={si} style={{ height: seg.height, backgroundColor: seg.color, opacity: 0.85 }} />
                  ))}
                </div>
              )}
            </div>
            <span className="text-xs text-gray-400">{DAY_LABELS[i]}</span>
          </div>
        )
      })}
    </div>
  )
}

// ── Category Row ──────────────────────────────────────────────────────
function CategoryRow({ tc, currentMins, avgMins }: {
  tc: typeof TIME_CATEGORIES[number]
  currentMins: number
  avgMins: number
}) {
  const diff = currentMins - avgMins
  const diffLabel = diff === 0 ? '持平'
    : diff > 0 ? `↑ +${formatMinutes(diff)}`
    : `↓ -${formatMinutes(Math.abs(diff))}`
  const diffColor = diff > 0 ? '#10B981' : diff < 0 ? '#EF4444' : '#9CA3AF'

  // Progress bar: relative to avg (avg = 100%)
  const maxMins = Math.max(currentMins, avgMins, 1)
  const currentPct = (currentMins / maxMins) * 100
  const avgPct = (avgMins / maxMins) * 100

  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: tc.color }} />
          <span className="text-sm font-medium text-gray-700">{tc.label}</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm font-semibold text-gray-800">{formatMinutes(currentMins)}</span>
          <span className="text-xs font-medium" style={{ color: diffColor }}>{diffLabel}</span>
        </div>
      </div>
      {/* Stacked bar: current vs avg */}
      <div className="relative h-2 bg-gray-100 rounded-full overflow-hidden">
        {/* avg marker */}
        <div
          className="absolute top-0 h-full rounded-full opacity-30"
          style={{ width: `${avgPct}%`, backgroundColor: tc.color }}
        />
        {/* current */}
        <div
          className="absolute top-0 h-full rounded-full"
          style={{ width: `${currentPct}%`, backgroundColor: tc.color, opacity: 0.85 }}
        />
      </div>
      <div className="flex justify-between text-xs text-gray-300">
        <span>本周 {formatMinutes(currentMins)}</span>
        <span>4周均 {formatMinutes(avgMins)}</span>
      </div>
    </div>
  )
}

// ── Page ──────────────────────────────────────────────────────────────
export default function ReviewPage() {
  const { currentWeek, avgWeek, loading, weekOffset, setWeekOffset } = useReviewData()

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-white shrink-0">
        <span className="text-base font-semibold text-gray-800">复盘</span>
        <div className="flex items-center gap-2">
          <button onClick={() => setWeekOffset(w => w - 1)} className="p-1.5 rounded-full hover:bg-gray-100 text-gray-400">
            <ChevronLeft size={16} />
          </button>
          <span className="text-sm text-gray-600 w-28 text-center">
            {currentWeek?.weekLabel ?? '...'}
          </span>
          <button
            onClick={() => setWeekOffset(w => Math.min(0, w + 1))}
            disabled={weekOffset >= 0}
            className="p-1.5 rounded-full hover:bg-gray-100 text-gray-400 disabled:opacity-30"
          >
            <ChevronRight size={16} />
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 pb-24 space-y-4">
        {loading ? (
          <div className="flex items-center justify-center py-20 text-gray-300 text-sm">加载中...</div>
        ) : !currentWeek ? null : (
          <>
            {/* Pie chart + legend */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4">
              <p className="text-xs font-medium text-gray-500 mb-3">本周时间分布</p>
              <div className="flex items-center gap-4">
                <PieChart byCategory={currentWeek.byCategory} total={currentWeek.totalMinutes} untracked={currentWeek.untracked} />
                {/* Legend */}
                <div className="flex-1 space-y-2">
                  {TIME_CATEGORIES.map(tc => {
                    const mins = currentWeek.byCategory[tc.key] ?? 0
                    const grandTotal = currentWeek.totalMinutes + currentWeek.untracked
                    const pct = grandTotal > 0 ? Math.round((mins / grandTotal) * 100) : 0
                    return (
                      <div key={tc.key} className="flex items-center justify-between">
                        <div className="flex items-center gap-1.5">
                          <span className="w-2 h-2 rounded-full" style={{ backgroundColor: tc.color }} />
                          <span className="text-xs text-gray-600">{tc.label}</span>
                        </div>
                        <span className="text-xs font-medium text-gray-500">{pct}%</span>
                      </div>
                    )
                  })}
                  {currentWeek.untracked > 0 && (
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-gray-200" />
                        <span className="text-xs text-gray-400">未追踪</span>
                      </div>
                      <span className="text-xs font-medium text-gray-400">
                        {(() => {
                          const g = currentWeek.totalMinutes + currentWeek.untracked
                          return g > 0 ? Math.round(currentWeek.untracked / g * 100) + '%' : '0%'
                        })()}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Bar chart */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4">
              <p className="text-xs font-medium text-gray-500 mb-3">每日分布</p>
              <WeekBarChart byDay={currentWeek.byDay} />
              {/* Color legend */}
              <div className="flex flex-wrap gap-3 mt-3">
                {TIME_CATEGORIES.map(tc => (
                  <div key={tc.key} className="flex items-center gap-1">
                    <span className="w-2 h-2 rounded-full" style={{ backgroundColor: tc.color }} />
                    <span className="text-xs text-gray-400">{tc.label}</span>
                  </div>
                ))}
                <div className="flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-gray-200" />
                  <span className="text-xs text-gray-400">未追踪</span>
                </div>
              </div>
            </div>

            {/* Category comparison */}
            <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4 space-y-4">
              <div className="flex items-center justify-between">
                <p className="text-xs font-medium text-gray-500">四类时间对比</p>
                <span className="text-xs text-gray-300">vs 近4周均</span>
              </div>
              {TIME_CATEGORIES.map(tc => (
                <CategoryRow
                  key={tc.key}
                  tc={tc}
                  currentMins={currentWeek.byCategory[tc.key] ?? 0}
                  avgMins={avgWeek?.byCategory[tc.key] ?? 0}
                />
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  )
}
