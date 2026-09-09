import SwiftUI

struct RecordSheet: View {
    let achievement: Achievement
    @ObservedObject var vm: TreeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var valueText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var showDeleteConfirm = false

    var isHabit: Bool { achievement.template == .habit }

    var body: some View {
        NavigationView {
            List {
                // Header: name + progress
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(achievement.name)
                            .font(.headline)
                        Text("\(Int(achievement.currentValue)) / \(Int(achievement.targetValue)) \(achievement.unit)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ProgressView(value: achievement.progress)
                            .tint(.red)
                    }
                    .padding(.vertical, 4)
                }

                // Add record
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

                // Danger zone
                Section {
                    if achievement.progress >= 1 && !achievement.isArchived {
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
