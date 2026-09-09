import SwiftUI

struct WeeklyHabitGridView: View {
    @ObservedObject var vm: TreeViewModel
    @State private var weekOffset = 0
    @State private var showAddHabit = false

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
                            Text("").frame(width: 80)
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
            }
        }
    }
}

// MARK: - Habit row

struct HabitGridRow: View {
    let habit: Achievement
    let weekDates: [Date]
    @ObservedObject var vm: TreeViewModel

    var body: some View {
        HStack(spacing: 0) {
            Text(habit.name)
                .font(.system(size: 13))
                .lineLimit(2)
                .frame(width: 80, alignment: .leading)

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
                    Circle()
                        .fill(checkedIn ? Color.green : Color(.systemFill))
                        .overlay(
                            day.isToday ? Circle().stroke(Color.blue, lineWidth: 2) : nil
                        )
                        .frame(width: 28, height: 28)
                        .opacity(isFuture ? 0.3 : 1)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Add habit sheet

struct AddHabitSheet: View {
    let onAdd: (AchievementInsert) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var targetText = "7"
    @State private var unit = "天"
    @EnvironmentObject private var prefs: PrefsViewModel

    var body: some View {
        NavigationView {
            Form {
                TextField("习惯名称", text: $name)
                HStack {
                    TextField("目标", text: $targetText).keyboardType(.numberPad)
                    Picker("周期", selection: $unit) {
                        Text("天/周").tag("天")
                        Text("次/周").tag("次")
                    }.pickerStyle(.segmented)
                }
            }
            .navigationTitle("添加习惯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let target = Double(targetText),
                              let userId = AuthService.currentUserId else { return }
                        let insert = AchievementInsert(
                            userId: userId,
                            category: prefs.orderedCategories.first ?? "健康",
                            name: name, unit: unit, targetValue: target,
                            year: Calendar.current.component(.year, from: Date()),
                            template: .habit, metadata: nil, parentId: nil
                        )
                        onAdd(insert); dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
