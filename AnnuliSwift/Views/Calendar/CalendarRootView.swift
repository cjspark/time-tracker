import SwiftUI

enum CalendarNavDest: Hashable {
    case month(Date)
    case day(Date)
}

struct CalendarRootView: View {
    @StateObject private var calVM = CalendarViewModel()
    @EnvironmentObject private var prefs: PrefsViewModel
    // Start on today's day detail; back→month, back→year
    @State private var path: [CalendarNavDest] = [.month(Date()), .day(Date())]

    var body: some View {
        NavigationStack(path: $path) {
            YearCalendarView(path: $path)
                .navigationDestination(for: CalendarNavDest.self) { dest in
                    switch dest {
                    case .month(let d):
                        MonthCalendarView(month: d, path: $path)
                    case .day(let d):
                        DayDetailView(vm: calVM, initialDate: d)
                            .environmentObject(prefs)
                    }
                }
        }
    }
}
