'use client'

import { useState } from 'react'
import { Plus, ChevronDown, ChevronRight, X } from 'lucide-react'
import type { BranchData, Achievement, DividendMeta, DepositMeta, StockMeta, AchievementTemplate, AchievementMeta } from './useTreeData'
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
  onArchive: (id: string) => Promise<void>
  onUnarchive: (id: string) => Promise<void>
}

const MAX_BAR_PX = 180

function formatMinutes(m: number): string {
  if (m < 60) return `${m}m`
  const h = Math.floor(m / 60)
  const min = m % 60
  return min === 0 ? `${h}h` : `${h}h${min}m`
}

// ── Child item (sub-achievement) ─────────────────────────────────────

function ChildItem({ child, unit, onDelete }: {
  child: Achievement
  unit: string
  onDelete: () => void
}) {
  const symbol = (child.metadata as DividendMeta | DepositMeta | StockMeta | null)?.currency === 'USD' ? '$' : '¥'

  const detail = () => {
    if (child.template === 'dividend') {
      const m = child.metadata as DividendMeta
      return `${m.shares}股 × ${symbol}${m.dividendPer10}/10股 = ${symbol}${child.target_value.toFixed(2)}/年`
    }
    if (child.template === 'deposit') {
      const m = child.metadata as DepositMeta
      return `本金${symbol}${m.principal.toLocaleString()} × ${m.rate}% = ${symbol}${child.target_value.toFixed(2)}/年`
    }
    if (child.template === 'stock_profit') {
      const m = child.metadata as StockMeta
      return m.costBasis ? `成本${symbol}${m.costBasis.toLocaleString()} · 目标${symbol}${child.target_value.toLocaleString()}` : `目标${symbol}${child.target_value.toLocaleString()}`
    }
    return `目标 ${child.target_value}${unit}`
  }

  return (
    <div className="flex items-center justify-between py-1.5 pl-4 border-l-2 border-red-100 ml-2">
      <div>
        <span className="text-xs font-medium text-gray-700">{child.name}</span>
        <p className="text-xs text-gray-400 mt-0.5">{detail()}</p>
      </div>
      <button onClick={onDelete} className="text-gray-200 hover:text-red-400 ml-3 shrink-0">
        <X size={12} />
      </button>
    </div>
  )
}

// ── Add child modal (投资子项) ────────────────────────────────────────

