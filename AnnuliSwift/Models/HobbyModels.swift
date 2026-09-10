import Foundation

// MARK: - HobbyItem (resolved, display-ready)

struct HobbyItem: Identifiable, Equatable {
    var id: String { label }
    var label: String
    var displayLabel: String
    var color: String         // hex

    var displayColor: String { color }
}

// MARK: - HobbyStats (for Hobbies view)

struct HobbyStats: Identifiable {
    var id: String { label }
    var label: String
    var displayLabel: String
    var color: String
    var historicalMinutes: Int
    var calendarMinutes: Int
    var category: String?

    var totalMinutes: Int { historicalMinutes + calendarMinutes }
}

// MARK: - BranchData (for Tree view)

struct BranchData: Identifiable {
    var id: String { category }
    var category: String
    var displayName: String
    var hobbies: [HobbyLeaf]
    var achievements: [Achievement]
    var maxMinutes: Int
}

struct HobbyLeaf: Identifiable {
    var id: String { label }
    var label: String
    var displayLabel: String
    var color: String
    var totalMinutes: Int
    var isInactive: Bool
}

// MARK: - HobbyItemMeta (hobby + domain assignment + global priority)

struct HobbyItemMeta: Identifiable {
    var id: String { hobby.label }
    var hobby: HobbyItem
    var domainId: UUID?
    var priority: Int   // lower index = higher priority; Int.max = unassigned
}


struct HobbyPreference: Codable {
    var userId: UUID
    var hobby: String
    var category: String

    enum CodingKeys: String, CodingKey {
        case hobby, category
        case userId = "user_id"
    }
}

struct HobbyHistory: Codable {
    var userId: UUID
    var hobby: String
    var historicalMinutes: Int

    enum CodingKeys: String, CodingKey {
        case hobby
        case userId = "user_id"
        case historicalMinutes = "historical_minutes"
    }
}

// MARK: - TimeCategory

enum TimeCategory: String, CaseIterable, Codable {
    case productive, consuming, enjoyable, unconscious

    var displayName: String {
        switch self {
        case .productive:  return "生产性"
        case .consuming:   return "消耗性"
        case .enjoyable:   return "享受性"
        case .unconscious: return "无意识"
        }
    }

    var hex: String {
        switch self {
        case .productive:  return "#8B5CF6"
        case .consuming:   return "#F97316"
        case .enjoyable:   return "#10B981"
        case .unconscious: return "#3B82F6"
        }
    }
}
