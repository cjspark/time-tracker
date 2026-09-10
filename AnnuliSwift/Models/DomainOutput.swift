import Foundation

struct DomainOutput: Codable, Identifiable, Equatable {
    var id: UUID
    var userId: UUID
    var domainId: UUID
    var title: String
    var date: String      // "YYYY-MM-DD"
    var count: Int?
    var notes: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, date, count, notes
        case userId    = "user_id"
        case domainId  = "domain_id"
        case createdAt = "created_at"
    }
}

struct OutputForm {
    var domainId: UUID
    var title: String = ""
    var date: String  = Date().localDateString()
    var count: Int?   = nil
    var notes: String = ""
}
