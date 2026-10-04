import SwiftUI

/// 复盘页 · 情绪维度：四颗情绪水晶球 + 点击展开情绪堆叠条。
/// 水位 = 该类效率时长（相对最忙的一类），水色 = 主导情绪（MoodBlend）。
struct CrystalBallSection: View {
    let stats: [Efficiency: EffStat]
    @State private var selected: Efficiency?

    private let order: [Efficiency] = [.productive, .daily, .creative, .enjoyable]

    private var maxMinutes: Int {
        max(1, order.map { stats[$0]?.minutes ?? 0 }.max() ?? 1)
    }
    private var hasData: Bool { order.contains { (stats[$0]?.minutes ?? 0) > 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("情绪 × 效率").font(.headline)

            HStack(alignment: .top, spacing: 12) {
                ForEach(order) { eff in ballColumn(eff) }
            }

            if !hasData {
                Text("给活动打上效率标签、记录时标个心情，球就会蓄满、显色。")
                    .font(.system(size: 12)).foregroundColor(EU.textFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let sel = selected, let stat = stats[sel], stat.minutes > 0 {
                detail(eff: sel, stat: stat)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(EU.bgCard)
        .cornerRadius(EU.radiusCard)
    }

    // MARK: 单颗球 + 标签

    private func ballColumn(_ eff: Efficiency) -> some View {
        let stat = stats[eff] ?? EffStat()
        let level = Double(stat.minutes) / Double(maxMinutes)
        return VStack(spacing: 7) {
            LiquidBall(level: level, weights: moodWeights(stat), selected: selected == eff)
                .frame(width: 62, height: 62)
                .contentShape(Circle())
                .onTapGesture {
                    guard stat.minutes > 0 else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selected = (selected == eff) ? nil : eff
                    }
                }
            Text(eff.label)
                .font(.system(size: 12, weight: selected == eff ? .semibold : .regular))
                .foregroundColor(selected == eff ? EU.textPrimary : EU.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func moodWeights(_ stat: EffStat) -> [Double] {
        Mood.allCases.map { Double(stat.byMood[$0] ?? 0) }
    }

    // MARK: 近景明细

    private func detail(eff: Efficiency, stat: EffStat) -> some View {
        let total = max(1, stat.minutes)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(eff.label).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(hoursLabel(stat.minutes)).font(.system(size: 13)).foregroundColor(EU.textMuted)
            }
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(Mood.allCases) { m in
                        let w = stat.byMood[m] ?? 0
                        if w > 0 {
                            Rectangle().fill(m.color)
                                .frame(width: geo.size.width * CGFloat(w) / CGFloat(total))
                        }
                    }
                    if stat.noMood > 0 {
                        Rectangle().fill(EU.untracked)
                            .frame(width: geo.size.width * CGFloat(stat.noMood) / CGFloat(total))
                    }
                }
            }
            .frame(height: 22)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Mood.allCases) { m in
                        let w = stat.byMood[m] ?? 0
                        if w > 0 { legendItem(color: m.color, text: "\(m.label) \(hoursLabel(w))") }
                    }
                    if stat.noMood > 0 { legendItem(color: EU.untracked, text: "没标心情 \(hoursLabel(stat.noMood))") }
                }
            }

            Text(suggestion(stat))
                .font(.system(size: 13)).foregroundColor(EU.textPrimary)
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(EU.bgCardAlt).cornerRadius(10)
        }
        .padding(.top, 4)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(text).font(.system(size: 12)).foregroundColor(EU.textMuted)
        }
    }

    private func hoursLabel(_ mins: Int) -> String {
        let h = mins / 60, m = mins % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h\(m)m"
    }

    private func suggestion(_ stat: EffStat) -> String {
        let total = Double(max(1, stat.minutes))
        let stress = Double(stat.byMood[.stress] ?? 0) / total
        let joy = Double(stat.byMood[.joyful] ?? 0) / total
        if stress >= 0.3 { return "这类事让你压力偏多，试试给相关目标调高奖励份额？" }
        if joy >= 0.4 { return "这类时间常带来愉悦，可以安心多留一点给自己。" }
        return "情绪挺平稳的，保持这个节奏就好。"
    }
}

// MARK: - 单颗液体球

struct LiquidBall: View {
    let level: Double        // 0...1
    let weights: [Double]    // 情绪权重（顺序同 Mood.allCases）
    let selected: Bool

    var body: some View {
        let base = MoodBlend.blend(weights: weights)
        let top  = MoodBlend.variant(base, dL:  0.10 * EU.liquidDepth, mulC: 1 - 0.45 * EU.liquidDepth)
        let bot  = MoodBlend.variant(base, dL: -0.18 * EU.liquidDepth, mulC: 1 + 0.80 * EU.liquidDepth)
        let clamped = max(0, min(1, level))

        return GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Circle().fill(EU.bgCardAlt)
                Rectangle()
                    .fill(LinearGradient(
                        colors: [col(top).opacity(EU.liquidAlpha * 0.9),
                                 col(bot).opacity(min(1, EU.liquidAlpha + 0.08))],
                        startPoint: .top, endPoint: .bottom))
                    .frame(height: geo.size.height * CGFloat(clamped))
            }
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.2))
            .overlay(alignment: .topLeading) {
                Ellipse().fill(Color.white.opacity(0.55))
                    .frame(width: geo.size.width * 0.3, height: geo.size.height * 0.2)
                    .blur(radius: 2)
                    .offset(x: geo.size.width * 0.18, y: geo.size.height * 0.14)
            }
            .overlay(Circle().stroke(selected ? EU.accent : Color.clear, lineWidth: 2))
            .shadow(color: Color(hex: "#5A4632").opacity(0.18), radius: 6, y: 4)
        }
    }

    private func col(_ rgb: (Double, Double, Double)) -> Color {
        Color(red: rgb.0, green: rgb.1, blue: rgb.2)
    }
}
