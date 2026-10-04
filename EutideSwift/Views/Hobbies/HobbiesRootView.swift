import SwiftUI

struct HobbiesRootView: View {
    @StateObject private var vm       = HobbiesViewModel()
    @StateObject private var treeVM   = TreeViewModel()
    @EnvironmentObject private var prefs: PrefsViewModel
    @EnvironmentObject private var timer: TimerViewModel

    // Sheet state
    @State private var editingHobby: HobbyStats?
    @State private var showAddHobby    = false
    @State private var showAddCategory = false
    @State private var showCatOrder    = false
    @State private var showAddHabit    = false

    // Habit section
    @State private var showHabits       = true
    @State private var habitWeekOffset  = 0

    // Category rename alert
    @State private var renamingCat: String?
    @State private var renameDraft = ""

    // Undo-hide toast
    @State private var undoHobbyLabel: String?
    @State private var undoTask: Task<Void, Never>?

    // Computed
    private var habitWeekDates: [Date] {
        let anchor = Calendar.current.date(byAdding: .weekOfYear, value: habitWeekOffset, to: Date()) ?? Date()
        return WeekCalculator.weekDates(containing: anchor)
    }

    private var habits: [Achievement] {
        treeVM.branches.flatMap(\.achievements).filter { $0.template == .habit && !$0.isArchived }
    }

