'use client'

import { useState } from 'react'
import { X, ChevronRight } from 'lucide-react'
import type { AchievementTemplate, DividendMeta, DepositMeta, StockMeta, HabitMeta } from './useTreeData'

type SaveData = {
  category: string; name: string; unit: string; target_value: number
  template: AchievementTemplate; metadata: DividendMeta | DepositMeta | StockMeta | HabitMeta | null
}

type Props = {
  category: string
  isInvestment: boolean
  onSave: (data: SaveData) => Promise<void>
  onClose: () => void
}

const UNIT_PRESETS = ['¥', 'kg', '次', '篇', '本', 'km', '%', '小时']

// ── Investment template forms ────────────────────────────────────────

function DividendForm({ category, onSave, onBack }: {
  category: string
  onSave: Props['onSave']
  onBack: () => void
}) {
  const [name, setName] = useState('')
  const [currency, setCurrency] = useState<'CNY' | 'USD'>('CNY')
  const [shares, setShares] = useState('')
  const [dividendPer10, setDividendPer10] = useState('')
  const [saving, setSaving] = useState(false)

  const symbol = currency === 'CNY' ? '¥' : '$'
  const estimated = shares && dividendPer10
    ? (parseFloat(shares) / 10 * parseFloat(dividendPer10)).toFixed(2)
    : null

  async function handleSave() {
    if (!name.trim() || !shares || !dividendPer10) return
    setSaving(true)
    const target_value = parseFloat(shares) / 10 * parseFloat(dividendPer10)
    await onSave({
      category, name: name.trim(), unit: symbol, target_value,
      template: 'dividend',
      metadata: { name: name.trim(), currency, shares: parseFloat(shares), dividendPer10: parseFloat(dividendPer10) },
    })
    setSaving(false)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <button onClick={onBack} className="text-gray-400 hover:text-gray-600"><ChevronRight size={16} className="rotate-180" /></button>
        <h3 className="text-sm font-semibold text-gray-700">股息收入</h3>
      </div>
      <div>
        <label className="text-xs text-gray-500 mb-1 block">名称（如：中国广核）</label>
        <input type="text" value={name} onChange={e => setName(e.target.value)} autoFocus
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
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
      <div>
        <label className="text-xs text-gray-500 mb-1 block">持股数（股）</label>
        <input type="number" value={shares} onChange={e => setShares(e.target.value)}
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
      </div>
      <div>
        <label className="text-xs text-gray-500 mb-1 block">每10股年分红（{symbol}）</label>
        <input type="number" value={dividendPer10} onChange={e => setDividendPer10(e.target.value)}
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
      </div>
      {estimated && (
        <div className="bg-green-50 rounded-xl px-4 py-3">
          <p className="text-xs text-green-600">预估年税前收入</p>
          <p className="text-lg font-bold text-green-600">{symbol}{estimated}</p>
        </div>
      )}
      <button onClick={handleSave} disabled={saving || !name.trim() || !shares || !dividendPer10}
        className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
        {saving ? '保存中...' : '添加成就'}
      </button>
    </div>
  )
}

