import Foundation

struct TimeEntry: Codable, Identifiable, Equatable {
    var id: UUID
    var userId: UUID
    var date: String          // "YYYY-MM-DD"
    var startTime: String     // "HH:MM:SS"
    var endTime: String       // "HH:MM:SS"
    var hobby: String
    var color: String         // hex
    var notes: String?
    var mood: Int?            // 1-5
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, date, hobby, color, notes, mood
        case userId = "user_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case createdAt = "created_at"
    }

    var startMinutes: Int { startTime.timeToMinutes() }
    var endMinutes: Int   { endTime.timeToMinutes() }
    var durationMinutes: Int { max(0, endMinutes - startMinutes) }
}

struct TimeEntryForm {
    var date: String
    var startTime: String     // "HH:MM"
    var endTime: String       // "HH:MM"
    var hobby: String
    var color: String
    var notes: String
    var mood: Int?

    static func empty(date: String, startMin: Int = 0, endMin: Int = 60) -> TimeEntryForm {
        TimeEntryForm(
            date: date,
            startTime: startMin.minutesToHHMM(),
            endTime: endMin.minutesToHHMM(),
            hobby: "",
            color: "#8B5CF6",
            notes: "",
            mood: nil
        )
    }
}
