import Foundation
import Supabase

struct AchievementService {
    // MARK: - Fetch

    static func fetchAchievements(year: Int) async throws -> [Achievement] {
        guard let userId = AuthService.currentUserId else { return [] }
        var achievements: [Achievement] = try await supabase
            .from("achievements").select()
            .eq("user_id", value: userId)
            .eq("year", value: year)
            .execute().value

        let records = try await fetchAllRecords()
        let recordMap = Dictionary(grouping: records, by: \.achievementId)

        // First pass: attach records to each achievement
        for i in achievements.indices {
            achievements[i].records = recordMap[achievements[i].id] ?? []
        }

        // Second pass: attach children to parents
        var parentMap: [UUID: [Achievement]] = [:]
        for ach in achievements where ach.parentId != nil {
            parentMap[ach.parentId!, default: []].append(ach)
        }
        for i in achievements.indices {
            achievements[i].children = parentMap[achievements[i].id] ?? []
        }

        return achievements
    }

    static func fetchAllRecords() async throws -> [AchievementRecord] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("achievement_records").select().eq("user_id", value: userId).execute().value
    }

    // MARK: - CRUD

    static func add(_ insert: AchievementInsert) async throws -> Achievement {
        let result: [Achievement] = try await supabase
            .from("achievements").insert(insert).select().execute().value
        return result[0]
    }

    static func rename(id: UUID, name: String) async throws {
        struct Patch: Encodable { let name: String }
        try await supabase.from("achievements").update(Patch(name: name)).eq("id", value: id).execute()
    }

    static func updateTarget(id: UUID, targetValue: Double) async throws {
        struct Patch: Encodable { let targetValue: Double
            enum CodingKeys: String, CodingKey { case targetValue = "target_value" }
        }
        try await supabase.from("achievements").update(Patch(targetValue: targetValue)).eq("id", value: id).execute()
    }

    static func delete(id: UUID) async throws {
        try await supabase.from("achievements").delete().eq("id", value: id).execute()
    }

    static func archive(id: UUID) async throws {
        struct Patch: Encodable { let archivedAt: String
            enum CodingKeys: String, CodingKey { case archivedAt = "archived_at" }
        }
        let now = ISO8601DateFormatter().string(from: Date())
        try await supabase.from("achievements").update(Patch(archivedAt: now)).eq("id", value: id).execute()
    }

    static func unarchive(id: UUID) async throws {
        // Set archived_at to null via raw dict
        try await supabase.from("achievements").update(["archived_at": AnyEncodable(value: NSNull())]).eq("id", value: id).execute()
    }

    // MARK: - Records

    static func addRecord(_ insert: AchievementRecordInsert) async throws -> AchievementRecord {
        let result: [AchievementRecord] = try await supabase
            .from("achievement_records").insert(insert).select().execute().value
        return result[0]
    }

    static func deleteRecord(id: UUID) async throws {
        try await supabase.from("achievement_records").delete().eq("id", value: id).execute()
    }
}