function DepositForm({ category, onSave, onBack }: {
  category: string
  onSave: Props['onSave']
  onBack: () => void
}) {
  const [name, setName] = useState('')
  const [currency, setCurrency] = useState<'CNY' | 'USD'>('CNY')
  const [principal, setPrincipal] = useState('')
  const [rate, setRate] = useState('')
  const [saving, setSaving] = useState(false)

  const symbol = currency === 'CNY' ? '¥' : '$'
  const estimated = principal && rate
    ? (parseFloat(principal) * parseFloat(rate) / 100).toFixed(2)
    : null

  async function handleSave() {
    if (!name.trim() || !principal || !rate) return
    setSaving(true)
    const target_value = parseFloat(principal) * parseFloat(rate) / 100
    await onSave({
      category, name: name.trim(), unit: symbol, target_value,
      template: 'deposit',
      metadata: { name: name.trim(), currency, principal: parseFloat(principal), rate: parseFloat(rate) },
    })
    setSaving(false)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <button onClick={onBack} className="text-gray-400 hover:text-gray-600"><ChevronRight size={16} className="rotate-180" /></button>
        <h3 className="text-sm font-semibold text-gray-700">定存 / 债券利息</h3>
      </div>
      <div>
        <label className="text-xs text-gray-500 mb-1 block">名称（如：九江银行定存）</label>
        <input type="text" value={name} onChange={e => setName(e.target.value)} autoFocus
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
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
      <div>
        <label className="text-xs text-gray-500 mb-1 block">本金（{symbol}）</label>
        <input type="number" value={principal} onChange={e => setPrincipal(e.target.value)}
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
      </div>
      <div>
        <label className="text-xs text-gray-500 mb-1 block">年化利率（% / 年）</label>
        <input type="number" value={rate} onChange={e => setRate(e.target.value)} step="0.01"
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
      </div>
      {estimated && (
        <div className="bg-green-50 rounded-xl px-4 py-3">
          <p className="text-xs text-green-600">预估年税前收入</p>
          <p className="text-lg font-bold text-green-600">{symbol}{estimated}</p>
        </div>
      )}
      <button onClick={handleSave} disabled={saving || !name.trim() || !principal || !rate}
        className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
        {saving ? '保存中...' : '添加成就'}
      </button>
    </div>
  )
}

function StockProfitForm({ category, onSave, onBack }: {
  category: string
  onSave: Props['onSave']
  onBack: () => void
}) {
  const [name, setName] = useState('')
  const [currency, setCurrency] = useState<'CNY' | 'USD'>('CNY')
  const [costBasis, setCostBasis] = useState('')
  const [targetProfit, setTargetProfit] = useState('')
  const [saving, setSaving] = useState(false)

  const symbol = currency === 'CNY' ? '¥' : '$'

  async function handleSave() {
    if (!name.trim() || !targetProfit) return
    setSaving(true)
    await onSave({
      category, name: name.trim(), unit: symbol, target_value: parseFloat(targetProfit),
      template: 'stock_profit',
      metadata: { name: name.trim(), currency, costBasis: parseFloat(costBasis || '0') },
    })
    setSaving(false)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-2">
        <button onClick={onBack} className="text-gray-400 hover:text-gray-600"><ChevronRight size={16} className="rotate-180" /></button>
        <h3 className="text-sm font-semibold text-gray-700">股票盈利</h3>
      </div>
      <div>
        <label className="text-xs text-gray-500 mb-1 block">名称（如：腾讯控股）</label>
        <input type="text" value={name} onChange={e => setName(e.target.value)} autoFocus
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
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
      <div>
        <label className="text-xs text-gray-500 mb-1 block">持有成本（{symbol}，可选）</label>
        <input type="number" value={costBasis} onChange={e => setCostBasis(e.target.value)}
          placeholder="如：50000"
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
      </div>
      <div>
        <label className="text-xs text-gray-500 mb-1 block">目标盈利（{symbol}）</label>
        <input type="number" value={targetProfit} onChange={e => setTargetProfit(e.target.value)}
          placeholder="如：10000"
          className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
      </div>
      <button onClick={handleSave} disabled={saving || !name.trim() || !targetProfit}
        className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
        {saving ? '保存中...' : '添加成就'}
      </button>
    </div>
  )
}

// ── Main modal ───────────────────────────────────────────────────────

type ModalMode = 'pick' | 'habit' | 'general'

