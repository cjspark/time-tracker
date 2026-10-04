import SwiftUI

// Forest scene: each hobby represented by a tree image at a deterministic position
struct TreeBoardView: View {
    @ObservedObject var vm: TreeViewModel
    private let sceneWidth: CGFloat  = 360
    private let sceneHeight: CGFloat = 300
    @State private var selected: HobbyLeaf?

    var body: some View {
        ScrollView {
            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: [Color(hex: "#87CEEB"), Color(hex: "#E0F4FF")],
                    startPoint: .top, endPoint: .bottom
                )

                // Ground strip
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(hex: "#7CB87C"))
                        .frame(height: 40)
                }

                // Trees
                ForEach(allHobbies.indices, id: \.self) { idx in
                    let hobby = allHobbies[idx]
                    let pos   = treePosition(index: idx, total: allHobbies.count)
                    let stage = TreeStageCalculator.stage(totalMinutes: hobby.totalMinutes)

                    Image(TreeStageCalculator.treeImageName(stage: stage))
                        .resizable()
                        .scaledToFit()
                        .frame(width: treeSize(stage: stage))
                        .saturation(hobby.isInactive ? 0 : 1)
                        .position(pos)
                        .onTapGesture { selected = hobby }
                }
            }
            .frame(width: sceneWidth, height: sceneHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            // Detail card when tapped
            if let hobby = selected {
                HobbyDetailCard(hobby: hobby)
                    .padding(.horizontal)
            }
        }
        .sheet(item: $selected) { hobby in
            HobbyDetailSheet(hobby: hobby)
        }
    }

    private var allHobbies: [HobbyLeaf] {
        vm.branches.flatMap(\.hobbies)
    }

    // Deterministic pseudo-random position based on index
    private func treePosition(index: Int, total: Int) -> CGPoint {
        let bandWidth = sceneWidth / max(CGFloat(total), 1)
        let x = bandWidth * CGFloat(index) + bandWidth * 0.5
        let yBase = sceneHeight - 50.0
        let yOffset = seedRand(seed: index, range: 0...30)
        return CGPoint(x: x, y: yBase - yOffset)
    }

    private func treeSize(stage: Int) -> CGFloat {
        [30, 42, 56, 70, 88][stage - 1]
    }

    private func seedRand(seed: Int, range: ClosedRange<CGFloat>) -> CGFloat {
        let val = (Double(seed * 2654435761) / Double(UInt32.max))
        return range.lowerBound + CGFloat(val) * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Detail card

struct HobbyDetailCard: View {
    let hobby: HobbyLeaf

    var body: some View {
        let stage = TreeStageCalculator.stage(totalMinutes: hobby.totalMinutes)
        let nextThreshold = TreeStageCalculator.stageNextThreshold(stage: stage)
        let progress = min(Double(hobby.totalMinutes) / 60.0 / nextThreshold, 1.0)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(Color(hex: hobby.color)).frame(width: 12, height: 12)
                Text(hobby.displayLabel).font(.headline)
                Spacer()
                Text("阶段 \(stage)").font(.caption).foregroundColor(.secondary)
            }
            ProgressView(value: progress)
                .tint(Color(hex: hobby.color))
            Text(TreeStageCalculator.stageProgressDescription(stage: stage, totalMinutes: hobby.totalMinutes))
                .font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct HobbyDetailSheet: View {
    let hobby: HobbyLeaf
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                HobbyDetailCard(hobby: hobby)
                Spacer()
            }
            .padding()
            .navigationTitle(hobby.displayLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("关闭") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
    }
}
