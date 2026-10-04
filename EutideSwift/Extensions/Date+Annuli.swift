import Foundation
import SwiftUI

// MARK: - Date extensions

extension Date {
    func localDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale.current
        return fmt.string(from: self)
    }

    static func today() -> Date { Date() }
    static func todayString() -> String { Date().localDateString() }

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var weekdayShort: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: self)
    }

    var dayNumber: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: self)
    }

    var monthDay: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "M/d"
        return fmt.string(from: self)
    }
}

extension String {
    func toDate() -> Date? {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: self)
    }
}
