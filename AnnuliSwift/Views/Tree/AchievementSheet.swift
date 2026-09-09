import SwiftUI

struct AchievementSheet: View {
    let category: String
    let year: Int
    let onAdd: (AchievementInsert) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var unit = "次"
    @State private var targetValue: String = "10"
    @State private var template: AchievementTemplate = .general

    private let unitPresets = ["次", "小时", "天", "本", "km", "kg"]

    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("成就名称", text: $name)
                    Picker("类型", selection: $template) {
                        Text("普通").tag(AchievementTemplate.general)
                        Text("习惯打卡").tag(AchievementTemplate.habit)
                        if isInvestment {
                            Text("股息").tag(AchievementTemplate.dividend)
                            Text("存款").tag(AchievementTemplate.deposit)
                            Text("股票收益").tag(AchievementTemplate.stockProfit)
                        }
                    }
                }

                Section("目标") {
                    HStack {
                        TextField("目标数值", text: $targetValue)
                            .keyboardType(.decimalPad)
                        Spacer()
                        Picker("单位", selection: $unit) {
                            ForEach(unitPresets, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("添加成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        guard let target = Double(targetValue),
                              let userId = AuthService.currentUserId else { return }
                        let insert = AchievementInsert(
                            userId: userId, category: category, name: name, unit: unit,
                            targetValue: target, year: year, template: template, metadata: nil, parentId: nil
                        )
                        onAdd(insert)
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var isInvestment: Bool {
        category.contains("投资") || category.contains("理财")
    }
}
