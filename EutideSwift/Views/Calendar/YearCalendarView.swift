import SwiftUI

struct YearCalendarView: View {
    @Binding var path: [CalendarNavDest]
    @State private var year: Int = Calendar.current.component(.year, from: Date())

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(String(year))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.red)
                    Spacer()
                    // Year navigation
                    HStack(spacing: 4) {
                        Button { year -= 1 } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Button { year += 1 } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...12, id: \.self) { month in
                        MiniMonthView(year: year, month: month)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let d = DateComponents(calendar: .current,
                                                          year: year, month: month, day: 1).date {
                                    path.append(.month(d))
                                }
                            }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(String(year))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Mini month (12-up view)

struct MiniMonthView: View {
    let year: Int
    let month: Int

    private let cal = Calendar.current

    private static let monthFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM"; f.locale = Locale(identifier: "en_US"); return f
    }()
    private static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Self.monthFmt.string(from: firstDay))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)

            // DOW header
            HStack(spacing: 0) {
                ForEach(["日","一","二","三","四","五","六"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let days = calDays()
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 2
            ) {
                ForEach(days.indices, id: \.self) { i in
                    if let date = days[i] {
                        let isToday = cal.isDateInToday(date)
                        Text(Self.dayFmt.string(from: date))
                            .font(.system(size: 8, weight: isToday ? .bold : .regular))
                            .foregroundColor(isToday ? .white : dayColor(date))
                            .frame(width: 14, height: 14)
                            .background(isToday ? Color.red : Color.clear)
                            .clipShape(Circle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(height: 14)
                    }
                }
            }
        }
    }

    private var firstDay: Date {
        DateComponents(calendar: .current, year: year, month: month, day: 1).date ?? Date()
    }

    private func dayColor(_ date: Date) -> Color {
        let wd = cal.component(.weekday, from: date)
        return (wd == 1 || wd == 7) ? Color(.tertiaryLabel) : .primary
    }

    private func calDays() -> [Date?] {
        let firstWeekday = cal.component(.weekday, from: firstDay) - 1
        let daysInMonth  = cal.range(of: .day, in: .month, for: firstDay)!.count
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in 1...daysInMonth {
            days.append(DateComponents(calendar: .current, year: year, month: month, day: d).date)
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}
