import Foundation
import Supabase

struct HobbyService {
    static func fetchPreferences() async throws -> [HobbyPreference] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("hobby_preferences").select().eq("user_id", value: userId).execute().value
    }

    static func fetchHistory() async throws -> [HobbyHistory] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("hobby_history").select().eq("user_id", value: userId).execute().value
    }

    static func updateCategory(hobby: String, category: String) async throws {
        guard let userId = AuthService.currentUserId else { return }
        struct Row: Encodable {
            let userId: UUID; let hobby, category: String
            enum CodingKeys: String, CodingKey { case hobby, category; case userId = "user_id" }
        }
        try await supabase
            .from("hobby_preferences")
            .upsert(Row(userId: userId, hobby: hobby, category: category), onConflict: "user_id,hobby")
            .execute()
    }

    static func updateHistorical(hobby: String, minutes: Int) async throws {
        guard let userId = AuthService.currentUserId else { return }
        struct Row: Encodable {
            let userId: UUID; let hobby: String; let historicalMinutes: Int
            enum CodingKeys: String, CodingKey {
                case hobby
                case userId = "user_id"
                case historicalMinutes = "historical_minutes"
            }
        }
        try await supabase
            .from("hobby_history")
            .upsert(Row(userId: userId, hobby: hobby, historicalMinutes: minutes), onConflict: "user_id,hobby")
            .execute()
    }
}
