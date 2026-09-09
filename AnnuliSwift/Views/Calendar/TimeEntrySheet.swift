import SwiftUI

struct TimeEntrySheet: View {
    @ObservedObject var vm: CalendarViewModel
    @EnvironmentObject var prefs: PrefsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showHobbyPicker = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            Form {
                // Hobby picker row
                Section {
                    Button {
                        showHobbyPicker = true
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: vm.draftForm.color))
                                .frame(width: 14, height: 14)
                            Text(vm.draftForm.hobby.isEmpty ? "选择活动" : vm.draftForm.hobby)
                                .foregroundColor(vm.draftForm.hobby.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Date + time
                Section {
                    DatePicker("日期", selection: Binding(
                        get: { vm.draftForm.date.toDate() ?? Date() },
                        set: { vm.draftForm.date = $0.localDateString() }
                    ), displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "zh_CN"))

                    TimePicker(label: "开始", time: $vm.draftForm.startTime)
                    TimePicker(label: "结束", time: $vm.draftForm.endTime)
                }

                // Mood
                Section("心情") {
                    MoodPickerView(mood: $vm.draftForm.mood)
                }

                // Notes
                Section("备注") {
                    TextEditor(text: $vm.draftForm.notes)
                        .frame(minHeight: 60)
                }

                // Delete button (edit mode only)
                if vm.editingEntry != nil {
                    Section {
                        Button("删除这条记录", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(vm.editingEntry == nil ? "新建记录" : "编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task { await vm.saveEntry() }
                    }
                    .disabled(vm.draftForm.hobby.isEmpty)
                }
            }
            .sheet(isPresented: $showHobbyPicker) {
                HobbyPickerView(
                    selected: $vm.draftForm.hobby,
                    selectedColor: $vm.draftForm.color,
                    hobbies: prefs.resolvedHobbies
                )
            }
            .confirmationDialog("确定删除？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    if let entry = vm.editingEntry {
                        Task { await vm.deleteEntry(entry) }
                    }
                }
            }
        }
    }
}

// MARK: - 15-minute-snapping time picker

struct TimePicker: View {
    let label: String
    @Binding var time: String  // "HH:MM"

    private var hour: Binding<Int> {
        Binding(
            get: { time.timeToMinutes() / 60 },
            set: { h in
                let m = (time.timeToMinutes() % 60 / 15) * 15
                time = String(format: "%02d:%02d", h, m)
            }
        )
    }

    private var quarterIndex: Binding<Int> {
        Binding(
            get: { (time.timeToMinutes() % 60) / 15 },
            set: { qi in
                let h = time.timeToMinutes() / 60
                time = String(format: "%02d:%02d", h, qi * 15)
            }
        )
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 0) {
                Picker("时", selection: hour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 52, height: 100)
                .clipped()

                Text(":").font(.system(size: 17, weight: .medium))

                Picker("分", selection: quarterIndex) {
                    ForEach(0..<4, id: \.self) { qi in
                        Text(String(format: "%02d", qi * 15)).tag(qi)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 52, height: 100)
                .clipped()
            }
        }
    }
}
