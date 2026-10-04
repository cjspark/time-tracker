import Foundation

struct WeekCalculator {
    // Monday-start week. Returns [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
    static func weekDates(containing date: Date) -> [Date] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2  // Monday
        let weekday = cal.component(.weekday, from: date)
        // weekday: 1=Sun,2=Mon,...,7=Sat  →  offset to Monday
        let daysFromMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: date)!
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: monday)! }
    }

    static func weekDateStrings(containing date: Date) -> [String] {
        weekDates(containing: date).map { $0.localDateString() }
    }

    static func weekLabel(dates: [Date]) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M月d日"
        guard let first = dates.first, let last = dates.last else { return "" }
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    // Untracked minutes for a set of date strings and their recorded minutes
    static func untrackedMinutes(dateStr: String, recordedMinutes: Int) -> Int {
        guard let d = dateStr.toDate(), d <= Date() else { return 0 }
        return max(0, 24 * 60 - recordedMinutes)
    }
}

// MARK: - WeekStats (for Review view)

struct WeekStats {
    var weekLabel: String
    var weekStart: Date
    var totalMinutes: Int
    var byCategory: [TimeCategory: Int]
    var untracked: Int
    var byDay: [DayStats]
}

struct DayStats {
    var date: Date
    var byCategory: [TimeCategory: Int]
    var untracked: Int
}
