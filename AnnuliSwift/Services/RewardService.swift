import Foundation
import Supabase

struct RewardService {

    static func fetchAll() async throws -> [RewardItem] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("reward_pool")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func create(form: RewardItemForm) async throws -> RewardItem {
        guard let userId = AuthService.currentUserId else { throw AnnuliError.notAuthenticated }
        struct Insert: Encodable {
            let userId: UUID; let name: String; let tier: String
            enum CodingKeys: String, CodingKey {
                case name, tier
                case userId = "user_id"
            }
        }
        let i = Insert(userId: userId, name: form.name, tier: form.tier.rawValue)
        let created: [RewardItem] = try await supabase
            .from("reward_pool").insert(i).select().execute().value
        return created[0]
    }

    static func delete(id: UUID) async throws {
        try await supabase.from("reward_pool").delete().eq("id", value: id).execute()
    }
}
