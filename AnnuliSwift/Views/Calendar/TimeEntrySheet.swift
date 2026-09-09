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

// MARK: - Simple time picker

struct TimePicker: View {
    let label: String
    @Binding var time: String  // "HH:MM"

    private var date: Binding<Date> {
        Binding(
            get: {
                let mins = time.timeToMinutes()
                return Calendar.current.date(bySettingHour: mins / 60, minute: mins % 60, second: 0, of: Date()) ?? Date()
            },
            set: {
                let h = Calendar.current.component(.hour, from: $0)
                let m = Calendar.current.component(.minute, from: $0)
                time = String(format: "%02d:%02d", h, m)
            }
        )
    }

    var body: some View {
        DatePicker(label, selection: date, displayedComponents: .hourAndMinute)
            .environment(\.locale, Locale(identifier: "zh_CN"))
    }
}
