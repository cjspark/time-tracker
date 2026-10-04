import SwiftUI

/// Eutide 设计 tokens —— 颜色 / 圆角 / 间距 / 参数的唯一真理源。
/// 对应 design-system/tokens.css。视图里一律引用 EU.xxx，不写死 hex。
enum EU {

    // MARK: 中性色
    static let bgPage      = Color(hex: "#F3F1EA")
    static let bgCard      = Color(hex: "#FBFAF6")
    static let bgCardAlt   = Color(hex: "#EDEAE0")
    static let borderSoft  = Color(hex: "#E0DCD0")
    static let textPrimary = Color(hex: "#3D3A32")
    static let textMuted   = Color(hex: "#7A756A")
    static let textFaint   = Color(hex: "#ABA599")

    // MARK: 主强调
    static let accent      = Color(hex: "#7A9B6E")
    static let accentDeep  = Color(hex: "#6A8A5E")

    // MARK: 四类效率（按驱动力）
    static let effProductive = Color(hex: "#8A7BA8")  // 生产：为了完成
    static let effCreative   = Color(hex: "#C08A5E")  // 创造：为了成长
    static let effEnjoyable  = Color(hex: "#7A9B6E")  // 娱乐：为了放松
    static let effDaily      = Color(hex: "#7D93A8")  // 日常：为了生活
    static let untracked     = Color(hex: "#D2CEC4")  // 未追踪 / 没标心情

    // MARK: 情绪五色
    static let moodJoyful  = Color(hex: "#A8BF94")
    static let moodCalm    = Color(hex: "#94ADBF")
    static let moodNeutral = Color(hex: "#BFB894")
    static let moodLow     = Color(hex: "#B09BA8")
    static let moodStress  = Color(hex: "#BF9A8A")

    // MARK: 奖励四级（莫兰迪）
    static let rewardSmall  = Color(hex: "#7AA88C")
    static let rewardMedium = Color(hex: "#7B9CC4")
    static let rewardLarge  = Color(hex: "#A88BB6")
    static let rewardXLarge = Color(hex: "#D2A85A")

    // MARK: 签名
    static let terracotta  = Color(hex: "#BC6A5A")

    // MARK: 圆角
    static let radiusCard: CGFloat = 16
    static let radiusCtl:  CGFloat = 12
    static let radiusSm:   CGFloat = 8

    // MARK: 间距
    static let padPage: CGFloat = 16
    static let padCard: CGFloat = 16
    static let gapCard: CGFloat = 12

    // MARK: 动效
    static let durStd:       Double = 0.3
    static let durPage:      Double = 0.45
    static let durCelebrate: Double = 0.7

    // MARK: MoodBlend 参数
    static let moodBlendChroma:    Double = 3.2
    static let moodBlendDominance: Double = 3.5

    // MARK: 液体渲染参数
    static let liquidDepth: Double = 0.55
    static let liquidAlpha: Double = 0.82
    static let liquidWave:  Double = 0.5
}
