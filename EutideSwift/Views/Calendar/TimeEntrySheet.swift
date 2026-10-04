import SwiftUI

struct TimeEntrySheet: View {
    @ObservedObject var vm: CalendarViewModel
    @EnvironmentObject var prefs: PrefsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showHobbyPicker = false
    @State private var showDeleteConfirm = false
    @State private var expanded: ExpandedField? = nil

    enum ExpandedField: Equatable { case start, end }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top bar ─────────────────────────────────────────────
            HStack {
                CircleButton(icon: "xmark", filled: false) { dismiss() }
                Spacer()
                Text(vm.editingEntry == nil ? "新建记录" : "编辑记录")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                CircleButton(icon: "checkmark", filled: !vm.draftForm.hobby.isEmpty) {
                    Task { await vm.saveEntry() }
                }
                .disabled(vm.draftForm.hobby.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 10) {

                    // ── Activity selector ─────────────────────────────
                    CardSection {
                        Button { showHobbyPicker = true } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color(hex: vm.draftForm.color))
                                    .frame(width: 14, height: 14)
                                Text(vm.draftForm.hobby.isEmpty ? "选择活动" : vm.draftForm.hobby)
                                    .font(.system(size: 16))
                                    .foregroundColor(vm.draftForm.hobby.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // ── Start / End ──────────────────────────────────
                    CardSection {
                        VStack(spacing: 0) {
                            TimeRow(
                                label: "开始",
                                dateStr: $vm.draftForm.date,
                                timeStr: $vm.draftForm.startTime,
                                isExpanded: expanded == .start
                            ) { expanded = expanded == .start ? nil : .start }

                            if expanded == .start {
                                Divider().padding(.leading, 16)
                                InlineDateTimePicker(
                                    dateStr: $vm.draftForm.date,
                                    timeStr: $vm.draftForm.startTime
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            Divider().padding(.leading, 16)

                            TimeRow(
                                label: "结束",
                                dateStr: $vm.draftForm.date,
                                timeStr: $vm.draftForm.endTime,
                                isExpanded: expanded == .end
                            ) { expanded = expanded == .end ? nil : .end }

                            if expanded == .end {
                                Divider().padding(.leading, 16)
                                InlineDateTimePicker(
                                    dateStr: $vm.draftForm.date,
                                    timeStr: $vm.draftForm.endTime
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }

                    // ── Mood ─────────────────────────────────────────
                    CardSection {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("心情")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            MoodPickerView(mood: $vm.draftForm.mood)
                        }
                    }

                    // ── Notes ─────────────────────────────────────────
                    CardSection {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("备注")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 4)
                            TextField("添加备注…", text: $vm.draftForm.notes, axis: .vertical)
                                .font(.system(size: 15))
                                .lineLimit(3...6)
                        }
                    }

                    // ── Delete (edit mode) ─────────────────────────
                    if vm.editingEntry != nil {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Text("删除这条记录")
                                .font(.system(size: 16))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .animation(.easeInOut(duration: 0.2), value: expanded)
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
                if let entry = vm.editingEntry { Task { await vm.deleteEntry(entry) } }
            }
        }
    }
}

// MARK: - Subviews

private struct CircleButton: View {
    let icon: String
    let filled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(filled ? .white : .primary)
                .frame(width: 34, height: 34)
                .background(filled ? Color.blue : Color(.secondarySystemBackground))
                .clipShape(Circle())
        }
    }
}

private struct CardSection<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
    }
}

private struct TimeRow: View {
    let label: String
    @Binding var dateStr: String
    @Binding var timeStr: String
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .frame(width: 36, alignment: .leading)
                Spacer()
                // Date chip
                Text(formattedDate)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isExpanded ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isExpanded ? Color.blue : Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                // Time chip
                Text(timeStr)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isExpanded ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isExpanded ? Color.blue : Color(.tertiarySystemBackground))
                    .cornerRadius(8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        guard let date = dateStr.toDate() else { return dateStr }
        let fmt = DateFormatter(); fmt.dateFormat = "M月d日"; fmt.locale = Locale(identifier: "zh_CN")
        return fmt.string(from: date)
    }
}

// Inline expandable date + time picker
private struct InlineDateTimePicker: View {
    @Binding var dateStr: String
    @Binding var timeStr: String

    var body: some View {
        VStack(spacing: 0) {
            // Date picker (compact graphical)
            DatePicker(
                "",
                selection: Binding(
                    get: { dateStr.toDate() ?? Date() },
                    set: { dateStr = $0.localDateString() }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .environment(\.locale, Locale(identifier: "zh_CN"))
            .labelsHidden()
            .frame(maxHeight: 300)

            Divider()

            // Time picker (15-min snap wheels)
            TimePicker(label: "", time: $timeStr)
                .padding(.vertical, 4)
        }
    }
}

// MARK: - 15-minute-snapping wheel time picker

struct TimePicker: View {
    let label: String
    @Binding var time: String

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
        HStack(spacing: 0) {
            if !label.isEmpty {
                Text(label).foregroundColor(.secondary)
                Spacer()
            }
            HStack(spacing: 0) {
                Picker("时", selection: hour) {
                    ForEach(0..<24, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
                .pickerStyle(.wheel).frame(width: 56, height: 100).clipped()

                Text(":").font(.system(size: 17, weight: .medium))

                Picker("分", selection: quarterIndex) {
                    ForEach(0..<4, id: \.self) { Text(String(format: "%02d", $0 * 15)).tag($0) }
                }
                .pickerStyle(.wheel).frame(width: 56, height: 100).clipped()
            }
            .frame(maxWidth: label.isEmpty ? .infinity : nil)
            .frame(maxWidth: label.isEmpty ? .infinity : nil)
        }
    }
}