export default function AchievementModal({ category, isInvestment, onSave, onClose }: Props) {
  const [mode, setMode] = useState<ModalMode>(isInvestment ? 'pick' : 'general')

  // Investment parent form
  const [invName, setInvName] = useState('')
  const [invCurrency, setInvCurrency] = useState<'CNY' | 'USD'>('CNY')
  const [invTarget, setInvTarget] = useState('')
  const [invSaving, setInvSaving] = useState(false)

  // Habit form
  const [habitName, setHabitName] = useState('')
  const [habitPeriodUnit, setHabitPeriodUnit] = useState<'天' | '周' | '年'>('天')
  const [habitPeriod, setHabitPeriod] = useState('330')
  const [habitSaving, setHabitSaving] = useState(false)

  // General form
  const [name, setName] = useState('')
  const [unit, setUnit] = useState('¥')
  const [customUnit, setCustomUnit] = useState('')
  const [targetValue, setTargetValue] = useState('')
  const [saving, setSaving] = useState(false)

  const finalUnit = unit === '__custom__' ? customUnit : unit

  // Suggested targets by unit
  const habitSuggestions: Record<string, number[]> = {
    '天': [30, 90, 180, 330, 365],
    '周': [12, 26, 48, 52],
    '年': [1, 2, 3, 5],
  }

  async function handleInvestmentSave() {
    if (!invName.trim()) return
    setInvSaving(true)
    const symbol = invCurrency === 'CNY' ? '¥' : '$'
    await onSave({ category, name: invName.trim(), unit: symbol, target_value: invTarget ? parseFloat(invTarget) : 0, template: 'general', metadata: null })
    setInvSaving(false)
    onClose()
  }

  async function handleHabitSave() {
    if (!habitName.trim() || !habitPeriod) return
    setHabitSaving(true)
    const target = parseInt(habitPeriod)
    await onSave({
      category,
      name: habitName.trim(),
      unit: habitPeriodUnit,
      target_value: target,
      template: 'habit',
      metadata: { unit: habitPeriodUnit, period: target } as HabitMeta,
    })
    setHabitSaving(false)
    onClose()
  }

  async function handleGeneralSave() {
    if (!name.trim() || !finalUnit.trim() || !targetValue) return
    setSaving(true)
    await onSave({ category, name: name.trim(), unit: finalUnit.trim(), target_value: parseFloat(targetValue), template: 'general', metadata: null })
    setSaving(false)
    onClose()
  }

  const renderBody = () => {
    // Investment: skip mode picker, go straight to investment form
    if (isInvestment) {
      return (
        <div className="space-y-4">
          <div className="text-xs text-gray-400">树枝：{category}</div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">成就名称</label>
            <input type="text" value={invName} onChange={e => setInvName(e.target.value)} autoFocus
              placeholder="如：A股股息、定存利息"
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">货币</label>
            <div className="flex rounded-xl border border-gray-200 overflow-hidden">
              {(['CNY', 'USD'] as const).map(c => (
                <button key={c} onClick={() => setInvCurrency(c)}
                  className={`flex-1 py-2 text-sm font-medium transition-colors ${invCurrency === c ? 'bg-blue-600 text-white' : 'text-gray-500'}`}>
                  {c === 'CNY' ? '¥ CNY' : '$ USD'}
                </button>
              ))}
            </div>
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">年目标金额（可选）</label>
            <input type="number" value={invTarget} onChange={e => setInvTarget(e.target.value)}
              placeholder="如：120000，留空则通过子项自动汇总"
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
          </div>
          <button onClick={handleInvestmentSave} disabled={invSaving || !invName.trim()}
            className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
            {invSaving ? '保存中...' : '添加成就'}
          </button>
        </div>
      )
    }

    // Habit form
    if (mode === 'habit') {
      return (
        <div className="space-y-4">
          <button onClick={() => setMode('pick')} className="text-xs text-gray-400 hover:text-gray-600">← 返回</button>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">习惯名称</label>
            <input type="text" value={habitName} onChange={e => setHabitName(e.target.value)} autoFocus
              placeholder="如：早睡、健康饮食、冥想"
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">计量单位</label>
            <div className="flex gap-2">
              {(['天', '周', '年'] as const).map(u => (
                <button key={u} onClick={() => { setHabitPeriodUnit(u); setHabitPeriod(String(habitSuggestions[u][3] ?? habitSuggestions[u][0])) }}
                  className={`flex-1 py-2 rounded-xl text-sm font-medium border transition-colors ${habitPeriodUnit === u ? 'bg-green-500 text-white border-green-500' : 'border-gray-200 text-gray-600'}`}>
                  {u}
                </button>
              ))}
            </div>
          </div>
          <div>
            <label className="text-xs text-gray-500 mb-1 block">目标次数（{habitPeriodUnit}）</label>
            <div className="flex flex-wrap gap-2 mb-2">
              {habitSuggestions[habitPeriodUnit].map(v => (
                <button key={v} onClick={() => setHabitPeriod(String(v))}
                  className={`px-3 py-1 rounded-full text-sm border transition-colors ${habitPeriod === String(v) ? 'bg-green-500 text-white border-green-500' : 'border-gray-200 text-gray-600'}`}>
                  {v}{habitPeriodUnit}
                </button>
              ))}
            </div>
            <input type="number" value={habitPeriod} onChange={e => setHabitPeriod(e.target.value)}
              placeholder="或自定义数字"
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
          </div>
          {habitName && habitPeriod && (
            <div className="bg-green-50 rounded-xl px-4 py-3 text-sm text-green-700">
              目标：{habitName} 坚持 <strong>{habitPeriod}{habitPeriodUnit}</strong>，每次完成点 +1
            </div>
          )}
          <button onClick={handleHabitSave} disabled={habitSaving || !habitName.trim() || !habitPeriod}
            className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
            {habitSaving ? '保存中...' : '添加习惯'}
          </button>
        </div>
      )
    }

    // General form
    return (
      <div className="space-y-4">
        <div>
          <label className="text-xs text-gray-500 mb-1 block">成就名称</label>
          <input type="text" value={name} onChange={e => setName(e.target.value)} autoFocus
            placeholder="如：减重目标、完成课程"
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
        </div>
        <div>
          <label className="text-xs text-gray-500 mb-1 block">单位</label>
          <div className="flex flex-wrap gap-2 mb-2">
            {UNIT_PRESETS.map(u => (
              <button key={u} onClick={() => setUnit(u)}
                className={`px-3 py-1 rounded-full text-sm border transition-colors ${unit === u ? 'bg-green-500 text-white border-green-500' : 'border-gray-200 text-gray-600'}`}>
                {u}
              </button>
            ))}
            <button onClick={() => setUnit('__custom__')}
              className={`px-3 py-1 rounded-full text-sm border transition-colors ${unit === '__custom__' ? 'bg-green-500 text-white border-green-500' : 'border-gray-200 text-gray-600'}`}>
              自定义
            </button>
          </div>
          {unit === '__custom__' && (
            <input type="text" value={customUnit} onChange={e => setCustomUnit(e.target.value)} placeholder="输入单位"
              className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
          )}
        </div>
        <div>
          <label className="text-xs text-gray-500 mb-1 block">目标值（{finalUnit || '单位'}）</label>
          <input type="number" value={targetValue} onChange={e => setTargetValue(e.target.value)} placeholder="如：1000"
            className="w-full px-3 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-green-400" />
        </div>
        <button onClick={handleGeneralSave} disabled={saving || !name.trim() || !finalUnit.trim() || !targetValue}
          className="w-full py-3 bg-green-500 text-white rounded-2xl text-sm font-medium disabled:opacity-40">
          {saving ? '保存中...' : '添加成就'}
        </button>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 z-[200] flex items-end justify-center bg-black/40" onClick={onClose}>
      <div className="w-full max-w-lg bg-white rounded-t-3xl p-5 space-y-4 mb-16 max-h-[80vh] overflow-y-auto"
        onClick={e => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <h2 className="text-base font-semibold text-gray-800">新增成就</h2>
          <button onClick={onClose}><X size={18} className="text-gray-400" /></button>
        </div>
        {renderBody()}
      </div>
    </div>
  )
}
