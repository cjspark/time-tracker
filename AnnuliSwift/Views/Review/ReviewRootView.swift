import SwiftUI
import Charts

struct ReviewRootView: View {
    @StateObject private var vm = ReviewViewModel()
    @EnvironmentObject private var prefs: PrefsViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                if let week = vm.currentWeek {
                    VStack(spacing: 20) {
                        weekNavigation
                            .padding(.horizontal)

                        TimeCategoryDonutView(stats: week)
                            .padding(.horizontal)

                        DailyBarChartView(stats: week)
                            .padding(.horizontal)

                        if let avg = vm.averageWeek {
                            CategoryComparisonView(current: week, average: avg)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                } else {
                    ProgressView("加载中…")
                        .padding(.top, 60)
                }
            }
            .navigationTitle("复盘")
        }
        .task { await vm.load(prefs: prefs) }
        .onChange(of: vm.weekOffset) { _ in Task { await vm.load(prefs: prefs) } }
    }

    private var weekNavigation: some View {
        HStack {
            Button {
                Task { await vm.goBack(); await vm.load(prefs: prefs) }
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            if let week = vm.currentWeek {
                Text(week.weekLabel).font(.system(size: 15, weight: .medium))
            }
            Spacer()
            Button {
                Task { await vm.goForward(); await vm.load(prefs: prefs) }
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundColor(vm.weekOffset == 0 ? .secondary : .primary)
            }
            .disabled(vm.weekOffset == 0)
        }
    }
}

// MARK: - Donut chart

struct TimeCategoryDonutView: View {
    let stats: WeekStats

    private struct ChartItem: Identifiable {
        let id = UUID()
        let name: String
        let minutes: Int
        let colorHex: String
    }

    private var trackedItems: [ChartItem] {
        TimeCategory.allCases.compactMap { cat in
            let m = stats.byCategory[cat] ?? 0
            guard m > 0 else { return nil }
            return ChartItem(name: cat.displayName, minutes: m, colorHex: cat.hex)
        }
    }

    private var allItems: [ChartItem] {
        var result = trackedItems
        if stats.untracked > 0 {
            result.append(ChartItem(name: "未追踪", minutes: stats.untracked, colorHex: "#9CA3AF"))
        }
        return result
    }

    private var trackedTotal: Int { trackedItems.reduce(0) { $0 + $1.minutes } }
    private var allTotal: Int { allItems.reduce(0) { $0 + $1.minutes } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间分布").font(.headline)

            if allItems.isEmpty {
                Text("本周暂无记录").foregroundColor(.secondary).font(.system(size: 13))
                    .padding(.vertical, 4)
            } else if #available(iOS 17, *) {
                ZStack {
                    Chart(allItems) { item in
                        SectorMark(
                            angle: .value("时间", item.minutes),
                            innerRadius: .ratio(0.55)
                        )
                        .foregroundStyle(Color(hex: item.colorHex))
                    }
                    .frame(height: 200)

                    VStack(spacing: 2) {
                        Text("已记录").font(.system(size: 11)).foregroundColor(.secondary)
                        Text(minuteLabel(trackedTotal)).font(.system(size: 15, weight: .semibold))
                    }
                }
            } else {
                // iOS 16 fallback: horizontal stacked bar
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(allItems) { item in
                            let w = allTotal > 0 ? geo.size.width * CGFloat(item.minutes) / CGFloat(allTotal) : 0
                            Rectangle()
                                .fill(Color(hex: item.colorHex))
                                .frame(width: max(w, 0))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(height: 24)

                HStack {
                    Text("已记录 \(minuteLabel(trackedTotal))").font(.system(size: 12)).foregroundColor(.secondary)
                    Spacer()
                    Text("共 \(minuteLabel(allTotal))").font(.system(size: 12)).foregroundColor(.secondary)
                }
            }

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(allItems) { item in
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: item.colorHex)).frame(width: 10, height: 10)
                        Text(item.name).font(.system(size: 12)).foregroundColor(.secondary)
                        Spacer()
                        Text(minuteLabel(item.minutes)).font(.system(size: 12, weight: .medium))
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func minuteLabel(_ mins: Int) -> String {
        let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h\(m > 0 ? " \(m)m" : "")" : "\(m)m"
    }
}

// MARK: - Daily bar chart

private struct BarEntry: Identifiable {
    let id = UUID()
    let dayLabel: String
    let minutes: Int
    let seriesName: String
    let colorHex: String
}

struct DailyBarChartView: View {
    let stats: WeekStats

    private var flatData: [BarEntry] {
        var result: [BarEntry] = []
        for day in stats.byDay {
            let label = day.date.dayNumber
            for cat in TimeCategory.allCases {
                let m = day.byCategory[cat] ?? 0
                guard m > 0 else { continue }
                result.append(BarEntry(dayLabel: label, minutes: m,
                                       seriesName: cat.displayName, colorHex: cat.hex))
            }
            if day.untracked > 0 {
                result.append(BarEntry(dayLabel: label, minutes: day.untracked,
                                       seriesName: "未追踪", colorHex: "#9CA3AF"))
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日分布").font(.headline)

            Chart(flatData) { entry in
                BarMark(
                    x: .value("日期", entry.dayLabel),
                    y: .value("分钟", entry.minutes),
                    stacking: .standard
                )
                .foregroundStyle(Color(hex: entry.colorHex))
            }
            .frame(height: 160)

            // Legend row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimeCategory.allCases, id: \.self) { cat in
                        HStack(spacing: 4) {
                            Circle().fill(Color(hex: cat.hex)).frame(width: 8, height: 8)
                            Text(cat.displayName).font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: "#9CA3AF")).frame(width: 8, height: 8)
                        Text("未追踪").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Category comparison

struct CategoryComparisonView: View {
    let current: WeekStats
    let average: WeekStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("vs 4周均值").font(.headline)

            ForEach(TimeCategory.allCases, id: \.self) { cat in
                let curr   = current.byCategory[cat] ?? 0
                let avg    = average.byCategory[cat] ?? 0
                let maxVal = max(curr, avg, 60)

                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Text(cat.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geo in
                            VStack(alignment: .leading, spacing: 3) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: cat.hex))
                                    .frame(width: geo.size.width * CGFloat(curr) / CGFloat(maxVal), height: 8)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: cat.hex).opacity(0.35))
                                    .frame(width: geo.size.width * CGFloat(avg) / CGFloat(maxVal), height: 8)
                            }
                        }
                        .frame(height: 24)

                        Text(diffLabel(curr: curr, avg: avg))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(curr >= avg ? .green : .red)
                            .frame(width: 50, alignment: .trailing)
                    }

                    HStack {
                        Text("").frame(width: 60)
                        Text("本周 \(minuteLabel(curr))")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                        Text("·").foregroundColor(.secondary)
                        Text("均值 \(minuteLabel(avg))")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func diffLabel(curr: Int, avg: Int) -> String {
        let diff = curr - avg
        if abs(diff) < 5 { return "持平" }
        return (diff >= 0 ? "↑ +" : "↓ ") + minuteLabel(abs(diff))
    }

    private func minuteLabel(_ mins: Int) -> String {
        let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h\(m > 0 ? "\(m)m" : "")" : "\(m)m"
    }
}
