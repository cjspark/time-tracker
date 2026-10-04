import Foundation

struct DomainOutput: Codable, Identifiable, Equatable {
    var id: UUID
    var userId: UUID
    var domainId: UUID
    var title: String
    var date: String        // "YYYY-MM-DD"
    var count: Int?
    var notes: String?
    var rewardTier: RewardTier?
    var isCompleted: Bool
    var completedAt: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date, count, notes
        case userId      = "user_id"
        case domainId    = "domain_id"
        case rewardTier  = "reward_tier"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case createdAt   = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self, forKey: .id)
        userId      = try c.decode(UUID.self, forKey: .userId)
        domainId    = try c.decode(UUID.self, forKey: .domainId)
        title       = try c.decode(String.self, forKey: .title)
        date        = try c.decode(String.self, forKey: .date)
        count       = try c.decodeIfPresent(Int.self, forKey: .count)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes)
        rewardTier  = try c.decodeIfPresent(RewardTier.self, forKey: .rewardTier)
        isCompleted = (try c.decodeIfPresent(Bool.self, forKey: .isCompleted)) ?? false
        completedAt = try c.decodeIfPresent(String.self, forKey: .completedAt)
        createdAt   = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

struct OutputForm {
    var domainId:   UUID
    var title:      String      = ""
    var date:       String      = Date().localDateString()
    var count:      Int?        = nil
    var notes:      String      = ""
    var rewardTier: RewardTier? = nil
}
