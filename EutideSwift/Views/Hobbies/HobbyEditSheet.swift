import SwiftUI

struct HobbyEditSheet: View {
    let stat: HobbyStats
    let categories: [String]
    let currentTimeCategory: String?
    let isInactive: Bool
    let onSaveCategory: (String) -> Void
    let onSaveHistorical: (Int) -> Void
    let onSaveColor: (String) -> Void
    let onSaveLabel: (String) -> Void
    let onSaveTimeCategory: (String?) -> Void
    let onSetInactive: () -> Void
    let onSetActive: () -> Void
    let onHide: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String
    @State private var historicalText: String
    @State private var labelText: String
    @State private var colorHex: String
    @State private var selectedTimeCategory: String

    init(stat: HobbyStats, categories: [String], currentTimeCategory: String?, isInactive: Bool,
         onSaveCategory: @escaping (String) -> Void,
         onSaveHistorical: @escaping (Int) -> Void,
         onSaveColor: @escaping (String) -> Void,
         onSaveLabel: @escaping (String) -> Void,
         onSaveTimeCategory: @escaping (String?) -> Void,
         onSetInactive: @escaping () -> Void,
         onSetActive: @escaping () -> Void,
         onHide: @escaping () -> Void) {
        self.stat = stat; self.categories = categories
        self.currentTimeCategory = currentTimeCategory; self.isInactive = isInactive
        self.onSaveCategory = onSaveCategory; self.onSaveHistorical = onSaveHistorical
        self.onSaveColor = onSaveColor; self.onSaveLabel = onSaveLabel
        self.onSaveTimeCategory = onSaveTimeCategory
        self.onSetInactive = onSetInactive; self.onSetActive = onSetActive; self.onHide = onHide
        _selectedCategory     = State(initialValue: stat.category ?? "")
        _historicalText       = State(initialValue: "\(stat.historicalMinutes)")
        _labelText            = State(initialValue: stat.displayLabel)
        _colorHex             = State(initialValue: stat.color)
        _selectedTimeCategory = State(initialValue: currentTimeCategory ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section("显示名称") {
                    TextField("名称", text: $labelText)
                }

                Section("颜色") {
                    ColorPicker("选择颜色", selection: Binding(
                        get: { Color(hex: colorHex) },
                        set: { color in if let hex = color.toHex() { colorHex = hex } }
                    ))
                }

                Section("大类") {
                    Picker("大类", selection: $selectedCategory) {
                        Text("未分类").tag("")
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                // 时间类型 — 决定复盘图表归属
                Section {
                    Picker("时间类型", selection: $selectedTimeCategory) {
                        Text("未设置").tag("")
                        ForEach(TimeCategory.allCases, id: \.self) { cat in
                            HStack {
                                Circle().fill(Color(hex: cat.hex)).frame(width: 10, height: 10)
                                Text(cat.displayName)
                            }
                            .tag(cat.rawValue)
                        }
                    }
                } header: {
                    Text("时间类型")
                } footer: {
                    Text("决定此活动在复盘图表中的颜色分类")
                        .font(.caption)
                }

                Section("历史时间（分钟）") {
                    TextField("分钟数（绝对值）", text: $historicalText)
                        .keyboardType(.numberPad)
                }

                Section {
                    if isInactive {
                        Button("激活此活动") {
                            onSetActive()
                            dismiss()
                        }
                        .foregroundColor(.green)
                    } else {
                        Button("封存此活动") {
                            onSetInactive()
                            dismiss()
                        }
                        .foregroundColor(.orange)
                    }
                    Button("完全隐藏（不可见）", role: .destructive) {
                        onHide()
                        dismiss()
                    }
                } footer: {
                    Text("封存：保留但置灰显示。完全隐藏：从所有列表中移除。")
                        .font(.caption)
                }
            }
            .navigationTitle("编辑「\(stat.label)」")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSaveLabel(labelText)
                        onSaveColor(colorHex)
                        onSaveCategory(selectedCategory)
                        onSaveTimeCategory(selectedTimeCategory.isEmpty ? nil : selectedTimeCategory)
                        if let mins = Int(historicalText) { onSaveHistorical(mins) }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Add hobby / category sheets

struct AddHobbySheet: View {
    let onAdd: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var color = Color.purple

    var body: some View {
        NavigationView {
            Form {
                TextField("活动名称", text: $label)
                ColorPicker("颜色", selection: $color)
            }
            .navigationTitle("添加活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        onAdd(label, color.toHex() ?? "#8B5CF6")
                        dismiss()
                    }.disabled(label.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct AddCategorySheet: View {
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationView {
            Form { TextField("分类名称", text: $name) }
            .navigationTitle("添加分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") { onAdd(name); dismiss() }.disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Category reorder sheet

struct CategoryOrderSheet: View {
    let categories: [String]
    let displayName: (String) -> String
    let onSave: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var ordered: [String]

    init(categories: [String], displayName: @escaping (String) -> String, onSave: @escaping ([String]) -> Void) {
        self.categories = categories; self.displayName = displayName; self.onSave = onSave
        _ordered = State(initialValue: categories)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(ordered, id: \.self) { cat in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                        Text(displayName(cat))
                    }
                }
                .onMove { from, to in ordered.move(fromOffsets: from, toOffset: to) }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("排序分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { onSave(ordered); dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Color+Hex helper

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
