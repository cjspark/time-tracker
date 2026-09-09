import SwiftUI

// Organic tree-of-life canvas with branch zones
struct TreeCanvasView: View {
    @ObservedObject var vm: TreeViewModel
    @State private var selectedAchievement: Achievement?

    // 6 branch zone positions (relative to 360x560 viewBox)
    private let zones: [(x: CGFloat, y: CGFloat)] = [
        (80, 160), (280, 180),
        (60, 260), (300, 250),
        (120, 340), (240, 330),
    ]

    var body: some View {
        ScrollView {
            Canvas { ctx, size in
                let scaleX = size.width / 360
                let scaleY = size.height / 560
                drawTrunk(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
            }
            .frame(height: 560)
            .overlay(orbsOverlay)
            .padding(.horizontal)
        }
    }

    // Draw tree trunk as a bezier path
    private func drawTrunk(ctx: GraphicsContext, scaleX: CGFloat, scaleY: CGFloat) {
        var path = Path()
        let trunkPoints: [(CGFloat, CGFloat)] = [
            (180, 540), (175, 480), (170, 420), (172, 380),
            (168, 340), (165, 300), (170, 260), (175, 220),
            (178, 180), (180, 140), (182, 100), (180, 60)
        ]
        path.move(to: CGPoint(x: trunkPoints[0].0 * scaleX, y: trunkPoints[0].1 * scaleY))
        for pt in trunkPoints.dropFirst() {
            path.addLine(to: CGPoint(x: pt.0 * scaleX, y: pt.1 * scaleY))
        }
        ctx.stroke(path, with: .color(Color(hex: "#8B6914")), style: StrokeStyle(lineWidth: 8 * scaleX, lineCap: .round))
    }

    // Overlay orbs at zone positions
    @ViewBuilder
    private var orbsOverlay: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / 360
            let scaleY = geo.size.height / 560
            ZStack {
                ForEach(vm.branches.indices, id: \.self) { idx in
                    if idx < zones.count {
                        let zone = zones[idx]
                        let branch = vm.branches[idx]
                        BranchZoneView(
                            branch: branch,
                            position: CGPoint(x: zone.x * scaleX, y: zone.y * scaleY),
                            onAchievementTap: { vm.selectedAchievement = $0; vm.showRecordSheet = true },
                            onAddTap: { vm.sheetCategory = branch.category; vm.showAchievementSheet = true }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Branch zone

struct BranchZoneView: View {
    let branch: BranchData
    let position: CGPoint
    let onAchievementTap: (Achievement) -> Void
    let onAddTap: () -> Void

    private let maxMinutes = 3600 // 60h for max orb size
    private let orbMinSize: CGFloat = 16
    private let orbMaxSize: CGFloat = 36

    var body: some View {
        ZStack {
            // Hobby orbs (green)
            ForEach(branch.hobbies.prefix(3).indices, id: \.self) { i in
                let hobby = branch.hobbies[i]
                let ratio = min(Double(hobby.totalMinutes) / Double(maxMinutes), 1.0)
                let size = orbMinSize + (orbMaxSize - orbMinSize) * CGFloat(ratio)
                let offset = orbOffset(index: i, side: .left)
                Circle()
                    .fill(Color(hex: hobby.color).opacity(0.7))
                    .frame(width: size, height: size)
                    .offset(x: offset.x, y: offset.y)
            }

            // Achievement orbs (red/yellow progress)
            ForEach(branch.achievements.prefix(3).filter { !$0.isArchived }.indices, id: \.self) { i in
                let ach = branch.achievements.filter { !$0.isArchived }[i]
                let size: CGFloat = orbMinSize + (orbMaxSize - orbMinSize) * CGFloat(ach.progress)
                let offset = orbOffset(index: i, side: .right)
                ZStack {
                    Circle().fill(Color.red.opacity(0.15)).frame(width: size, height: size)
                    Circle()
                        .trim(from: 0, to: ach.progress)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: size - 4, height: size - 4)
                }
                .offset(x: offset.x, y: offset.y)
                .onTapGesture { onAchievementTap(ach) }
            }

            // + button
            Button { onAddTap() } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.7))
            }
            .offset(x: 28, y: 0)
        }
        .position(position)
    }

    enum Side { case left, right }

    private func orbOffset(index: Int, side: Side) -> CGPoint {
        let offsets: [CGPoint] = [.init(x: 0, y: -20), .init(x: -15, y: 5), .init(x: 15, y: 5)]
        let base = offsets[min(index, 2)]
        let sign: CGFloat = side == .left ? -1 : 1
        return CGPoint(x: base.x * sign - 20 * sign, y: base.y)
    }
}
