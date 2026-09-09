import SwiftUI

struct HobbyEditSheet: View {
    let stat: HobbyStats
    let categories: [String]
    let onSaveCategory: (String) -> Void
    let onSaveHistorical: (Int) -> Void
    let onSaveColor: (String) -> Void
    let onSaveLabel: (String) -> Void
    let onHide: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String
    @State private var historicalText: String
    @State private var labelText: String
    @State private var colorHex: String
    @State private var showColorPicker = false

    init(stat: HobbyStats, categories: [String],
         onSaveCategory: @escaping (String) -> Void,
         onSaveHistorical: @escaping (Int) -> Void,
         onSaveColor: @escaping (String) -> Void,
         onSaveLabel: @escaping (String) -> Void,
         onHide: @escaping () -> Void) {
        self.stat = stat; self.categories = categories
        self.onSaveCategory = onSaveCategory; self.onSaveHistorical = onSaveHistorical
        self.onSaveColor = onSaveColor; self.onSaveLabel = onSaveLabel; self.onHide = onHide
        _selectedCategory = State(initialValue: stat.category ?? "")
        _historicalText   = State(initialValue: "\(stat.historicalMinutes)")
        _labelText        = State(initialValue: stat.displayLabel)
        _colorHex         = State(initialValue: stat.color)
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
                        set: { color in
                            if let hex = color.toHex() { colorHex = hex }
                        }
                    ))
                }

                Section("分类") {
                    Picker("分类", selection: $selectedCategory) {
                        Text("未分类").tag("")
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("历史时间（分钟）") {
                    TextField("分钟数", text: $historicalText)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("隐藏此活动", role: .destructive) {
                        onHide()
                        dismiss()
                    }
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
