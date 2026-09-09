import SwiftUI

struct RecordSheet: View {
    let achievement: Achievement
    @ObservedObject var vm: TreeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var valueText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var showDeleteConfirm = false

    // Edit target
    @State private var isEditingTarget = false
    @State private var targetDraft = ""

    var isHabit: Bool { achievement.template == .habit }

    var body: some View {
        NavigationView {
            List {
                // Header: name + progress + edit target
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text(achievement.name).font(.headline)
                            Spacer()
                            if achievement.isArchived {
                                Label("里程碑", systemImage: "trophy.circle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        if isEditingTarget {
                            HStack {
                                Text("目标值").font(.subheadline).foregroundColor(.secondary)
                                TextField("目标", text: $targetDraft)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Text(achievement.unit).font(.subheadline).foregroundColor(.secondary)
                                Spacer()
                                Button("确定") {
                                    if let v = Double(targetDraft), v > 0 {
                                        Task { await vm.updateAchievementTarget(id: achievement.id, value: v) }
                                    }
                                    isEditingTarget = false
                                }
                                .font(.system(size: 13, weight: .medium))
                                Button("取消") { isEditingTarget = false }
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack {
                                Text("\(Int(achievement.currentValue)) / \(Int(achievement.targetValue)) \(achievement.unit)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button {
                                    targetDraft = String(Int(achievement.targetValue))
                                    isEditingTarget = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        ProgressView(value: achievement.progress)
                            .tint(achievement.isArchived ? .orange : .red)
                    }
                    .padding(.vertical, 4)
                }

                // Add record (hidden if archived)
                if !achievement.isArchived {
                    Section("添加记录") {
                        if !isHabit {
                            TextField("数值", text: $valueText)
                                .keyboardType(.decimalPad)
                        }
                        DatePicker("日期", selection: $date, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                        TextField("备注（可选）", text: $note)

                        Button(isHabit ? "打卡 +1" : "添加") {
                            addRecord()
                        }
                        .disabled(!isHabit && valueText.isEmpty)
                    }
                }

                // Record history
                Section("记录历史") {
                    if achievement.records.isEmpty {
                        Text("暂无记录").foregroundColor(.secondary)
                    }
                    ForEach(achievement.records.sorted { $0.date > $1.date }) { record in
                        HStack {
                            Text(record.date)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(isHabit ? "✓" : "+\(Int(record.value)) \(achievement.unit)")
                                .font(.system(size: 13))
                            if let n = record.note, !n.isEmpty {
                                Text(n).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .swipeActions {
                            Button("删除", role: .destructive) {
                                Task { await vm.deleteRecord(id: record.id, from: achievement.id) }
                            }
                        }
                    }
                }

                // Actions
                Section {
                    if achievement.isArchived {
                        Button("取消归档") {
                            Task { await vm.unarchiveAchievement(id: achievement.id); dismiss() }
                        }
                        .foregroundColor(.blue)
                    } else if achievement.progress >= 1 {
                        Button("归档为里程碑") {
                            Task { await vm.archiveAchievement(id: achievement.id); dismiss() }
                        }
                        .foregroundColor(.orange)
                    }
                    Button("删除成就", role: .destructive) { showDeleteConfirm = true }
                }
            }
            .navigationTitle("成就详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("关闭") { dismiss() } }
            }
            .confirmationDialog("确定删除成就？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    Task { await vm.deleteAchievement(id: achievement.id); dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func addRecord() {
        guard let userId = AuthService.currentUserId else { return }
        let value: Double = isHabit ? 1 : (Double(valueText) ?? 0)
        let insert = AchievementRecordInsert(
            achievementId: achievement.id, userId: userId,
            value: value, note: note.isEmpty ? nil : note,
            date: date.localDateString()
        )
        Task { await vm.addRecord(insert, to: achievement.id) }
        valueText = ""; note = ""
    }
}
