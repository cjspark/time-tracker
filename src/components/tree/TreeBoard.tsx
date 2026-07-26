'use client'

import { useState, useMemo } from 'react'
import Image from 'next/image'
import type { BranchData } from './useTreeData'
import { getTreeStage, getFruitStage, getTreeImageSrc, getFruitImageSrc } from './treeUtils'

const SCENE_W = 360
const SCENE_H = 300

type TreeNode = {
  key: string
  hobby: string
  color: string
  type: 'timer' | 'checkin'
  totalMinutes: number
  achievementCount: number
  isArchived: boolean
  displayName: string
  // scene coords (pixels)
  x: number
  y: number
  size: number   // image size px
  zIndex: number
}

// Deterministic pseudo-random from string seed
function seedRand(seed: string, index: number, range: number, offset = 0): number {
  let h = 5381
  for (let i = 0; i < seed.length; i++) h = ((h << 5) + h) ^ seed.charCodeAt(i)
  h = (h ^ (index * 2654435761)) >>> 0
  return offset + (h / 0xFFFFFFFF) * range
}

// Build tree placements: grouped by category, organic positions
function buildPlacements(
  branches: BranchData[],
  inactiveHobbies: string[],
  habitLabels: string[]
): TreeNode[] {
  const sorted = [...branches]
    .filter(b => b.hobbies.length > 0)
    .sort((a, b) =>
      b.hobbies.reduce((s, h) => s + h.totalMinutes, 0) -
      a.hobbies.reduce((s, h) => s + h.totalMinutes, 0)
    )

  const nodes: TreeNode[] = []
  const totalCats = sorted.length
  if (totalCats === 0) return []

  // Divide scene into vertical bands per category
  const bandW = SCENE_W / Math.max(totalCats, 1)

  sorted.forEach((branch, bi) => {
    const bandLeft = bi * bandW
    const hobbies = [...branch.hobbies].sort((a, b) => b.totalMinutes - a.totalMinutes)

    // Arrange within band: columns of 2-3 trees
    const cols = Math.ceil(hobbies.length / 3) || 1
    const colW = bandW / cols

    hobbies.forEach((hobby, hi) => {
      const col = hi % cols
      const row = Math.floor(hi / cols)

      const stage = getTreeStage(hobby.totalMinutes / 60)
      // Size: stage 1=40, 5=90, scaled by row depth
      const baseSize = 40 + stage * 10
      // rows further back (row 0) are smaller; front (row 2) larger
      const depthScale = 0.75 + row * 0.12
      const size = baseSize * depthScale

      // y: spread across vertical range, back rows near top
      // rows: 0=back(top), 1=mid, 2=front(bottom)
      const yBase = 80 + row * 65
      const yJitter = seedRand(`${branch.category}-${hi}`, hi + 7, 28, -14)
      const y = yBase + yJitter

      // x: within column + jitter
      const xBase = bandLeft + col * colW + colW / 2
      const xJitter = seedRand(`${branch.category}-${hi}`, hi, colW * 0.3, -colW * 0.15)
      const x = Math.max(size / 2, Math.min(SCENE_W - size / 2, xBase + xJitter))

      nodes.push({
        key: `${branch.category}-${hobby.label}`,
        hobby: hobby.label,
        color: hobby.color,
        type: habitLabels.includes(hobby.label) ? 'checkin' : 'timer',
        totalMinutes: hobby.totalMinutes,
        achievementCount: branch.achievements.filter(a => !a.parent_id).length,
        isArchived: inactiveHobbies.includes(hobby.label),
        displayName: branch.displayName,
        x,
        y,
        size,
        zIndex: Math.round(y),
      })
    })
  })

  return nodes.sort((a, b) => a.zIndex - b.zIndex)
}

type Props = {
  branches: BranchData[]
  inactiveHobbies?: string[]
  habitLabels?: string[]
  onNodeTap?: (hobby: string) => void
}

