import SwiftUI

struct CalendarRootView: View {
    @StateObject private var vm = CalendarViewModel()
    @EnvironmentObject private var prefs: PrefsViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Top bar: view switcher + date navigator
            HStack(spacing: 12) {
                ViewSwitcherView(selected: $vm.viewMode)
                Spacer()
                DateNavigatorView(
                    label: navigationLabel,
                    onPrev: { Task { await vm.navigate(by: -navStep) } },
                    onNext: { Task { await vm.navigate(by: navStep) } },
                    onPickDate: { vm.anchorDate = $0; Task { await vm.load() } }
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            Divider()

            TimeGridView(vm: vm)
        }
        .task { await vm.load() }
        .sheet(isPresented: $vm.showEntrySheet) {
            TimeEntrySheet(vm: vm)
                .environmentObject(prefs)
        }
    }

    private var navStep: Int {
        switch vm.viewMode {
        case .day: return 1
        case .twoDay: return 2
        case .week: return 7
        }
    }

    private var navigationLabel: String {
        let dates = vm.displayDates.compactMap { $0.toDate() }
        if let first = dates.first {
            switch vm.viewMode {
            case .day:
                let fmt = DateFormatter()
                fmt.dateFormat = "M月d日 EEE"
                fmt.locale = Locale(identifier: "zh_CN")
                return fmt.string(from: first)
            case .twoDay:
                return "\(first.monthDay) – \(dates.last?.monthDay ?? "")"
            case .week:
                return WeekCalculator.weekLabel(dates: dates)
            }
        }
        return ""
    }
}

// MARK: - View switcher

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

// MARK: - Date navigator

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
                    .foregroundColor(.primary)
            }
            Button(label) { showDatePicker = true }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            Button { onNext() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(date: $pickedDate, onConfirm: {
                onPickDate(pickedDate)
                showDatePicker = false
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
