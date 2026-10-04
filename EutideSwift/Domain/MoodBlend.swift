import SwiftUI

/// Eutide 的 MoodBlend 色彩引擎 —— 在 OKLab 感知色彩空间混合情绪分布，避免"泥色"。
/// 对应 design-docs/liquid-lab.html 的 blend()。
/// 情绪顺序固定：愉悦 / 平静 / 还行 / 低落 / 压力。
enum MoodBlend {

    /// 情绪基色（顺序与 Mood 枚举一致）
    static let moodHex = ["#A8BF94", "#94ADBF", "#BFB894", "#B09BA8", "#BF9A8A"]

    /// 把情绪时间分布（权重，顺序同 moodHex）混成一个 Color。
    static func color(weights: [Double],
                      chroma: Double = EU.moodBlendChroma,
                      dominance: Double = EU.moodBlendDominance) -> Color {
        let (r, g, b) = blend(weights: weights, chroma: chroma, dominance: dominance)
        return Color(red: r, green: g, blue: b)
    }

    /// 核心混合，返回 sRGB 0...1。
    static func blend(weights: [Double],
                      chroma: Double = EU.moodBlendChroma,
                      dominance: Double = EU.moodBlendDominance) -> (Double, Double, Double) {
        let labs = moodHex.map { rgbToOklab(hexToRGB($0)) }
        let wp = weights.map { pow(max(0, $0), dominance) }
        let total = wp.reduce(0, +)
        guard total > 0 else { return (0.835, 0.816, 0.769) }  // 未追踪中性
        var l = 0.0, a = 0.0, b = 0.0
        for (i, lab) in labs.enumerated() where i < wp.count {
            let k = wp[i] / total
            l += k * lab.0; a += k * lab.1; b += k * lab.2
        }
        return oklabToRGB((l, a * chroma, b * chroma))
    }

    /// 深度变体（液体渐变用）：平移明度、缩放彩度。
    static func variant(_ c: (Double, Double, Double), dL: Double, mulC: Double) -> (Double, Double, Double) {
        let lab = rgbToOklab(c)
        let chroma = (lab.1 * lab.1 + lab.2 * lab.2).squareRoot()
        let hue = atan2(lab.2, lab.1)
        let l = min(1, max(0, lab.0 + dL))
        let c2 = max(0, chroma * mulC)
        return oklabToRGB((l, c2 * cos(hue), c2 * sin(hue)))
    }

    // MARK: - 转换

    static func hexToRGB(_ hex: String) -> (Double, Double, Double) {
        let h = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        return (Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255)
    }

    static func rgbToOklab(_ c: (Double, Double, Double)) -> (Double, Double, Double) {
        let r = lin(c.0), g = lin(c.1), b = lin(c.2)
        let l = 0.4122214708*r + 0.5363325363*g + 0.0514459929*b
        let m = 0.2119034982*r + 0.6806995451*g + 0.1073969566*b
        let s = 0.0883024619*r + 0.2817188376*g + 0.6299787005*b
        let l_ = cbrt(l), m_ = cbrt(m), s_ = cbrt(s)
        return (0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
                1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
                0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_)
    }

    static func oklabToRGB(_ lab: (Double, Double, Double)) -> (Double, Double, Double) {
        let (bigL, a, b) = lab
        let l_ = bigL + 0.3963377774*a + 0.2158037573*b
        let m_ = bigL - 0.1055613458*a - 0.0638541728*b
        let s_ = bigL - 0.0894841775*a - 1.2914855480*b
        let l = l_*l_*l_, m = m_*m_*m_, s = s_*s_*s_
        return (unlin( 4.0767416621*l - 3.3077115913*m + 0.2309699292*s),
                unlin(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s),
                unlin(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s))
    }

    private static func lin(_ x: Double) -> Double {
        x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
    }
    private static func unlin(_ x: Double) -> Double {
        let v = x <= 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0/2.4) - 0.055
        return min(1, max(0, v))
    }
}