function SceneTree({ node, onClick }: { node: TreeNode; onClick: () => void }) {
  const [hovered, setHovered] = useState(false)
  const stage = getTreeStage(node.totalMinutes / 60)
  const fruitStage = stage === 5 ? getFruitStage(node.achievementCount) : 'none'
  const treeSrc = getTreeImageSrc(stage)
  const fruitSrc = fruitStage !== 'none' ? getFruitImageSrc(fruitStage) : null

  const imgFilter = [
    node.type === 'checkin' ? 'hue-rotate(140deg) saturate(0.9)' : '',
    node.isArchived ? 'grayscale(0.65) opacity(0.65)' : '',
  ].filter(Boolean).join(' ') || undefined

  return (
    <div
      onClick={onClick}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      className="absolute cursor-pointer select-none"
      style={{
        left: node.x - node.size / 2,
        bottom: SCENE_H - node.y - node.size * 0.1,
        width: node.size,
        height: node.size * 1.3,
        zIndex: node.zIndex,
        animation: node.isArchived ? undefined : `treeSway ${4 + (node.zIndex % 3)}s ease-in-out infinite`,
        animationDelay: `${seedRand(node.key, 0, 2, 0).toFixed(2)}s`,
      }}
    >
      {/* Shadow */}
      <div
        className="absolute bottom-0 left-1/2 -translate-x-1/2 rounded-full"
        style={{
          width: node.size * 0.6,
          height: node.size * 0.12,
          background: 'rgba(0,0,0,0.18)',
          filter: 'blur(4px)',
          zIndex: -1,
        }}
      />

      {/* Tree image */}
      <div className="relative w-full h-full" style={{ filter: imgFilter }}>
        <Image
          src={treeSrc}
          alt={node.hobby}
          fill
          className="object-contain object-bottom"
          sizes={`${node.size}px`}
        />
        {/* Fruit */}
        {fruitSrc && (
          <div className="absolute top-1 right-0" style={{ width: node.size * 0.35, height: node.size * 0.35 }}>
            <Image src={fruitSrc} alt="fruit" fill className="object-contain" sizes={`${node.size * 0.35}px`} />
          </div>
        )}
      </div>

      {/* Hover label */}
      {hovered && (
        <div
          className="absolute -top-8 left-1/2 -translate-x-1/2 bg-gray-900/85 text-white text-xs rounded-lg px-2 py-1 whitespace-nowrap z-50 shadow-lg"
          style={{ zIndex: 999 }}
        >
          {node.hobby}
        </div>
      )}
    </div>
  )
}

