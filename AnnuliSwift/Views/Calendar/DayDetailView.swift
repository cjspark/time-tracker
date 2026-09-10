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
            vm.viewMode   = .day
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
                let dateStr = date.localDateString()
                let isShown = vm.displayDates.contains(dateStr)
                let isToday = cal.isDateInToday(date)
                Button { Task { await vm.goToDate(date) } } label: {
                    WeekStripCell(date: date, isShown: isShown, isToday: isToday)
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
    let isShown: Bool
    let isToday: Bool

    private let cal = Calendar.current
    private static let dowFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; f.locale = Locale(identifier: "zh_CN"); return f
    }()

    var body: some View {
        VStack(spacing: 2) {
            Text(Self.dowFmt.string(from: date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isToday ? .red : .secondary)
            Text(String(cal.component(.day, from: date)))
                .font(.system(size: 16, weight: isToday || isShown ? .bold : .regular))
                .foregroundColor(isToday ? .white : (isShown ? Color.blue : .primary))
                .frame(width: 30, height: 30)
                .background(
                    isToday ? Color.red :
                    (isShown ? Color.blue.opacity(0.15) : Color.clear)
                )
                .clipShape(Circle())
        }
        .padding(.vertical, 2)
    }
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
