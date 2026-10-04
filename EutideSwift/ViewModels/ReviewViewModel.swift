import SwiftUI
import Combine

/// 复盘情绪维度：每类效率的时长 + 情绪分布。
struct EffStat {
    var minutes: Int = 0
    var byMood: [Mood: Int] = [:]
    var noMood: Int = 0        // 有记录但没标情绪
}

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var weekOffset = 0
    @Published var currentWeek: WeekStats?
    @Published var averageWeek: WeekStats?
    @Published var effStats: [Efficiency: EffStat] = [:]
    @Published var isLoading = false

    func load(prefs: PrefsViewModel) async {
        isLoading = true
        let today = Date()
        let anchor = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: today) ?? today
        let weekDates = WeekCalculator.weekDates(containing: anchor)
        let weekStrings = weekDates.map { $0.localDateString() }

        // Fetch 5 weeks: current + 4 prior
        var allDateStrings: [String] = weekStrings
        for w in 1...4 {
            let pastAnchor = Calendar.current.date(byAdding: .weekOfYear, value: -w, to: anchor)!
            allDateStrings += WeekCalculator.weekDateStrings(containing: pastAnchor)
        }

        do {
            let entries = try await TimeEntryService.fetch(dates: allDateStrings)
            let timeCatMap = prefs.timeCategoryMap
            let labelRenames = prefs.labelRenames

            let weekEntries = entries.filter { weekStrings.contains($0.date) }
            currentWeek = buildWeekStats(
                dates: weekDates,
                entries: weekEntries,
                timeCatMap: timeCatMap,
                labelRenames: labelRenames
            )
            effStats = buildEffStats(entries: weekEntries, effMap: prefs.hobbyEfficiencyMap)

            // 4-week average
            var priorStats: [WeekStats] = []
            for w in 1...4 {
                let pastAnchor = Calendar.current.date(byAdding: .weekOfYear, value: -w, to: anchor)!
                let pastDates = WeekCalculator.weekDates(containing: pastAnchor)
                let pastStrings = pastDates.map { $0.localDateString() }
                let pastEntries = entries.filter { pastStrings.contains($0.date) }
                priorStats.append(buildWeekStats(dates: pastDates, entries: pastEntries,
                                                  timeCatMap: timeCatMap, labelRenames: labelRenames))
            }
            averageWeek = averageOf(priorStats)
        } catch {}
        isLoading = false
    }

    func goBack() async { weekOffset -= 1 }
    func goForward() async { guard weekOffset < 0 else { return }; weekOffset += 1 }

    // MARK: - Private

    private func buildWeekStats(dates: [Date], entries: [TimeEntry],
                                  timeCatMap: [String: String], labelRenames: [String: String]) -> WeekStats {
        var byCategory: [TimeCategory: Int] = [:]
        var byDay: [DayStats] = []

        for date in dates {
            let dateStr = date.localDateString()
            let dayEntries = entries.filter { $0.date == dateStr }
            var dayCat: [TimeCategory: Int] = [:]
            var recordedMins = 0
            for e in dayEntries {
                let dur = e.durationMinutes
                recordedMins += dur
                if let catStr = timeCatMap[e.hobby], let cat = TimeCategory(rawValue: catStr) {
                    dayCat[cat, default: 0] += dur
                    byCategory[cat, default: 0] += dur
                }
            }
            let untracked = WeekCalculator.untrackedMinutes(dateStr: dateStr, recordedMinutes: recordedMins)
            byDay.append(DayStats(date: date, byCategory: dayCat, untracked: untracked))
        }

        let totalTracked = byCategory.values.reduce(0, +)
        let weekUntracked = byDay.reduce(0) { $0 + $1.untracked }
        let weekLabel = WeekCalculator.weekLabel(dates: dates)
        return WeekStats(weekLabel: weekLabel, weekStart: dates.first ?? Date(),
                          totalMinutes: totalTracked, byCategory: byCategory,
                          untracked: weekUntracked, byDay: byDay)
    }

    private func buildEffStats(entries: [TimeEntry], effMap: [String: [String]]) -> [Efficiency: EffStat] {
        var result: [Efficiency: EffStat] = [:]
        for e in entries {
            let effs = (effMap[e.hobby] ?? []).compactMap { Efficiency(rawValue: $0) }
            let dur = e.durationMinutes
            for eff in effs {   // 最多 2 个，各算 100%
                var stat = result[eff] ?? EffStat()
                stat.minutes += dur
                if let m = e.moodLabel { stat.byMood[m, default: 0] += dur }
                else { stat.noMood += dur }
                result[eff] = stat
            }
        }
        return result
    }

    private func averageOf(_ weeks: [WeekStats]) -> WeekStats {        guard !weeks.isEmpty else {
            return WeekStats(weekLabel: "4周均值", weekStart: Date(), totalMinutes: 0,
                             byCategory: [:], untracked: 0, byDay: [])
        }
        var avgCat: [TimeCategory: Int] = [:]
        for cat in TimeCategory.allCases {
            let total = weeks.reduce(0) { $0 + ($1.byCategory[cat] ?? 0) }
            avgCat[cat] = total / weeks.count
        }
        let avgTotal = avgCat.values.reduce(0, +)
        return WeekStats(weekLabel: "4周均值", weekStart: weeks[0].weekStart,
                          totalMinutes: avgTotal, byCategory: avgCat,
                          untracked: weeks.reduce(0) { $0 + $1.untracked } / weeks.count,
                          byDay: [])
    }
}
