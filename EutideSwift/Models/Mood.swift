import SwiftUI

/// 五档情绪 —— 记录时打标签。顺序与 MoodBlend.moodHex / 权重数组一致。
/// rawValue 存入数据库（time_entries.mood 文本）。
enum Mood: String, CaseIterable, Codable, Identifiable {
    case joyful   // 愉悦
    case calm     // 平静
    case neutral  // 还行
    case low      // 低落
    case stress   // 压力

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .joyful:  return "😊"
        case .calm:    return "😌"
        case .neutral: return "😐"
        case .low:     return "😔"
        case .stress:  return "😤"
        }
    }

    var label: String {
        switch self {
        case .joyful:  return "愉悦"
        case .calm:    return "平静"
        case .neutral: return "还行"
        case .low:     return "低落"
        case .stress:  return "压力"
        }
    }

    /// 情绪色（见 EU tokens）。低落 / 压力非警告色。
    var color: Color {
        switch self {
        case .joyful:  return EU.moodJoyful
        case .calm:    return EU.moodCalm
        case .neutral: return EU.moodNeutral
        case .low:     return EU.moodLow
        case .stress:  return EU.moodStress
        }
    }

    /// 在 MoodBlend 权重数组里的下标（0...4）。
    var blendIndex: Int { Mood.allCases.firstIndex(of: self) ?? 0 }
}
