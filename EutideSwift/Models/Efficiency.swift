import SwiftUI

/// 四类效率 —— 按"驱动力"定义，不按活动名字。
/// 一个活动最多打 2 个，各算 100%（见计量模型）。rawValue 存库。
enum Efficiency: String, CaseIterable, Codable, Identifiable {
    case productive  // 生产：为了完成
    case creative    // 创造：为了成长
    case enjoyable   // 娱乐：为了放松
    case daily       // 日常：为了生活

    var id: String { rawValue }

    var label: String {
        switch self {
        case .productive: return "生产"
        case .creative:   return "创造"
        case .enjoyable:  return "娱乐"
        case .daily:      return "日常"
        }
    }

    /// 一句驱动力定义
    var driver: String {
        switch self {
        case .productive: return "为了完成"
        case .creative:   return "为了成长"
        case .enjoyable:  return "为了放松"
        case .daily:      return "为了生活"
        }
    }

    /// 典型例子（UI 里的小字说明）
    var detail: String {
        switch self {
        case .productive: return "工作、任务、交付"
        case .creative:   return "创作、搭建、学本领"
        case .enjoyable:  return "玩、看剧、消遣"
        case .daily:      return "吃饭、通勤、家务"
        }
    }

    var color: Color {
        switch self {
        case .productive: return EU.effProductive
        case .creative:   return EU.effCreative
        case .enjoyable:  return EU.effEnjoyable
        case .daily:      return EU.effDaily
        }
    }
}
