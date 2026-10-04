import SwiftUI

struct MonthCalendarView: View {
    @State private var month: Date
    @Binding var path: [CalendarNavDest]

    private let cal = Calendar.current

    private static let monthFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM"; f.locale = Locale(identifier: "en_US"); return f
    }()
    private static let yearFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f
    }()

    init(month: Date, path: Binding<[CalendarNavDest]>) {
        _month  = State(initialValue: month)
        _path   = path
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month title + year + prev/next
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Self.monthFmt.string(from: month))
                        .font(.system(size: 28, weight: .bold))
                    Text(Self.yearFmt.string(from: month))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 16) {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Button { shiftMonth(1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)

            // Day-of-week header
            HStack(spacing: 0) {
                ForEach(["日","一","二","三","四","五","六"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)

            Divider()

            // Calendar grid
            let days = calDays()
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 0
            ) {
                ForEach(days.indices, id: \.self) { i in
                    if let date = days[i] {
                        MonthDayCell(date: date) {
                            path.append(.day(date))
                        }
                    } else {
                        Color.clear.frame(height: cellHeight)
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer()
        }
        .navigationTitle(Self.monthFmt.string(from: month))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    month = Calendar.current.startOfDay(for: Date())
                    // Jump to today
                    var dc = cal.dateComponents([.year, .month], from: Date())
                    dc.day = 1
                    if let m = cal.date(from: dc) { month = m }
                } label: {
                    Text("今")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private var cellHeight: CGFloat { 54 }

    private func shiftMonth(_ n: Int) {
        if let d = cal.date(byAdding: .month, value: n, to: month) { month = d }
    }

    private func calDays() -> [Date?] {
        var dc = cal.dateComponents([.year, .month], from: month)
        dc.day = 1
        guard let firstDay = cal.date(from: dc) else { return [] }
        let firstWeekday = cal.component(.weekday, from: firstDay) - 1
        let daysInMonth  = cal.range(of: .day, in: .month, for: firstDay)!.count
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in 1...daysInMonth {
            var dc2 = dc; dc2.day = d
            days.append(cal.date(from: dc2))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

// MARK: - Day cell

private struct MonthDayCell: View {
    let date: Date
    let onTap: () -> Void

    private let cal = Calendar.current

    var body: some View {
        let isToday   = cal.isDateInToday(date)
        let weekday   = cal.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7

        Button(action: onTap) {
            VStack(spacing: 0) {
                Divider()
                Text(String(cal.component(.day, from: date)))
                    .font(.system(size: 18, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : (isWeekend ? .secondary : .primary))
                    .frame(width: 34, height: 34)
                    .background(isToday ? Color.red : Color.clear)
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 54)
    }
}
