import SwiftUI

struct DayDetailView: View {
    @ObservedObject var vm: CalendarViewModel
    let initialDate: Date
    @EnvironmentObject private var prefs: PrefsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Week strip — tap to change displayed day
            WeekStripView(vm: vm)
                .background(Color(.systemBackground))

            Divider()

            // Time grid (single-day)
            TimeGridView(vm: vm)
        }
        .navigationTitle(dayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.anchorDate = initialDate
            vm.viewMode   = .twoDay
            await vm.load()
        }
        .sheet(isPresented: $vm.showEntrySheet) {
            TimeEntrySheet(vm: vm)
                .environmentObject(prefs)
        }
    }

    private var dayTitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M月d日 EEE"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: vm.anchorDate)
    }
}

// MARK: - Week strip

struct WeekStripView: View {
    @ObservedObject var vm: CalendarViewModel
    private let cal = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDates(for: vm.anchorDate), id: \.self) { date in
                let dateStr   = date.localDateString()
                let isAnchor  = vm.displayDates.first == dateStr
                let isTrail   = vm.displayDates.count > 1 && vm.displayDates[1] == dateStr
                let isToday   = cal.isDateInToday(date)
                Button { Task { await vm.goToDate(date) } } label: {
                    WeekStripCell(date: date, isAnchor: isAnchor, isTrail: isTrail, isToday: isToday)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private func weekDates(for anchor: Date) -> [Date] {
        let wd = cal.component(.weekday, from: anchor) - 1
        guard let start = cal.date(byAdding: .day, value: -wd, to: anchor) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

private struct WeekStripCell: View {
    let date: Date
    let isAnchor: Bool
    let isTrail: Bool
    let isToday: Bool

    private let cal = Calendar.current
    private static let dowFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "zh_CN"); return f
    }()

    var body: some View {
        let weekday   = cal.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7
        let isSelected = isAnchor || isTrail

        VStack(spacing: 2) {
            Text(Self.dowFmt.string(from: date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isToday ? .red : (isWeekend ? Color(.tertiaryLabel) : .secondary))

            Text(String(cal.component(.day, from: date)))
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(
                    isSelected ? .white :
                    isToday    ? .red   :
                    isWeekend  ? .secondary : .primary
                )
                .frame(width: 30, height: 30)
                .background(circleBg)
                .clipShape(Circle())

            Text(lunarLabel(date))
                .font(.system(size: 9))
                .foregroundColor(isToday ? .red : Color(.tertiaryLabel))
        }
        .padding(.vertical, 2)
    }

    private var circleBg: Color {
        if isAnchor  { return isToday ? .red : Color(.systemGray4) }
        if isTrail   { return Color(.systemGray5) }
        return .clear
    }
}

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

// MARK: - Shared components (kept for compatibility)

struct ViewSwitcherView: View {
    @Binding var selected: CalendarViewModel.ViewMode
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewModel.ViewMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) { selected = mode }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selected == mode ? .white : .primary)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(selected == mode ? Color.blue : Color.clear)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DateNavigatorView: View {
    let label: String
    let onPrev: () -> Void; let onNext: () -> Void; let onPickDate: (Date) -> Void
    @State private var showPicker = false
    @State private var picked = Date()
    var body: some View {
        HStack(spacing: 4) {
            Button { onPrev() } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold)) }
            Button(label) { showPicker = true }.font(.system(size: 14, weight: .medium)).foregroundColor(.primary)
            Button { onNext() } label: { Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)) }
        }
        .foregroundColor(.primary)
        .sheet(isPresented: $showPicker) {
            DatePickerSheet(date: $picked, onConfirm: { onPickDate(picked); showPicker = false })
        }
    }
}

struct DatePickerSheet: View {
    @Binding var date: Date; let onConfirm: () -> Void
    var body: some View {
        NavigationView {
            DatePicker("选择日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical).environment(\.locale, Locale(identifier: "zh_CN")).padding()
                .navigationTitle("跳转到日期").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("确定") { onConfirm() } } }
        }
        .presentationDetents([.medium])
    }
}
