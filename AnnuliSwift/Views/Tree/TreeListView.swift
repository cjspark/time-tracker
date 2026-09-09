import SwiftUI

struct TreeListView: View {
    @ObservedObject var vm: TreeViewModel

    var body: some View {
        List {
            ForEach(vm.branches) { branch in
                BranchCardView(branch: branch, vm: vm)
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - BranchCard

struct BranchCardView: View {
    let branch: BranchData
    @ObservedObject var vm: TreeViewModel
    @State private var isExpanded = true

    private var isInvestment: Bool {
        branch.category.contains("投资") || branch.category.contains("理财")
    }

    var body: some View {
        Section {
            // Category header
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(branch.displayName)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(Color(.secondarySystemBackground))

            if isExpanded {
                // Hobby bars
                ForEach(branch.hobbies) { hobby in
                    HobbyBarRow(hobby: hobby, maxMinutes: branch.maxMinutes)
                }

                // Active achievements
                ForEach(branch.achievements.filter { !$0.isArchived }) { ach in
                    AchievementRow(achievement: ach) {
                        vm.selectedAchievement = ach
                        vm.showRecordSheet = true
                    }
                }

                // Archived achievements as milestones
                let archived = branch.achievements.filter(\.isArchived)
                if !archived.isEmpty {
                    HStack {
                        Image(systemName: "archivebox")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("里程碑 (\(archived.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Add achievement button
                Button {
                    vm.sheetCategory = branch.category
                    vm.showAchievementSheet = true
                } label: {
                    Label("添加成就", systemImage: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Hobby bar row

struct HobbyBarRow: View {
    let hobby: HobbyLeaf
    let maxMinutes: Int

    private var ratio: Double {
        maxMinutes > 0 ? Double(hobby.totalMinutes) / Double(maxMinutes) : 0
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: hobby.color).opacity(hobby.isInactive ? 0.3 : 1))
                .frame(width: 10, height: 10)
            Text(hobby.displayLabel)
                .font(.system(size: 13))
                .foregroundColor(hobby.isInactive ? .secondary : .primary)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemFill))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: hobby.color).opacity(hobby.isInactive ? 0.3 : 1))
                        .frame(width: geo.size.width * ratio, height: 6)
                }
            }
            .frame(width: 80, height: 6)
            Text(minuteLabel(hobby.totalMinutes))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func minuteLabel(_ mins: Int) -> String {
        let h = mins / 60
        return h > 0 ? "\(h)h" : "\(mins)m"
    }
}

// MARK: - Achievement row

struct AchievementRow: View {
    let achievement: Achievement
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "star.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                    Text("\(Int(achievement.currentValue))/\(Int(achievement.targetValue)) \(achievement.unit)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                ProgressView(value: achievement.progress)
                    .frame(width: 60)
                    .tint(.red)
            }
        }
        .buttonStyle(.plain)
    }
}
