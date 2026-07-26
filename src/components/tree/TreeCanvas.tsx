'use client'

import { useState } from 'react'
import type { BranchData, Achievement, AchievementTemplate, AchievementMeta } from './useTreeData'
import { isInvestmentCategory } from './useTreeData'
import AchievementModal from './AchievementModal'
import RecordModal from './RecordModal'

type Props = {
  branches: BranchData[]
  onAddAchievement: (data: { category: string; name: string; unit: string; target_value: number; template?: AchievementTemplate; metadata?: AchievementMeta; parent_id?: string }) => Promise<void>
  onAddRecord: (achievement_id: string, data: { value: number; note: string; date: string }) => Promise<void>
  onDeleteRecord: (id: string) => Promise<void>
  onDeleteAchievement: (id: string) => Promise<void>
  onUpdateTarget: (id: string, target_value: number) => Promise<void>
}

const W = 360
const H = 560
const CX = W / 2  // canopy center x
const CY = 200    // canopy center y

// Zone positions within canopy for up to 6 branches
const ZONES = [
  { x: CX - 88, y: CY - 75 },
  { x: CX + 88, y: CY - 75 },
  { x: CX - 110, y: CY + 15 },
  { x: CX + 110, y: CY + 15 },
  { x: CX - 40,  y: CY - 110 },
  { x: CX + 40,  y: CY - 110 },
]

function NodeOrb({ x, y, r, fill, stroke, label, sub, onClick }: {
  x: number; y: number; r: number
  fill: string; stroke: string
  label: string; sub?: string
  onClick: () => void
}) {
  return (
    <g onClick={onClick} style={{ cursor: 'pointer' }}>
      {/* Drop shadow */}
      <circle cx={x + 2} cy={y + 3} r={r} fill="rgba(0,0,0,0.15)" />
      {/* Main orb */}
      <circle cx={x} cy={y} r={r} fill={fill} stroke={stroke} strokeWidth={1.5} />
      {/* Glass highlight */}
      <ellipse cx={x - r * 0.25} cy={y - r * 0.3} rx={r * 0.35} ry={r * 0.22}
        fill="rgba(255,255,255,0.45)" />
      {/* Label */}
      <text x={x} y={y + r + 11} textAnchor="middle"
        fontSize={9} fontWeight="600" fill="#1a3a1a"
        style={{ userSelect: 'none', pointerEvents: 'none' }}>
        {label.length > 6 ? label.slice(0, 6) + '…' : label}
      </text>
      {sub && (
        <text x={x} y={y + r + 21} textAnchor="middle"
          fontSize={8} fill="#4a6a4a"
          style={{ userSelect: 'none', pointerEvents: 'none' }}>
          {sub}
        </text>
      )}
    </g>
  )
}

function BranchZone({ branch, zx, zy, onSelectAchievement, onAddAchievement }: {
  branch: BranchData; zx: number; zy: number
  onSelectAchievement: (a: Achievement) => void
  onAddAchievement: () => void
}) {
  const maxMin = branch.maxMinutes || 1
  // Arrange up to 3 green + 3 red in a small cluster
  const items: { key: string; label: string; r: number; fill: string; stroke: string; sub: string; onClick: () => void }[] = []

  branch.hobbies.slice(0, 3).forEach((h, i) => {
    const r = Math.max(14, Math.min(22, 14 + (h.totalMinutes / maxMin) * 8))
    items.push({
      key: h.label,
      label: h.label,
      r,
      fill: h.color + 'cc',
      stroke: h.color,
      sub: h.totalMinutes >= 60
        ? `${Math.floor(h.totalMinutes / 60)}h`
        : `${h.totalMinutes}m`,
      onClick: () => {},
    })
  })

  branch.achievements.slice(0, 3).forEach((a) => {
    const isComplete = a.progress >= 1
    const r = Math.max(14, Math.min(22, 14 + a.progress * 8))
    items.push({
      key: a.id,
      label: a.name,
      r,
      fill: isComplete ? '#FEF08A' : '#FECACA',
      stroke: isComplete ? '#EAB308' : '#EF4444',
      sub: `${Math.round(a.progress * 100)}%`,
      onClick: () => onSelectAchievement(a),
    })
  })

  // Position items in a small fan around zone center
  const offsets = [
    { dx: 0, dy: 0 },
    { dx: -28, dy: -8 },
    { dx: 28, dy: -8 },
    { dx: -14, dy: 24 },
    { dx: 14, dy: 24 },
    { dx: 0, dy: -30 },
  ]

  return (
    <g>
      {/* Zone label */}
      <text x={zx} y={zy - 32} textAnchor="middle"
        fontSize={10} fontWeight="700" fill="#14532d"
        style={{ userSelect: 'none' }}>
        {branch.displayName}
      </text>

      {/* Nodes */}
      {items.map((item, i) => {
        const off = offsets[i] ?? { dx: 0, dy: 0 }
        return (
          <NodeOrb key={item.key}
            x={zx + off.dx} y={zy + off.dy}
            r={item.r} fill={item.fill} stroke={item.stroke}
            label={item.label} sub={item.sub}
            onClick={item.onClick}
          />
        )
      })}

      {/* Add achievement button */}
      <g onClick={onAddAchievement} style={{ cursor: 'pointer' }}>
        <circle cx={zx + 34} cy={zy - 18} r={9}
          fill="rgba(255,255,255,0.7)" stroke="#EF4444" strokeWidth={1.2} strokeDasharray="2,2" />
        <text x={zx + 34} y={zy - 18} textAnchor="middle" dominantBaseline="middle"
          fontSize={13} fill="#EF4444" style={{ userSelect: 'none' }}>+</text>
      </g>
    </g>
  )
}

