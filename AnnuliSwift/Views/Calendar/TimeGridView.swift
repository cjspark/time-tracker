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

                            // 4. Current-time indicator spanning all columns
                            CurrentTimeLineFullView(
                                hourLabelWidth: hourLabelWidth,
                                gridWidth: gridWidth
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

// MARK: - Current time indicator (full width)

struct CurrentTimeLineFullView: View {
    let hourLabelWidth: CGFloat
    let gridWidth: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 30)) { _ in
            let mins = Calendar.current.component(.hour, from: Date()) * 60
                + Calendar.current.component(.minute, from: Date())
            HStack(spacing: 0) {
                // Red dot aligned to right edge of hour-label column
                ZStack(alignment: .trailing) {
                    Color.clear
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .padding(.trailing, 2)
                }
                .frame(width: hourLabelWidth)

                // Red line across all day columns
                Rectangle()
                    .fill(Color.red)
                    .frame(width: gridWidth - hourLabelWidth, height: 1.5)
            }
            .offset(y: CGFloat(mins) * Constants.pxPerMinute - 0.75)
        }
    }
}

// MARK: - Day header cell

struct DayHeaderView: View {
    let dateStr: String

    private static let dowFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "zh_CN"); return f
    }()
    private static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()

    var body: some View {
        if let date = dateStr.toDate() {
            let isToday = Calendar.current.isDateInToday(date)
            VStack(spacing: 1) {
                Text(Self.dowFmt.string(from: date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isToday ? Color(red: 0.1, green: 0.4, blue: 1) : .secondary)
                Text(Self.dayFmt.string(from: date))
                    .font(.system(size: 17, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : .primary)
                    .frame(width: 30, height: 30)
                    .background(isToday ? Color(red: 0.1, green: 0.4, blue: 1) : Color.clear)
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
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
