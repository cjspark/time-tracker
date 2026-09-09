import Foundation

// MARK: - Achievement

struct Achievement: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var category: String
    var name: String
    var unit: String
    var targetValue: Double
    var year: Int
    var template: AchievementTemplate
    var metadata: AchievementMetaWrapper?
    var parentId: UUID?
    var archivedAt: String?
    var createdAt: String?

    // Enriched client-side (not from DB)
    var records: [AchievementRecord] = []
    var children: [Achievement] = []

    var currentValue: Double {
        if !children.isEmpty {
            return children.reduce(0) { $0 + $1.targetValue }
        }
        return records.reduce(0) { $0 + $1.value }
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }

    var isArchived: Bool { archivedAt != nil }

    enum CodingKeys: String, CodingKey {
        case id, category, name, unit, year, template, metadata
        case userId = "user_id"
        case targetValue = "target_value"
        case parentId = "parent_id"
        case archivedAt = "archived_at"
        case createdAt = "created_at"
    }
}

// MARK: - Template

enum AchievementTemplate: String, Codable {
    case general, dividend, deposit, stockProfit = "stock_profit", habit
}

// MARK: - Metadata

struct AchievementMetaWrapper: Codable {
    // General habit
    var unit: String?          // "天" | "周" | "年"
    var period: Double?

    // Dividend
    var name: String?
    var currency: String?
    var shares: Double?
    var dividendPer10: Double?

    // Deposit
    var principal: Double?
    var rate: Double?

    // Stock
    var costBasis: Double?
}

// MARK: - Record

struct AchievementRecord: Codable, Identifiable {
    var id: UUID
    var achievementId: UUID
    var userId: UUID
    var value: Double
    var note: String?
    var date: String          // "YYYY-MM-DD"

    enum CodingKeys: String, CodingKey {
        case id, value, note, date
        case achievementId = "achievement_id"
        case userId = "user_id"
    }
}

// MARK: - Insert helpers

struct AchievementInsert: Encodable {
    var userId: UUID
    var category: String
    var name: String
    var unit: String
    var targetValue: Double
    var year: Int
    var template: AchievementTemplate
    var metadata: AchievementMetaWrapper?
    var parentId: UUID?

    enum CodingKeys: String, CodingKey {
        case category, name, unit, year, template, metadata
        case userId = "user_id"
        case targetValue = "target_value"
        case parentId = "parent_id"
    }
}

struct AchievementRecordInsert: Encodable {
    var achievementId: UUID
    var userId: UUID
    var value: Double
    var note: String?
    var date: String

    enum CodingKeys: String, CodingKey {
        case value, note, date
        case achievementId = "achievement_id"
        case userId = "user_id"
    }
}