export default function TreeCanvas({
  branches, onAddAchievement, onAddRecord,
  onDeleteRecord, onDeleteAchievement, onUpdateTarget
}: Props) {
  const [selectedAchievement, setSelectedAchievement] = useState<Achievement | null>(null)
  const [addingToBranch, setAddingToBranch] = useState<BranchData | null>(null)

  if (branches.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center flex-1 text-gray-300 gap-3 py-20">
        <span className="text-5xl">🌱</span>
        <p className="text-sm">先在日历中记录时间，树枝就会生长</p>
      </div>
    )
  }

  const sorted = [...branches].sort((a, b) =>
    b.hobbies.reduce((s, h) => s + h.totalMinutes, 0) -
    a.hobbies.reduce((s, h) => s + h.totalMinutes, 0)
  )

  return (
    <div className="flex flex-col items-center w-full">
      <svg viewBox={`0 0 ${W} ${H}`} width="100%" style={{ maxWidth: 420 }}>
        <defs>
          {/* Sky gradient */}
          <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#bae6fd" />
            <stop offset="60%" stopColor="#d1fae5" />
            <stop offset="100%" stopColor="#bbf7d0" />
          </linearGradient>

          {/* Trunk gradient */}
          <linearGradient id="trunk" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%"   stopColor="#78350f" />
            <stop offset="30%"  stopColor="#b45309" />
            <stop offset="60%"  stopColor="#d97706" />
            <stop offset="100%" stopColor="#78350f" />
          </linearGradient>

          {/* Canopy layers */}
          <radialGradient id="canopy1" cx="45%" cy="40%">
            <stop offset="0%"   stopColor="#4ade80" stopOpacity="0.95" />
            <stop offset="60%"  stopColor="#16a34a" stopOpacity="0.97" />
            <stop offset="100%" stopColor="#14532d" stopOpacity="1" />
          </radialGradient>
          <radialGradient id="canopy2" cx="55%" cy="35%">
            <stop offset="0%"   stopColor="#86efac" stopOpacity="0.8" />
            <stop offset="100%" stopColor="#22c55e" stopOpacity="0" />
          </radialGradient>
          <radialGradient id="canopyTop" cx="40%" cy="30%">
            <stop offset="0%"   stopColor="#bbf7d0" stopOpacity="0.6" />
            <stop offset="100%" stopColor="#4ade80" stopOpacity="0" />
          </radialGradient>

          {/* Ground gradient */}
          <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%"   stopColor="#4ade80" />
            <stop offset="100%" stopColor="#15803d" />
          </linearGradient>

          <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="0" dy="4" stdDeviation="6" floodOpacity="0.2" />
          </filter>
        </defs>

        {/* Sky background */}
        <rect width={W} height={H} fill="url(#sky)" />

        {/* Distant hills */}
        <ellipse cx={80}  cy={H - 20} rx={130} ry={50} fill="#86efac" opacity={0.4} />
        <ellipse cx={290} cy={H - 15} rx={120} ry={45} fill="#6ee7b7" opacity={0.35} />

        {/* Ground */}
        <ellipse cx={CX} cy={H - 10} rx={175} ry={38} fill="url(#ground)" />
        <ellipse cx={CX} cy={H - 10} rx={175} ry={38} fill="url(#ground)" />

        {/* ── TRUNK ── */}
        {/* Trunk roots / base spread */}
        <path d={`M ${CX - 68} ${H - 22} C ${CX - 52} ${H - 60}, ${CX - 38} ${H - 100}, ${CX - 26} ${H - 160}`}
          fill="none" stroke="#78350f" strokeWidth={18} strokeLinecap="round" opacity={0.6} />
        <path d={`M ${CX + 68} ${H - 22} C ${CX + 52} ${H - 60}, ${CX + 38} ${H - 100}, ${CX + 26} ${H - 160}`}
          fill="none" stroke="#78350f" strokeWidth={18} strokeLinecap="round" opacity={0.6} />

        {/* Main trunk body */}
        <path d={`
          M ${CX - 42} ${H - 18}
          C ${CX - 44} ${H - 100}, ${CX - 38} ${H - 200}, ${CX - 22} ${H - 290}
          C ${CX - 14} ${H - 320}, ${CX - 8}  ${H - 338}, ${CX}     ${H - 342}
          C ${CX + 8}  ${H - 338}, ${CX + 14} ${H - 320}, ${CX + 22} ${H - 290}
          C ${CX + 38} ${H - 200}, ${CX + 44} ${H - 100}, ${CX + 42} ${H - 18}
          Z
        `} fill="url(#trunk)" filter="url(#shadow)" />

        {/* Trunk texture */}
        {[0.2, 0.38, 0.55, 0.70].map((t, i) => {
          const y = H - 18 - t * 324
          const w = 38 - t * 16
          return (
            <path key={i}
              d={`M ${CX - w} ${y} Q ${CX + 4} ${y - 8} ${CX + w - 4} ${y + 4}`}
              fill="none" stroke="#92400e" strokeWidth={2} opacity={0.35} strokeLinecap="round"
            />
          )
        })}

        {/* ── CANOPY ── */}
        {/* Base shadow */}
        <ellipse cx={CX + 6} cy={CY + 8} rx={158} ry={152} fill="#14532d" opacity={0.35} />
        {/* Main canopy */}
        <ellipse cx={CX} cy={CY} rx={156} ry={150} fill="url(#canopy1)" filter="url(#shadow)" />
        {/* Bumpy canopy top-left cluster */}
        <ellipse cx={CX - 70} cy={CY - 80} rx={80} ry={75} fill="#22c55e" opacity={0.55} />
        {/* Bumpy canopy top-right cluster */}
        <ellipse cx={CX + 65} cy={CY - 85} rx={75} ry={70} fill="#16a34a" opacity={0.5} />
        {/* Bumpy top center */}
        <ellipse cx={CX + 5}  cy={CY - 110} rx={65} ry={58} fill="#4ade80" opacity={0.5} />
        {/* Highlight overlay */}
        <ellipse cx={CX - 20} cy={CY - 30} rx={110} ry={100} fill="url(#canopy2)" />
        {/* Specular highlight */}
        <ellipse cx={CX - 35} cy={CY - 60} rx={70}  ry={55}  fill="url(#canopyTop)" />

        {/* ── BRANCHES & DATA NODES (on top of canopy) ── */}
        {sorted.slice(0, 6).map((branch, i) => {
          const zone = ZONES[i] ?? ZONES[0]
          return (
            <BranchZone
              key={branch.category}
              branch={branch}
              zx={zone.x}
              zy={zone.y}
              onSelectAchievement={setSelectedAchievement}
              onAddAchievement={() => setAddingToBranch(branch)}
            />
          )
        })}

        {/* Canopy edge detail dots */}
        {[
          [CX - 148, CY + 20], [CX + 145, CY + 15],
          [CX - 130, CY - 100], [CX + 128, CY - 95],
          [CX - 60,  CY + 140], [CX + 55,  CY + 142],
        ].map(([ex, ey], i) => (
          <circle key={i} cx={ex} cy={ey} r={12 + (i % 3) * 5}
            fill="#22c55e" opacity={0.45} />
        ))}
      </svg>

      {/* Modals */}
      {selectedAchievement && (
        <RecordModal
          achievement={selectedAchievement}
          maxMinutes={branches.find(b => b.achievements.some(a => a.id === selectedAchievement.id))?.maxMinutes ?? 0}
          onAddRecord={data => onAddRecord(selectedAchievement.id, data)}
          onDeleteRecord={onDeleteRecord}
          onDeleteAchievement={() => onDeleteAchievement(selectedAchievement.id)}
          onUpdateTarget={v => onUpdateTarget(selectedAchievement.id, v)}
          onArchive={async () => { setSelectedAchievement(null) }}
          onClose={() => setSelectedAchievement(null)}
        />
      )}
      {addingToBranch && (
        <AchievementModal
          category={addingToBranch.category}
          isInvestment={isInvestmentCategory(addingToBranch.displayName)}
          onSave={onAddAchievement}
          onClose={() => setAddingToBranch(null)}
        />
      )}
    </div>
  )
}