export default function TreeBoard({ branches, inactiveHobbies = [], habitLabels = [], onNodeTap }: Props) {
  const [selected, setSelected] = useState<TreeNode | null>(null)

  const nodes = useMemo(
    () => buildPlacements(branches, inactiveHobbies, habitLabels),
    [branches, inactiveHobbies, habitLabels]
  )

  if (nodes.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-20 text-gray-300 gap-3">
        <span className="text-5xl">🌱</span>
        <p className="text-sm">先在日历中记录时间，树木就会生长</p>
      </div>
    )
  }

  return (
    <>
      <style>{`
        @keyframes treeSway {
          0%, 100% { transform: rotate(-1.2deg) translateX(0); }
          50%       { transform: rotate(1.2deg) translateX(1px); }
        }
      `}</style>

      <div className="mx-3">
        {/* Forest scene */}
        <div
          className="relative overflow-hidden rounded-3xl shadow-lg"
          style={{
            width: '100%',
            height: SCENE_H,
            background: 'linear-gradient(180deg, #1a4731 0%, #1e5c3a 40%, #2d7a4f 70%, #3a9660 100%)',
          }}
        >
          {/* Sky glow */}
          <div
            className="absolute inset-0 pointer-events-none"
            style={{
              background: 'radial-gradient(ellipse 80% 40% at 50% 0%, rgba(100,200,120,0.18) 0%, transparent 70%)',
            }}
          />

          {/* Ground / grass layer */}
          <div
            className="absolute bottom-0 left-0 right-0"
            style={{
              height: 60,
              background: 'linear-gradient(180deg, transparent 0%, rgba(20,80,35,0.6) 60%, rgba(15,60,25,0.95) 100%)',
            }}
          />

          {/* Grass texture dots */}
          <div
            className="absolute bottom-0 left-0 right-0 pointer-events-none"
            style={{ height: 40, opacity: 0.3 }}
          >
            {Array.from({ length: 20 }, (_, i) => (
              <div
                key={i}
                className="absolute rounded-full bg-green-400"
                style={{
                  width: 2 + (i % 3),
                  height: 6 + (i % 5),
                  left: `${(i / 20) * 100 + seedRand('grass', i, 4, -2)}%`,
                  bottom: seedRand('grassY', i, 14),
                }}
              />
            ))}
          </div>

          {/* Category zone labels */}
          <div className="absolute top-3 left-3 right-3 flex flex-wrap gap-1.5 pointer-events-none">
            {branches.filter(b => b.hobbies.length > 0).map(b => (
              <span
                key={b.category}
                className="text-xs px-2 py-0.5 rounded-full font-medium backdrop-blur-sm"
                style={{ background: 'rgba(255,255,255,0.15)', color: 'rgba(255,255,255,0.85)' }}
              >
                {b.displayName}
              </span>
            ))}
          </div>

          {/* Trees */}
          <div className="absolute inset-0">
            {nodes.map(node => (
              <SceneTree
                key={node.key}
                node={node}
                onClick={() => setSelected(node)}
              />
            ))}
          </div>

          {/* Bottom stats */}
          <div className="absolute bottom-3 right-4 flex items-center gap-3 pointer-events-none">
            <span className="text-xs text-white/70">
              🌳 {nodes.filter(n => !n.isArchived).length} 棵
            </span>
            <span className="text-xs text-white/70">
              🏅 {nodes.reduce((s, n) => s + n.achievementCount, 0)} 成就
            </span>
          </div>
        </div>

        {/* Tree detail modal */}
        {selected && (
          <div
            className="fixed inset-0 z-[200] flex items-end justify-center bg-black/50"
            onClick={() => setSelected(null)}
          >
            <div
              className="w-full max-w-lg bg-white rounded-t-3xl p-5 mb-16 space-y-4"
              onClick={e => e.stopPropagation()}
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-16 h-16 relative rounded-2xl overflow-hidden flex items-center justify-center"
                  style={{ background: selected.color + '18' }}
                >
                  <Image
                    src={getTreeImageSrc(getTreeStage(selected.totalMinutes / 60))}
                    alt={selected.hobby}
                    fill
                    className="object-contain p-1"
                    style={{ filter: selected.type === 'checkin' ? 'hue-rotate(140deg) saturate(0.9)' : undefined }}
                    sizes="64px"
                  />
                </div>
                <div>
                  <p className="font-semibold text-gray-800 text-base">{selected.hobby}</p>
                  <p className="text-xs text-gray-400">{selected.displayName}</p>
                  <p className="text-xs mt-0.5" style={{ color: selected.color }}>
                    阶段 {getTreeStage(selected.totalMinutes / 60)} · {selected.type === 'checkin' ? '打卡型' : '计时型'}
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="bg-gray-50 rounded-2xl p-3">
                  <p className="text-xs text-gray-400 mb-1">累计时间</p>
                  <p className="text-xl font-bold" style={{ color: selected.color }}>
                    {(selected.totalMinutes / 60).toFixed(1)}
                    <span className="text-sm font-normal text-gray-400 ml-1">h</span>
                  </p>
                </div>
                <div className="bg-gray-50 rounded-2xl p-3">
                  <p className="text-xs text-gray-400 mb-1">成就数</p>
                  <p className="text-xl font-bold text-amber-500">
                    {selected.achievementCount}
                    <span className="text-sm font-normal text-gray-400 ml-1">个</span>
                  </p>
                </div>
              </div>

              {/* Next stage bar */}
              {(() => {
                const h = selected.totalMinutes / 60
                const stage = getTreeStage(h)
                const thresholds = [0, 2, 8, 25, 60, Infinity]
                const prev = thresholds[stage - 1]
                const next = thresholds[stage]
                if (next === Infinity) return (
                  <div className="text-center py-2">
                    <span className="text-sm text-amber-500 font-medium">🌳 已达到最高阶段！</span>
                  </div>
                )
                const pct = (h - prev) / (next - prev)
                return (
                  <div>
                    <div className="flex justify-between text-xs text-gray-500 mb-1.5">
                      <span>阶段 {stage} → {stage + 1}</span>
                      <span>还差 {(next - h).toFixed(1)}h</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{
                          width: `${Math.min(100, pct * 100)}%`,
                          background: `linear-gradient(90deg, ${selected.color}88, ${selected.color})`,
                        }}
                      />
                    </div>
                  </div>
                )
              })()}
            </div>
          </div>
        )}
      </div>
    </>
  )
}
