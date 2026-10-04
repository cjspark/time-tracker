import Foundation

struct RewardItem: Codable, Identifiable, Equatable {
    var id: UUID
    var userId: UUID
    var name: String
    var tier: RewardTier
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, tier
        case userId    = "user_id"
        case createdAt = "created_at"
    }
}

struct RewardItemForm {
    var name: String     = ""
    var tier: RewardTier = .small
}
