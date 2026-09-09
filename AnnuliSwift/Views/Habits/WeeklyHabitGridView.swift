import SwiftUI

struct WeeklyHabitGridView: View {
    @ObservedObject var vm: TreeViewModel
    @State private var weekOffset = 0
    @State private var showAddHabit = false
    @EnvironmentObject private var prefs: PrefsViewModel

    private var weekDates: [Date] {
        let anchor = Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        return WeekCalculator.weekDates(containing: anchor)
    }

    private var habits: [Achievement] {
        vm.branches.flatMap(\.achievements).filter { $0.template == .habit && !$0.isArchived }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Week navigation
                HStack {
                    Button { weekOffset -= 1 } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(WeekCalculator.weekLabel(dates: weekDates))
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Button { if weekOffset < 0 { weekOffset += 1 } } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(weekOffset == 0 ? .secondary : .primary)
                    }
                    .disabled(weekOffset == 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider()

                if habits.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("还没有习惯").foregroundColor(.secondary)
                        Button("添加习惯") { showAddHabit = true }
                        Spacer()
                    }
                } else {
                    List {
                        // Day header row
                        HStack {
                            Text("").frame(width: 100)
                            ForEach(weekDates, id: \.self) { day in
                                VStack(spacing: 2) {
                                    Text(day.weekdayShort)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    Text(day.dayNumber)
                                        .font(.system(size: 12, weight: day.isToday ? .bold : .regular))
                                        .foregroundColor(day.isToday ? .blue : .primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .listRowBackground(Color(.secondarySystemBackground))

                        ForEach(habits) { habit in
                            HabitGridRow(habit: habit, weekDates: weekDates, vm: vm)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("习惯打卡")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddHabit = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitSheet { insert in
                    Task { await vm.addAchievement(insert: insert) }
                }
                .environmentObject(prefs)
            }
        }
    }
}

// MARK: - Habit row with progress + edit

struct HabitGridRow: View {
    let habit: Achievement
    let weekDates: [Date]
    @ObservedObject var vm: TreeViewModel
    @State private var showEdit = false

    private var weekCount: Int {
        habit.records.filter { r in weekDates.contains { $0.localDateString() == r.date } }.count
    }

    private var weekTarget: Int { Int(habit.targetValue) }

    private var progressFraction: Double {
        weekTarget > 0 ? Double(weekCount) / Double(weekTarget) : 0
    }

    var body: some View {
        HStack(spacing: 0) {
            // Name + progress
            Button { showEdit = true } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        // Mini progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(.systemFill)).frame(height: 4)
                                Capsule()
                                    .fill(Color.green)
                                    .frame(width: geo.size.width * min(progressFraction, 1), height: 4)
                            }
                        }
                        .frame(height: 4)
                        Text("\(weekCount)/\(weekTarget)")
                            .font(.system(size: 10))
                            .foregroundColor(weekCount >= weekTarget ? .green : .secondary)
                            .fixedSize()
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: 100, alignment: .leading)

            ForEach(weekDates, id: \.self) { day in
                let dateStr = day.localDateString()
                let checkedIn = habit.records.contains { $0.date == dateStr }
                let isFuture = day > Date()

                Button {
                    if !isFuture {
                        Task {
                            if checkedIn {
                                if let rec = habit.records.first(where: { $0.date == dateStr }) {
                                    await vm.deleteRecord(id: rec.id, from: habit.id)
                                }
                            } else {
                                guard let userId = AuthService.currentUserId else { return }
                                let insert = AchievementRecordInsert(
                                    achievementId: habit.id, userId: userId,
                                    value: 1, note: nil, date: dateStr
                                )
                                await vm.addRecord(insert, to: habit.id)
                            }
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(checkedIn ? Color.green : Color(.systemFill))
                            .frame(width: 28, height: 28)
                        if day.isToday {
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 28, height: 28)
                        }
                        if checkedIn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .opacity(isFuture ? 0.3 : 1)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showEdit) {
            HabitEditSheet(habit: habit, vm: vm)
        }
    }
}

// MARK: - Habit edit sheet

struct HabitEditSheet: View {
    let habit: Achievement
    @ObservedObject var vm: TreeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var nameDraft: String
    @State private var targetDraft: String
    @State private var showDeleteConfirm = false

    init(habit: Achievement, vm: TreeViewModel) {
        self.habit = habit; self.vm = vm
        _nameDraft  = State(initialValue: habit.name)
        _targetDraft = State(initialValue: String(Int(habit.targetValue)))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("习惯名称") {
                    TextField("名称", text: $nameDraft)
                }

                Section("每周目标（次/天）") {
                    TextField("目标次数", text: $targetDraft)
                        .keyboardType(.numberPad)
                    // Presets
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach([1, 2, 3, 4, 5, 6, 7], id: \.self) { v in
                            Button("\(v)") {
                                targetDraft = "\(v)"
                            }
                            .font(.system(size: 13))
                            .foregroundColor(targetDraft == "\(v)" ? .white : .blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(targetDraft == "\(v)" ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button("归档习惯", role: .none) {
                        Task { await vm.archiveAchievement(id: habit.id); dismiss() }
                    }
                    .foregroundColor(.orange)

                    Button("删除习惯", role: .destructive) {
                        showDeleteConfirm = true
                    }
                }
            }
            .navigationTitle("编辑习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            if nameDraft != habit.name {
                                await vm.renameAchievement(id: habit.id, name: nameDraft)
                            }
                            if let t = Double(targetDraft), t != habit.targetValue {
                                await vm.updateAchievementTarget(id: habit.id, value: t)
                            }
                        }
                        dismiss()
                    }
                    .disabled(nameDraft.isEmpty)
                }
            }
            .confirmationDialog("确定删除这个习惯？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    Task { await vm.deleteAchievement(id: habit.id); dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Add habit sheet (improved)

struct AddHabitSheet: View {
    let onAdd: (AchievementInsert) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var prefs: PrefsViewModel

    @State private var name = ""
    @State private var selectedCategory = ""
    @State private var targetText = "7"
    @State private var unit = "天"

    private let unitPresets = ["天", "次", "km", "分钟"]
    private let targetPresets = [7, 30, 90, 180, 330, 365]

    var body: some View {
        NavigationView {
            Form {
                Section("习惯名称") {
                    TextField("例如：每日运动、阅读", text: $name)
                }

                Section("所属分类") {
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(prefs.orderedCategories, id: \.self) { cat in
                            Text(prefs.displayName(for: cat)).tag(cat)
                        }
                    }
                }

                Section("目标单位") {
                    Picker("单位", selection: $unit) {
                        ForEach(unitPresets, id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        TextField("目标值", text: $targetText)
                            .keyboardType(.numberPad)
                        Text(unit).foregroundColor(.secondary)
                    }
                    // Quick presets
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(targetPresets, id: \.self) { v in
                            Button("\(v)\(unit)") {
                                targetText = "\(v)"
                            }
                            .font(.system(size: 12))
                            .foregroundColor(targetText == "\(v)" ? .white : .blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(targetText == "\(v)" ? Color.blue : Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("目标值")
                }
            }
            .navigationTitle("添加习惯")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedCategory = prefs.orderedCategories.first ?? ""
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let target = Double(targetText),
                              let userId = AuthService.currentUserId else { return }
                        let cat = selectedCategory.isEmpty ? (prefs.orderedCategories.first ?? "健康") : selectedCategory
                        let insert = AchievementInsert(
                            userId: userId,
                            category: cat,
                            name: name, unit: unit, targetValue: target,
                            year: Calendar.current.component(.year, from: Date()),
                            template: .habit, metadata: nil, parentId: nil
                        )
                        onAdd(insert); dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}
