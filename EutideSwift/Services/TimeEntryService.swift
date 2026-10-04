import Foundation
import Supabase

struct TimeEntryService {
    static func fetch(dates: [String]) async throws -> [TimeEntry] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("time_entries")
            .select()
            .eq("user_id", value: userId)
            .in("date", values: dates)
            .order("start_time")
            .execute()
            .value
    }

    static func save(form: TimeEntryForm, id: UUID? = nil) async throws -> TimeEntry {
        guard let userId = AuthService.currentUserId else { throw AnnuliError.notAuthenticated }

        let startFull = form.startTime + ":00"
        let endFull   = form.endTime + ":00"

        if let existingId = id {
            struct Update: Encodable {
                let date, startTime, endTime, hobby, color: String
                let notes: String?
                let mood: Int?
                enum CodingKeys: String, CodingKey {
                    case date, hobby, color, notes, mood
                    case startTime = "start_time"
                    case endTime   = "end_time"
                }
            }
            let update = Update(date: form.date, startTime: startFull, endTime: endFull,
                                hobby: form.hobby, color: form.color,
                                notes: form.notes.isEmpty ? nil : form.notes, mood: form.mood)
            let updated: [TimeEntry] = try await supabase
                .from("time_entries").update(update).eq("id", value: existingId).select().execute().value
            return updated[0]
        } else {
            struct Insert: Encodable {
                let userId: UUID
                let date, startTime, endTime, hobby, color: String
                let notes: String?
                let mood: Int?
                enum CodingKeys: String, CodingKey {
                    case date, hobby, color, notes, mood
                    case userId    = "user_id"
                    case startTime = "start_time"
                    case endTime   = "end_time"
                }
            }
            let insert = Insert(userId: userId, date: form.date, startTime: startFull, endTime: endFull,
                                hobby: form.hobby, color: form.color,
                                notes: form.notes.isEmpty ? nil : form.notes, mood: form.mood)
            let created: [TimeEntry] = try await supabase
                .from("time_entries").insert(insert).select().execute().value
            return created[0]
        }
    }

    static func delete(id: UUID) async throws {
        try await supabase.from("time_entries").delete().eq("id", value: id).execute()
    }

    static func fetchAll() async throws -> [TimeEntry] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("time_entries").select().eq("user_id", value: userId).execute().value
    }
}

enum AnnuliError: Error {
    case notAuthenticated
    case invalidData
}
