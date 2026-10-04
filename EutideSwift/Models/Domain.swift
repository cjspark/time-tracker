import Foundation

struct Domain: Codable, Identifiable, Equatable {
    var id: UUID
    var userId: UUID
    var name: String
    var color: String
    var icon: String
    var sortOrder: Int
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, color, icon
        case userId    = "user_id"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}