    var body: some View {
        NavigationView {
            List {
                // ── 习惯打卡 ──────────────────────────────────────────
                Section {
                    if showHabits {
                        // Day header row
                        HStack(spacing: 0) {
                            Text("").frame(width: 86)
                            ForEach(habitWeekDates, id: \.self) { day in
                                VStack(spacing: 2) {
                                    Text(day.weekdayShort)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Text(day.dayNumber)
                                        .font(.system(size: 11, weight: day.isToday ? .bold : .regular))
                                        .foregroundColor(day.isToday ? .blue : .primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .listRowBackground(Color(.secondarySystemBackground))

                        if habits.isEmpty {
                            HStack {
                                Spacer()
                                Text("还没有习惯").foregroundColor(.secondary).font(.system(size: 13))
                                Spacer()
                            }
                        } else {
                            ForEach(habits) { habit in
                                HabitGridRow(habit: habit, weekDates: habitWeekDates, vm: treeVM)
                            }
                        }

                        Button {
                            showAddHabit = true
                        } label: {
                            Label("添加习惯", systemImage: "plus.circle")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Button {
                            withAnimation { showHabits.toggle() }
                        } label: {
                            HStack(spacing: 4) {
                                Text("习惯打卡")
                                    .font(.system(size: 13, weight: .semibold))
                                Image(systemName: showHabits ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        if showHabits {
                            HStack(spacing: 8) {
                                Button { habitWeekOffset -= 1 } label: {
                                    Image(systemName: "chevron.left").font(.system(size: 11))
                                }
                                .buttonStyle(.plain)
                                Text(WeekCalculator.weekLabel(dates: habitWeekDates))
                                    .font(.system(size: 11))
                                Button {
                                    if habitWeekOffset < 0 { habitWeekOffset += 1 }
                                } label: {
                                    Image(systemName: "chevron.right").font(.system(size: 11))
                                        .foregroundColor(habitWeekOffset >= 0 ? .secondary : .primary)
                                }
                                .buttonStyle(.plain)
                                .disabled(habitWeekOffset >= 0)
                            }
                        }
                    }
                }

                // ── 各分类 ─────────────────────────────────────────────
                ForEach(prefs.orderedCategories, id: \.self) { cat in
                    let activeStats   = vm.stats.filter { $0.category == cat && !prefs.inactiveHobbies.contains($0.label) }
                    let inactiveStats = vm.stats.filter { $0.category == cat &&  prefs.inactiveHobbies.contains($0.label) }
                    let catTotalMins  = (activeStats + inactiveStats).reduce(0) { $0 + $1.totalMinutes }

                    Section {
                        ForEach(activeStats) { hobby in
                            HobbyRowView(
                                stat: hobby, isInactive: false,
                                isTimerActive: timer.activeHobby == hobby.label,
                                onStartTimer: {
                                    if timer.activeHobby == hobby.label {
                                        Task { await timer.stop(save: true) }
                                    } else { timer.start(hobby: hobby.label, color: hobby.color) }
                                },
                                onEdit: { editingHobby = hobby }
                            )
                        }
                        ForEach(inactiveStats) { hobby in
                            HobbyRowView(
                                stat: hobby, isInactive: true,
                                isTimerActive: false,
                                onStartTimer: {},
                                onEdit: { editingHobby = hobby }
                            )
                        }
                    } header: {
                        HStack {
                            Button(prefs.displayName(for: cat)) {
                                renameDraft = prefs.displayName(for: cat)
                                renamingCat = cat
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            Spacer()
                            if catTotalMins > 0 {
                                Text(minuteLabel(catTotalMins))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // ── 未分类 ────────────────────────────────────────────
                let uncategorized = vm.stats.filter { $0.category == nil }
                if !uncategorized.isEmpty {
                    Section("未分类") {
                        ForEach(uncategorized) { hobby in
                            HobbyRowView(
                                stat: hobby, isInactive: prefs.inactiveHobbies.contains(hobby.label),
                                isTimerActive: timer.activeHobby == hobby.label,
                                onStartTimer: {
                                    if timer.activeHobby == hobby.label {
                                        Task { await timer.stop(save: true) }
                                    } else { timer.start(hobby: hobby.label, color: hobby.color) }
                                },
                                onEdit: { editingHobby = hobby }
                            )
                        }
                    }
                }
            }
            .navigationTitle("活动")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("添加活动") { showAddHobby = true }
                        Button("添加分类") { showAddCategory = true }
                        Divider()
                        Button("排序分类") { showCatOrder = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await vm.load(prefs: prefs)
                await treeVM.load(prefs: prefs)
            }
            // Category rename alert
            .alert("重命名分类", isPresented: Binding(
                get: { renamingCat != nil },
                set: { if !$0 { renamingCat = nil } }
            )) {
                TextField("分类名称", text: $renameDraft)
                Button("确定") {
                    if let cat = renamingCat {
                        Task { await prefs.renameCategory(cat, to: renameDraft) }
                    }
                    renamingCat = nil
                }
                Button("取消", role: .cancel) { renamingCat = nil }
            }
            // Edit sheet
            .sheet(item: $editingHobby) { hobby in
                HobbyEditSheet(
                    stat: hobby,
                    categories: prefs.orderedCategories,
                    currentTimeCategory: prefs.timeCategoryMap[hobby.label],
                    isInactive: prefs.inactiveHobbies.contains(hobby.label),
                    onSaveCategory:     { cat  in Task { await vm.updateCategory(hobby: hobby.label, category: cat) } },
                    onSaveHistorical:   { mins in Task { await vm.updateHistorical(hobby: hobby.label, minutes: mins) } },
                    onSaveColor:        { c    in Task { await prefs.setColorOverride(c, for: hobby.label) } },
                    onSaveLabel:        { l    in Task { await prefs.setLabelRename(l, for: hobby.label) } },
                    onSaveTimeCategory: { tc   in
                        if let tc = tc { Task { await prefs.setTimeCategory(tc, for: hobby.label) } }
                    },
                    onSetInactive: { Task { await prefs.setInactive(hobby: hobby.label) } },
                    onSetActive:   { Task { await prefs.setActive(hobby: hobby.label) } },
                    onHide:        {
                        let label = hobby.label
                        Task { await prefs.hide(hobby: label) }
                        undoTask?.cancel()
                        undoHobbyLabel = label
                        undoTask = Task {
                            try? await Task.sleep(nanoseconds: 5_000_000_000)
                            if !Task.isCancelled { undoHobbyLabel = nil }
                        }
                    }
                )
            }
            .sheet(isPresented: $showAddHobby) {
                AddHobbySheet { label, color in
                    Task { await prefs.addCustomHobby(label: label, color: color) }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet { name in
                    Task { await prefs.addCustomCategory(name) }
                }
            }
            .sheet(isPresented: $showCatOrder) {
                CategoryOrderSheet(
                    categories: prefs.orderedCategories,
                    displayName: { prefs.displayName(for: $0) },
                    onSave: { order in Task { await prefs.reorderCategories(order) } }
                )
            }
            .sheet(isPresented: $showAddHabit) {
                AddHabitSheet { insert in
                    Task { await treeVM.addAchievement(insert: insert) }
                }
                .environmentObject(prefs)
            }
            .overlay(alignment: .bottom) {
                if let label = undoHobbyLabel {
                    HStack(spacing: 12) {
                        Text("已隐藏「\(label)」")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        Spacer()
                        Button("撤销") {
                            undoTask?.cancel()
                            undoTask = nil
                            undoHobbyLabel = nil
                            Task { await prefs.unhide(hobby: label) }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.label).opacity(0.88))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: undoHobbyLabel)
                }
            }
        }
    }

    private func minuteLabel(_ mins: Int) -> String {
        let h = mins / 60; let m = mins % 60
        return h > 0 ? "\(h)h\(m > 0 ? " \(m)m" : "")" : "\(m)m"
    }
}
