import SwiftUI

struct TimeGridView: View {
    @ObservedObject var vm: CalendarViewModel

    private let hourLabelWidth: CGFloat = 48
    private let columnMinWidth: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            let colCount  = vm.displayDates.count
            let colWidth  = max(columnMinWidth, (geo.size.width - hourLabelWidth) / CGFloat(colCount))
            let gridWidth = geo.size.width

            VStack(spacing: 0) {
                // ── Sticky day-header row ──────────────────────────────────
                HStack(spacing: 0) {
                    Spacer().frame(width: hourLabelWidth)
                    ForEach(vm.displayDates, id: \.self) { dateStr in
                        DayHeaderView(dateStr: dateStr)
                            .frame(width: colWidth)
                    }
                }
                .background(Color(.systemBackground))

                Divider()

                // ── Scrollable time grid ───────────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {

                            // 1. Hour labels + horizontal lines
                            HourRulerView(totalWidth: gridWidth)

                            // 2. Vertical column separators
                            HStack(spacing: 0) {
                                Spacer().frame(width: hourLabelWidth)
                                ForEach(0..<colCount, id: \.self) { _ in
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color(.separator).opacity(0.25))
                                            .frame(width: 0.5, height: Constants.totalGridHeight)
                                        Spacer()
                                    }
                                    .frame(width: colWidth)
                                }
                            }

                            // 3. Day columns (today gets subtle blue tint)
                            HStack(spacing: 0) {
                                Spacer().frame(width: hourLabelWidth)
                                ForEach(vm.displayDates, id: \.self) { dateStr in
                                    DayColumnView(
                                        dateStr: dateStr,
                                        entries: vm.entries(for: dateStr),
                                        columnWidth: colWidth,
                                        onTap: { s, e in vm.openCreate(date: dateStr, startMin: s, endMin: e) },
                                        onEditEntry: { vm.openEdit($0) }
                                    )
                                    .frame(width: colWidth)
                                }
                            }

                            // 4. Current-time indicator — only on today's column
                            let todayStr = Date().localDateString()
                            let todayIdx = vm.displayDates.firstIndex(of: todayStr)
                            let todayColX: CGFloat? = todayIdx.map {
                                hourLabelWidth + CGFloat($0) * colWidth
                            }
                            CurrentTimeLineFullView(
                                hourLabelWidth: hourLabelWidth,
                                gridWidth: gridWidth,
                                todayColumnX: todayColX,
                                columnWidth: colWidth
                            )
                        }
                        .frame(height: Constants.totalGridHeight)
                        .id("grid")
                    }
                    .onAppear {
                        let mins = Calendar.current.component(.hour, from: Date()) * 60
                            + Calendar.current.component(.minute, from: Date())
                        let offsetY = CGFloat(mins) * Constants.pxPerMinute - geo.size.height / 2
                        proxy.scrollTo("grid", anchor: UnitPoint(x: 0, y: max(0, offsetY) / Constants.totalGridHeight))
                    }
                }
            }
        }
    }
}

// MARK: - Current time indicator (today column only, Apple Calendar style)

struct CurrentTimeLineFullView: View {
    let hourLabelWidth: CGFloat
    let gridWidth: CGFloat
    let todayColumnX: CGFloat?   // nil = today not in view
    let columnWidth: CGFloat

    var body: some View {
        if let colX = todayColumnX {
            TimelineView(.animation(minimumInterval: 30)) { _ in
                let now  = Date()
                let mins = Calendar.current.component(.hour, from: now) * 60
                         + Calendar.current.component(.minute, from: now)
                let label = String(format: "%02d:%02d", mins / 60, mins % 60)

                ZStack(alignment: .leading) {
                    // Red line — only spans today's column
                    HStack(spacing: 0) {
                        Color.clear.frame(width: colX)
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: columnWidth, height: 1.5)
                        Spacer()
                    }
                    .frame(width: gridWidth)

                    // Red time pill in hour-label area
                    Text(label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(5)
                        .frame(width: hourLabelWidth, alignment: .trailing)
                        .padding(.trailing, 2)
                }
                .offset(y: CGFloat(mins) * Constants.pxPerMinute - 9)
            }
        }
    }
}

// MARK: - Day header cell (Apple Calendar style: "周三 – 9月9日" + lunar + red underline for today)

private func lunarLabel(_ date: Date) -> String {
    let cc = Calendar(identifier: .chinese)
    let c  = cc.dateComponents([.month, .day, .isLeapMonth], from: date)
    guard let day = c.day, let month = c.month else { return "" }
    if day == 1 {
        let names = ["正月","二月","三月","四月","五月","六月",
                     "七月","八月","九月","十月","冬月","腊月"]
        guard month >= 1 && month <= 12 else { return "" }
        return (c.isLeapMonth ?? false) ? "闰\(names[month-1])" : names[month-1]
    }
    let days = ["初一","初二","初三","初四","初五","初六","初七","初八","初九","初十",
                "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十",
                "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"]
    guard day >= 1 && day <= 30 else { return "" }
    return days[day - 1]
}

struct DayHeaderView: View {
    let dateStr: String

    private static let fullFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "zh_CN"); return f
    }()
    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M月d日"; f.locale = Locale(identifier: "zh_CN"); return f
    }()

    var body: some View {
        if let date = dateStr.toDate() {
            let isToday = Calendar.current.isDateInToday(date)
            let accent: Color = isToday ? .red : .primary

            VStack(spacing: 1) {
                HStack(spacing: 4) {
                    Text(Self.fullFmt.string(from: date))
                        .foregroundColor(isToday ? .red : .secondary)
                    Text("–")
                        .foregroundColor(.secondary)
                    Text(Self.dateFmt.string(from: date))
                        .foregroundColor(accent)
                }
                .font(.system(size: 12, weight: .semibold))

                Text(lunarLabel(date))
                    .font(.system(size: 10))
                    .foregroundColor(isToday ? .red : Color(.tertiaryLabel))

                if isToday {
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 1.5)
                        .padding(.horizontal, 14)
                        .padding(.top, 1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Hour ruler

struct HourRulerView: View {
    let totalWidth: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<25) { hour in
                let y = CGFloat(hour * 60) * Constants.pxPerMinute
                HStack(spacing: 0) {
                    Text(hour < 24 ? String(format: "%02d:00", hour) : "")
                        .font(.system(size: 10))
                        .foregroundColor(Color(.tertiaryLabel))
                        .frame(width: 48, alignment: .trailing)
                        .padding(.trailing, 6)
                    Rectangle()
                        .fill(Color(.separator).opacity(0.35))
                        .frame(height: 0.5)
                }
                .frame(width: totalWidth)
                .offset(y: y - 6)
            }
        }
        .frame(width: totalWidth, height: Constants.totalGridHeight)
    }
}
