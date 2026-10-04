import Foundation

enum RewardTier: String, CaseIterable, Codable {
    case small  = "小"
    case medium = "中"
    case large  = "大"
    case xlarge = "特大"

    var displayName: String {
        switch self {
        case .small:  return "小确幸"
        case .medium: return "好好犒劳"
        case .large:  return "认真奖励"
        case .xlarge: return "里程碑"
        }
    }

    var emoji: String {
        switch self {
        case .small:  return "🌱"
        case .medium: return "🌟"
        case .large:  return "🎯"
        case .xlarge: return "🏆"
        }
    }

    var colorHex: String {
        switch self {
        case .small:  return "#34C759"
        case .medium: return "#007AFF"
        case .large:  return "#AF52DE"
        case .xlarge: return "#FF9F0A"
        }
    }
}
