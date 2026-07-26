'use client'

import { useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useTreeData } from '@/components/tree/useTreeData'
import TreeView from '@/components/tree/TreeView'

export default function TreePage() {
  const currentYear = new Date().getFullYear()
  const [year, setYear] = useState(currentYear)
  const { branches, loading, addAchievement, updateAchievementTarget, deleteAchievement, archiveAchievement, unarchiveAchievement, addRecord, deleteRecord } = useTreeData(year)

  return (
    <div className="flex flex-col h-full">
      <div className="flex items-center justify-center gap-4 px-4 py-3 border-b border-gray-100 bg-white shrink-0">
        <button onClick={() => setYear(y => y - 1)} className="p-1.5 rounded-full hover:bg-gray-100 text-gray-400 transition-colors">
          <ChevronLeft size={18} />
        </button>
        <span className="text-base font-semibold text-gray-700 w-16 text-center">{year}</span>
        <button onClick={() => setYear(y => y + 1)} disabled={year >= currentYear}
          className="p-1.5 rounded-full hover:bg-gray-100 text-gray-400 transition-colors disabled:opacity-30">
          <ChevronRight size={18} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-3 pb-24">
        {loading
          ? <div className="flex items-center justify-center py-20 text-gray-300 text-sm">加载中...</div>
          : <TreeView
              branches={branches}
              onAddAchievement={addAchievement}
              onAddRecord={addRecord}
              onDeleteRecord={deleteRecord}
              onDeleteAchievement={deleteAchievement}
              onUpdateTarget={updateAchievementTarget}
              onArchive={archiveAchievement}
              onUnarchive={unarchiveAchievement}
            />
        }
      </div>
    </div>
  )
}
