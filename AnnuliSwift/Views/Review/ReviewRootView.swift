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
                        // Week navigation
                        HStack {
                            Button { Task { await vm.goBack(); await vm.load(prefs: prefs) } } label: {
                                Image(systemName: "chevron.left")
                            }
                            Spacer()
                            Text(week.weekLabel)
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Button { Task { await vm.goForward(); await vm.load(prefs: prefs) } } label: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(vm.weekOffset == 0 ? .secondary : .primary)
                            }
                            .disabled(vm.weekOffset == 0)
                        }
                        .padding(.horizontal)

                        // Donut chart
                        TimeCategoryDonutView(stats: week)
                            .padding(.horizontal)

                        // Daily bar chart
                        DailyBarChartView(stats: week)
                            .padding(.horizontal)

                        // vs 4-week average
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
}

// MARK: - Donut chart

struct TimeCategoryDonutView: View {
    let stats: WeekStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("时间分布").font(.headline)

            if #available(iOS 17, *) {
                Chart(chartData, id: \.category) { item in
                    SectorMark(angle: .value("时间", item.minutes), innerRadius: .ratio(0.5))
                        .foregroundStyle(Color(hex: item.color))
                }
                .frame(height: 200)
            } else {
                // Fallback: horizontal bar segments
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        ForEach(chartData, id: \.category) { item in
                            let ratio = totalMinutes > 0 ? CGFloat(item.minutes) / CGFloat(totalMinutes) : 0
                            Rectangle()
                                .fill(Color(hex: item.color))
                                .frame(width: geo.size.width * ratio)
                        }
                    }
                    .cornerRadius(6)
                }
                .frame(height: 24)
            }

            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(chartData, id: \.category) { item in
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: item.color)).frame(width: 10, height: 10)
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

    private var chartData: [(category: TimeCategory, name: String, minutes: Int, color: String)] {
        TimeCategory.allCases.map { cat in
            (cat, cat.displayName, stats.byCategory[cat] ?? 0, cat.hex)
        }.filter { $0.minutes > 0 }
    }

    private var totalMinutes: Int { chartData.reduce(0) { $0 + $1.minutes } }

    private func minuteLabel(_ mins: Int) -> String {
        let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h\(m > 0 ? "\(m)m" : "")" : "\(m)m"
    }
}

// MARK: - Daily bar chart

struct DailyBarChartView: View {
    let stats: WeekStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日分布").font(.headline)

            if #available(iOS 16, *) {
                Chart {
                    ForEach(stats.byDay, id: \.date) { day in
                        ForEach(TimeCategory.allCases, id: \.self) { cat in
                            let mins = day.byCategory[cat] ?? 0
                            if mins > 0 {
                                BarMark(
                                    x: .value("日期", day.date.dayNumber),
                                    y: .value("分钟", mins)
                                )
                                .foregroundStyle(Color(hex: cat.hex))
                            }
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 160)
            } else {
                // Fallback: simple bar for each day
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(stats.byDay, id: \.date) { day in
                        let total = day.byCategory.values.reduce(0, +)
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: total > 0 ? CGFloat(total) / 10 : 2)
                            Text(day.date.dayNumber)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 100)
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
                let curr = current.byCategory[cat] ?? 0
                let avg  = average.byCategory[cat] ?? 0
                let maxVal = max(curr, avg, 60)

                HStack(spacing: 8) {
                    Text(cat.displayName)
                        .font(.system(size: 12))
                        .frame(width: 60, alignment: .leading)

                    GeometryReader { geo in
                        VStack(alignment: .leading, spacing: 3) {
                            // Current week bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: cat.hex))
                                .frame(width: geo.size.width * CGFloat(curr) / CGFloat(maxVal), height: 8)
                            // Average bar (dashed appearance)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: cat.hex).opacity(0.35))
                                .frame(width: geo.size.width * CGFloat(avg) / CGFloat(maxVal), height: 8)
                        }
                    }
                    .frame(height: 24)

                    Text(diffLabel(curr: curr, avg: avg))
                        .font(.system(size: 11))
                        .foregroundColor(curr >= avg ? .green : .red)
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func diffLabel(curr: Int, avg: Int) -> String {
        let diff = curr - avg
        let h = abs(diff) / 60
        let m = abs(diff) % 60
        let label = h > 0 ? "\(h)h\(m > 0 ? "\(m)m" : "")" : "\(m)m"
        return diff >= 0 ? "+\(label)" : "-\(label)"
    }
}