function AddChildModal({ parent, onSave, onClose }: {
  parent: Achievement
  onSave: (data: { name: string; unit: string; target_value: number; template: AchievementTemplate; metadata: AchievementMeta }) => Promise<void>
  onClose: () => void
}) {
  const [template, setTemplate] = useState<'dividend' | 'deposit' | 'stock_profit'>('dividend')
  const [name, setName] = useState('')
  const [currency, setCurrency] = useState<'CNY' | 'USD'>('CNY')
  const [shares, setShares] = useState('')
  const [dividendPer10, setDividendPer10] = useState('')
  const [principal, setPrincipal] = useState('')
  const [rate, setRate] = useState('')
  const [costBasis, setCostBasis] = useState('')
  const [targetProfit, setTargetProfit] = useState('')
  const [saving, setSaving] = useState(false)

  const symbol = currency === 'CNY' ? '¥' : '$'

  const estimated = () => {
    if (template === 'dividend' && shares && dividendPer10)
      return (parseFloat(shares) / 10 * parseFloat(dividendPer10)).toFixed(2)
    if (template === 'deposit' && principal && rate)
      return (parseFloat(principal) * parseFloat(rate) / 100).toFixed(2)
    return null
  }

  const canSave = name.trim() && (
    (template === 'dividend' && shares && dividendPer10) ||
    (template === 'deposit' && principal && rate) ||
    (template === 'stock_profit' && targetProfit)
  )

  async function handleSave() {
    if (!canSave) return
    setSaving(true)
    let target_value = 0
    let metadata: AchievementMeta = null
    if (template === 'dividend') {
      target_value = parseFloat(shares) / 10 * parseFloat(dividendPer10)
      metadata = { name: name.trim(), currency, shares: parseFloat(shares), dividendPer10: parseFloat(dividendPer10) }
    } else if (template === 'deposit') {
      target_value = parseFloat(principal) * parseFloat(rate) / 100
      metadata = { name: name.trim(), currency, principal: parseFloat(principal), rate: parseFloat(rate) }
    } else {
      target_value = parseFloat(targetProfit)
      metadata = { name: name.trim(), currency, costBasis: parseFloat(costBasis || '0') }
    }
    await onSave({ name: name.trim(), unit: symbol, target_value, template, metadata })
    setSaving(false)
    onClose()
  }

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center bg-black/40" onClick={onClose}>
      <div className="w-full max-w-lg bg-white rounded-t-3xl p-5 space-y-4 mb-16 max-h-[80vh] overflow-y-auto"
        onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-semibold text-gray-800">添加子项</h2>
            <p className="text-xs text-gray-400 mt-0.5">归入：{parent.name}</p>
          </div>
          <button onClick={onClose}><X size={18} className="text-gray-400" /></button>
        </div>

        {/* Template tabs */}
        <div className="flex gap-1 bg-gray-100 rounded-xl p-1">
          {[
            { key: 'dividend' as const, label: '股息' },
            { key: 'deposit' as const, label: '定存/债券' },
            { key: 'stock_profit' as const, label: '股票盈利' },
          ].map(t => (
            <button key={t.key} onClick={() => setTemplate(t.key)}
              className={`flex-1 py-1.5 rounded-lg text-xs font-medium transition-colors ${template === t.key ? 'bg-white text-gray-800 shadow-sm' : 'text-gray-500'}`}>
              {t.label}
            </button>
          ))}
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">名称</label>
          <input type="text" value={name} onChange={e => setName(e.target.value)} autoFocus
            placeholder={template === 'dividend' ? '如：中国广核' : template === 'deposit' ? '如：九江银行定存' : '如：腾讯控股'}
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400" />
        </div>

        <div>
          <label className="text-xs text-gray-500 mb-1 block">货币</label>
          <div className="flex rounded-xl border border-gray-200 overflow-hidden">
            {(['CNY', 'USD'] as const).map(c => (
              <button key={c} onClick={() => setCurrency(c)}
                className={`flex-1 py-2 text-sm font-medium transition-colors ${currency === c ? 'bg-blue-600 text-white' : 'text-gray-500'}`}>
                {c === 'CNY' ? '¥ CNY' : '$ USD'}
              </button>
            ))}
          </div>
        </div>

        {template === 'dividend' && (
          <>
            <div>
              <label className="text-xs text-gray-500 mb-1 block">持股数（股）</label>
              <input type="number" value={shares} onChange={e => setShares(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400" />
            </div>
            <div>
              <label className="text-xs text-gray-500 mb-1 block">每10股年分红（{symbol}）</label>
              <input type="number" value={dividendPer10} onChange={e => setDividendPer10(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400" />
            </div>
          </>
        )}

        {template === 'deposit' && (
          <>
            <div>
              <label className="text-xs text-gray-500 mb-1 block">本金（{symbol}）</label>
              <input type="number" value={principal} onChange={e => setPrincipal(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400" />
            </div>
            <div>
              <label className="text-xs text-gray-500 mb-1 block">年化利率（%）</label>
              <input type="number" value={rate} onChange={e => setRate(e.target.value)} step="0.01"
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400" />
            </div>
          </>
        )}

        {template === 'stock_profit' && (
          <>
            <div>
              <label className="text-xs text-gray-500 mb-1 block">持有成本（{symbol}，可选）</label>
              <input type="number" value={costBasis} onChange={e => setCostBasis(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400" />
            </div>
            <div>
              <label className="text-xs text-gray-500 mb-1 block">目标盈利（{symbol}）</label>
              <input type="number" value={targetProfit} onChange={e => setTargetProfit(e.target.value)}
                className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-red-400" />
            </div>
          </>
        )}

        {estimated() && (
          <div className="bg-green-50 rounded-xl px-4 py-3">
            <p className="text-xs text-green-600">预估年收入</p>
            <p className="text-lg font-bold text-green-600">{symbol}{estimated()}</p>
          </div>
        )}

        <button onClick={handleSave} disabled={saving || !canSave}
          className="w-full py-3 bg-red-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
          {saving ? '保存中...' : '添加'}
        </button>
      </div>
    </div>
  )
}

// ── Red leaf with children ───────────────────────────────────────────

function RedLeafWithChildren({ achievement, maxMinutes, isInvestment, onOpenDetail, onAddChild, onDeleteChild }: {
  achievement: Achievement
  maxMinutes: number
  isInvestment: boolean
  onOpenDetail: () => void
  onAddChild: () => void
  onDeleteChild: (id: string) => void
}) {
  const [expanded, setExpanded] = useState(false)
  const isComplete = achievement.progress >= 1
  const barColor = isComplete ? '#F59E0B' : '#EF4444'
  const hasChildren = achievement.children.length > 0
  const filledWidth = Math.max(4, Math.round(achievement.progress * MAX_BAR_PX))

  return (
    <div>
      <div className="flex items-center gap-2 py-0.5">
        <span className="text-xs text-gray-500 w-16 text-right shrink-0 truncate">{achievement.name}</span>
        {/* Track (gray background = total target) */}
        <button
          className="relative h-5 rounded-r-full text-left shrink-0"
          style={{ width: `${MAX_BAR_PX}px`, backgroundColor: '#E5E7EB', borderLeft: `3px solid ${barColor}` }}
          onClick={onOpenDetail}
        >
          {/* Filled portion */}
          <div
            className="absolute inset-y-0 left-0 rounded-r-full flex items-center px-2 transition-all"
            style={{ width: `${filledWidth}px`, backgroundColor: barColor + '33' }}
          />
          {/* Label */}
          <span className="relative text-xs font-medium px-2" style={{ color: barColor }}>
            {achievement.current_value.toFixed(achievement.current_value % 1 === 0 ? 0 : 1)}{achievement.unit}
            {isComplete && ' 🏅'}
          </span>
        </button>
        <span className="text-xs text-gray-400 w-8 shrink-0">{Math.round(achievement.progress * 100)}%</span>
        {isInvestment && (
          <button
            onClick={() => setExpanded(e => !e)}
            className="text-gray-300 hover:text-red-400 transition-colors"
          >
            {expanded ? <ChevronDown size={13} /> : <ChevronRight size={13} />}
          </button>
        )}
      </div>

      {expanded && (
        <div className="mt-1 mb-1 space-y-0.5">
          {hasChildren
            ? achievement.children.map(child => (
                <ChildItem key={child.id} child={child} unit={achievement.unit} onDelete={() => onDeleteChild(child.id)} />
              ))
            : <p className="text-xs text-gray-300 pl-6 py-1">还没有子项</p>
          }
          <button
            onClick={onAddChild}
            className="flex items-center gap-1 text-xs text-gray-300 hover:text-red-400 pl-4 mt-1 transition-colors"
          >
            <Plus size={11} /> 添加子项
          </button>
        </div>
      )}
    </div>
  )
}

// ── Branch ───────────────────────────────────────────────────────────

function Branch({ branch, onAddAchievement, onAddRecord, onDeleteRecord, onDeleteAchievement, onUpdateTarget, onArchive, onUnarchive }: {
  branch: BranchData
  onAddAchievement: Props['onAddAchievement']
  onAddRecord: Props['onAddRecord']
  onDeleteRecord: Props['onDeleteRecord']
  onDeleteAchievement: Props['onDeleteAchievement']
  onUpdateTarget: Props['onUpdateTarget']
  onArchive: Props['onArchive']
  onUnarchive: Props['onUnarchive']
}) {
  const [collapsed, setCollapsed] = useState(false)
  const [archivedExpanded, setArchivedExpanded] = useState(false)
  const [showAddAchievement, setShowAddAchievement] = useState(false)
  const [selectedAchievement, setSelectedAchievement] = useState<Achievement | null>(null)
  const [addingChildTo, setAddingChildTo] = useState<Achievement | null>(null)

  const isInvestment = isInvestmentCategory(branch.displayName)
  const totalMinutes = branch.hobbies.reduce((s, h) => s + h.totalMinutes, 0)
  const activeAchievements = branch.achievements.filter(a => !a.archived_at)
  const archivedAchievements = branch.achievements.filter(a => a.archived_at)

  return (
    <div className="border border-gray-100 rounded-2xl bg-white shadow-sm overflow-hidden">
      <button className="w-full flex items-center justify-between px-4 py-3" onClick={() => setCollapsed(c => !c)}>
        <div className="flex items-center gap-2">
          {collapsed ? <ChevronRight size={14} className="text-gray-400" /> : <ChevronDown size={14} className="text-gray-400" />}
          <span className="text-sm font-semibold text-gray-700">{branch.displayName}</span>
          <span className="text-xs text-gray-300">{branch.hobbies.length}绿 · {branch.achievements.length}红</span>
        </div>
        <span className="text-xs text-gray-400">{formatMinutes(totalMinutes)}</span>
      </button>

      {!collapsed && (
        <div className="px-4 pb-4 space-y-1">
          {branch.hobbies.length > 0 && (
            <>
              <p className="text-xs text-gray-300 pt-1 pb-0.5">投入</p>
              {branch.hobbies.sort((a, b) => b.totalMinutes - a.totalMinutes).map(h => (
                <div key={h.label} className="flex items-center gap-2 py-0.5">
                  <span className="text-xs text-gray-500 w-16 text-right shrink-0 truncate">{h.label}</span>
                  <div className="h-5 rounded-r-full flex items-center px-2"
                    style={{ width: `${branch.maxMinutes > 0 ? Math.max(32, Math.round(h.totalMinutes / branch.maxMinutes * MAX_BAR_PX)) : 32}px`, backgroundColor: h.color + '33', borderLeft: `3px solid ${h.color}` }}>
                    <span className="text-xs font-medium truncate" style={{ color: h.color }}>{formatMinutes(h.totalMinutes)}</span>
                  </div>
                </div>
              ))}
            </>
          )}

          {activeAchievements.length > 0 && (
            <>
              <p className="text-xs text-gray-300 pt-2 pb-0.5">成就</p>
              {activeAchievements.map(a => (
                <RedLeafWithChildren
                  key={a.id}
                  achievement={a}
                  maxMinutes={branch.maxMinutes}
                  isInvestment={isInvestment}
                  onOpenDetail={() => setSelectedAchievement(a)}
                  onAddChild={() => setAddingChildTo(a)}
                  onDeleteChild={onDeleteAchievement}
                />
              ))}
            </>
          )}

          {/* 里程碑（归档成就） */}
          {archivedAchievements.length > 0 && (
            <div className="mt-1">
              <button
                onClick={() => setArchivedExpanded(e => !e)}
                className="flex items-center gap-1.5 text-xs text-amber-500 hover:text-amber-600 transition-colors mt-1"
              >
                <span>🏅</span>
                <span>里程碑 {archivedAchievements.length}</span>
                <span className="text-amber-300">{archivedExpanded ? '▲' : '▼'}</span>
              </button>
              {archivedExpanded && (
                <div className="mt-1.5 space-y-1">
                  {archivedAchievements.map(a => (
                    <div key={a.id} className="flex items-center gap-2 py-0.5 opacity-70">
                      <span className="text-xs text-gray-400 w-16 text-right shrink-0 truncate">{a.name}</span>
                      <div className="flex-1 h-1.5 bg-amber-100 rounded-full overflow-hidden">
                        <div className="h-full bg-amber-400 rounded-full w-full" />
                      </div>
                      <span className="text-xs text-amber-500">🏅</span>
                      <button
                        onClick={() => onUnarchive(a.id)}
                        className="text-xs text-gray-300 hover:text-gray-500 transition-colors"
                        title="取消归档"
                      >↩</button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          <button onClick={() => setShowAddAchievement(true)}
            className="flex items-center gap-1 text-xs text-gray-300 hover:text-red-400 mt-2 transition-colors">
            <Plus size={13} /> 添加成就
          </button>
        </div>
      )}

      {showAddAchievement && (
        <AchievementModal
          category={branch.category}
          isInvestment={isInvestment}
          onSave={onAddAchievement}
          onClose={() => setShowAddAchievement(false)}
        />
      )}
      {selectedAchievement && (
        <RecordModal
          achievement={selectedAchievement}
          maxMinutes={branch.maxMinutes}
          onAddRecord={data => onAddRecord(selectedAchievement.id, data)}
          onDeleteRecord={onDeleteRecord}
          onDeleteAchievement={() => onDeleteAchievement(selectedAchievement.id)}
          onUpdateTarget={target_value => onUpdateTarget(selectedAchievement.id, target_value)}
          onArchive={async () => { await onArchive(selectedAchievement.id); setSelectedAchievement(null) }}
          onClose={() => setSelectedAchievement(null)}
        />
      )}
      {addingChildTo && (
        <AddChildModal
          parent={addingChildTo}
          onSave={data => onAddAchievement({
            category: branch.category,
            parent_id: addingChildTo.id,
            ...data,
          })}
          onClose={() => setAddingChildTo(null)}
        />
      )}
    </div>
  )
}

// ── Root ─────────────────────────────────────────────────────────────

export default function TreeView({ branches, onAddAchievement, onAddRecord, onDeleteRecord, onDeleteAchievement, onUpdateTarget, onArchive, onUnarchive }: Props) {
  if (branches.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center flex-1 text-gray-300 gap-3 py-20">
        <span className="text-5xl">🌱</span>
        <p className="text-sm">先在日历中记录时间，树枝就会生长</p>
      </div>
    )
  }

  return (
    <div className="space-y-3">
      {branches
        .sort((a, b) => b.hobbies.reduce((s, h) => s + h.totalMinutes, 0) - a.hobbies.reduce((s, h) => s + h.totalMinutes, 0))
        .map(branch => (
          <Branch
            key={branch.category}
            branch={branch}
            onAddAchievement={onAddAchievement}
            onAddRecord={onAddRecord}
            onDeleteRecord={onDeleteRecord}
            onDeleteAchievement={onDeleteAchievement}
            onUpdateTarget={onUpdateTarget}
            onArchive={onArchive}
            onUnarchive={onUnarchive}
          />
        ))}
    </div>
  )
}
