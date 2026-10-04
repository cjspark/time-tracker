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

    // Add child investment
    @State private var showAddChild = false

    var isHabit: Bool { achievement.template == .habit }
    var isInvestment: Bool { [AchievementTemplate.dividend, .deposit, .stockProfit].contains(achievement.template) }
    var isInvestmentParent: Bool { !achievement.children.isEmpty }

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
                                Text("\(formattedValue(achievement.currentValue)) / \(formattedValue(achievement.targetValue)) \(achievement.unit)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if !isInvestmentParent {
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
                        }

                        ProgressView(value: achievement.progress)
                            .tint(achievement.isArchived ? .orange : .red)
                    }
                    .padding(.vertical, 4)
                }

                // Investment metadata card
                if let meta = achievement.metadata {
                    investmentMetaSection(meta: meta)
                }

                // Investment parent: children list + add child
                if isInvestmentParent || (achievement.children.isEmpty && isInvestmentCategory) {
                    childrenSection
                }

                // Add record (for non-investment-parent non-archived achievements)
                if !achievement.isArchived && !isInvestmentParent {
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
                if !isInvestmentParent {
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
                                Text(isHabit ? "✓" : "+\(formattedValue(record.value)) \(achievement.unit)")
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
            .sheet(isPresented: $showAddChild) {
                AchievementSheet(
                    category: achievement.category,
                    year: achievement.year,
                    parentId: achievement.id
                ) { insert in
                    Task { await vm.addAchievement(insert: insert) }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Investment metadata display

    @ViewBuilder
    private func investmentMetaSection(meta: AchievementMetaWrapper) -> some View {
        Section("投资详情") {
            switch achievement.template {
            case .dividend:
                if let shares = meta.shares {
                    metaRow("持股数量", value: "\(Int(shares)) 股")
                }
                if let d = meta.dividendPer10 {
                    metaRow("每10股股息", value: "\(meta.currency == "USD" ? "$" : "¥")\(String(format: "%.2f", d))")
                }
                if let currency = meta.currency {
                    metaRow("货币", value: currency)
                }
            case .deposit:
                if let principal = meta.principal {
                    metaRow("本金", value: "\(meta.currency == "USD" ? "$" : "¥")\(String(format: "%.2f", principal))")
                }
                if let rate = meta.rate {
                    metaRow("年利率", value: "\(String(format: "%.2f", rate))%")
                }
            case .stockProfit:
                if let cb = meta.costBasis, cb > 0 {
                    metaRow("成本基数", value: "\(meta.currency == "USD" ? "$" : "¥")\(String(format: "%.2f", cb))")
                }
            default:
                EmptyView()
            }
        }
    }

    private func metaRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium))
        }
    }

    // MARK: - Children section

    private var isInvestmentCategory: Bool {
        achievement.category.contains("投资") || achievement.category.contains("理财")
    }

    @ViewBuilder
    private var childrenSection: some View {
        Section {
            if achievement.children.isEmpty {
                Text("暂无子项").foregroundColor(.secondary)
            }
            ForEach(achievement.children) { child in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: templateIcon(child.template))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(child.name).font(.system(size: 13))
                        }
                        Text("\(child.unit) \(formattedValue(child.targetValue))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(formattedValue(child.targetValue) + " " + child.unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }

            Button {
                showAddChild = true
            } label: {
                Label("添加投资子项", systemImage: "plus.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
            }
        } header: {
            HStack {
                Text("投资子项")
                Spacer()
                if !achievement.children.isEmpty {
                    Text("合计 \(achievement.children.reduce(0) { $0 + $1.targetValue }, format: .number.precision(.fractionLength(0...2))) \(achievement.unit)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func templateIcon(_ t: AchievementTemplate) -> String {
        switch t {
        case .dividend:    return "chart.bar"
        case .deposit:     return "banknote"
        case .stockProfit: return "arrow.up.right.circle"
        default:           return "star.circle"
        }
    }

    private func formattedValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.2f", v)
    }

    // MARK: - Add record

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
