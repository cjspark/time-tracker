import SwiftUI

// Day detail: week strip + view mode switcher + time grid
struct DayDetailView: View {
    @ObservedObject var vm: CalendarViewModel
    let initialDate: Date
    @EnvironmentObject private var prefs: PrefsViewModel

    private let cal = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // ── Week strip ──────────────────────────────────────────
            WeekStripView(vm: vm)
                .background(Color(.systemBackground))

            // ── View mode + today button ────────────────────────────
            HStack(spacing: 8) {
                ViewSwitcherView(selected: $vm.viewMode)
                    .onChange(of: vm.viewMode) { _ in Task { await vm.load() } }

                Button("今") {
                    Task { await vm.goToDate(Date()) }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(cal.isDateInToday(vm.anchorDate) ? .white : .blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(cal.isDateInToday(vm.anchorDate) ? Color.blue : Color.clear)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue, lineWidth: cal.isDateInToday(vm.anchorDate) ? 0 : 1))

                Spacer()

                DateNavigatorView(
                    label: navigationLabel,
                    onPrev: { Task { await vm.navigate(by: -navStep) } },
                    onNext: { Task { await vm.navigate(by:  navStep) } },
                    onPickDate: { d in Task { await vm.goToDate(d) } }
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            // ── Time grid ───────────────────────────────────────────
            TimeGridView(vm: vm)
        }
        .navigationTitle(dayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            vm.anchorDate = initialDate
            if vm.viewMode == .week { vm.viewMode = .day }
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

    private var navStep: Int {
        switch vm.viewMode {
        case .day: return 1; case .twoDay: return 2; case .week: return 7
        }
    }

    private var navigationLabel: String {
        let dates = vm.displayDates.compactMap { $0.toDate() }
        guard let first = dates.first else { return "" }
        switch vm.viewMode {
        case .day:
            let fmt = DateFormatter(); fmt.dateFormat = "M月d日 EEE"
            fmt.locale = Locale(identifier: "zh_CN")
            return fmt.string(from: first)
        case .twoDay:
            return "\(first.monthDay) – \(dates.last?.monthDay ?? "")"
        case .week:
            return WeekCalculator.weekLabel(dates: dates)
        }
    }
}

// MARK: - Week strip

struct WeekStripView: View {
    @ObservedObject var vm: CalendarViewModel
    private let cal = Calendar.current

    var body: some View {
        let weekDates = weekDates(for: vm.anchorDate)
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                let dateStr  = date.localDateString()
                let isShown  = vm.displayDates.contains(dateStr)
                let isToday  = cal.isDateInToday(date)

                Button {
                    Task { await vm.goToDate(date) }
                } label: {
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
        let weekday = cal.component(.weekday, from: anchor) - 1   // 0 = Sun
        guard let start = cal.date(byAdding: .day, value: -weekday, to: anchor) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

private struct WeekStripCell: View {
    let date: Date
    let isShown: Bool   // currently displayed in time grid
    let isToday: Bool

    private let cal = Calendar.current
    private static let dowFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"
        f.locale = Locale(identifier: "zh_CN"); return f
    }()

    var body: some View {
        VStack(spacing: 2) {
            Text(Self.dowFmt.string(from: date))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isToday ? Color(red: 0.9, green: 0.2, blue: 0.1) : .secondary)

            Text(String(cal.component(.day, from: date)))
                .font(.system(size: 16, weight: isToday || isShown ? .bold : .regular))
                .foregroundColor(isToday ? .white : (isShown ? Color(red: 0.1, green: 0.4, blue: 1) : .primary))
                .frame(width: 30, height: 30)
                .background(
                    isToday ? Color(red: 0.9, green: 0.2, blue: 0.1) :
                    (isShown ? Color(red: 0.1, green: 0.4, blue: 1).opacity(0.15) : Color.clear)
                )
                .clipShape(Circle())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Shared: view switcher + date navigator (reused in day detail)

struct ViewSwitcherView: View {
    @Binding var selected: CalendarViewModel.ViewMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CalendarViewModel.ViewMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) { selected = mode }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selected == mode ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(selected == mode ? Color.blue : Color.clear)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DateNavigatorView: View {
    let label: String
    let onPrev: () -> Void
    let onNext: () -> Void
    let onPickDate: (Date) -> Void

    @State private var showDatePicker = false
    @State private var pickedDate = Date()

    var body: some View {
        HStack(spacing: 4) {
            Button { onPrev() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
            }
            Button(label) { showDatePicker = true }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            Button { onNext() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .foregroundColor(.primary)
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(date: $pickedDate, onConfirm: {
                onPickDate(pickedDate); showDatePicker = false
            })
        }
    }
}

struct DatePickerSheet: View {
    @Binding var date: Date
    let onConfirm: () -> Void

    var body: some View {
        NavigationView {
            DatePicker("选择日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .padding()
                .navigationTitle("跳转到日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确定") { onConfirm() }
                    }
                }
        }
        .presentationDetents([.medium])
    }
}
