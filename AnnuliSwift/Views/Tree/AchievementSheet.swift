import SwiftUI

struct AchievementSheet: View {
    let category: String
    let year: Int
    let parentId: UUID?                     // non-nil when adding a child item
    let onAdd: (AchievementInsert) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var template: AchievementTemplate = .general

    init(category: String, year: Int, parentId: UUID? = nil, onAdd: @escaping (AchievementInsert) -> Void) {
        self.category = category; self.year = year; self.parentId = parentId; self.onAdd = onAdd
        _template = State(initialValue: parentId != nil ? .dividend : .general)
    }

    var body: some View {
        NavigationView {
            Form {
                if parentId == nil {
                    Section("成就类型") {
                        Picker("类型", selection: $template) {
                            Text("普通").tag(AchievementTemplate.general)
                            Text("习惯打卡").tag(AchievementTemplate.habit)
                            if isInvestment {
                                Divider()
                                Text("股息").tag(AchievementTemplate.dividend)
                                Text("定存").tag(AchievementTemplate.deposit)
                                Text("股票收益").tag(AchievementTemplate.stockProfit)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                } else {
                    // Child item — choose investment type
                    Section("投资类型") {
                        Picker("类型", selection: $template) {
                            Text("股息").tag(AchievementTemplate.dividend)
                            Text("定存").tag(AchievementTemplate.deposit)
                            Text("股票收益").tag(AchievementTemplate.stockProfit)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                switch template {
                case .dividend:
                    DividendForm(category: category, year: year, parentId: parentId, onAdd: onAdd, dismiss: dismiss)
                case .deposit:
                    DepositForm(category: category, year: year, parentId: parentId, onAdd: onAdd, dismiss: dismiss)
                case .stockProfit:
                    StockProfitForm(category: category, year: year, parentId: parentId, onAdd: onAdd, dismiss: dismiss)
                default:
                    GeneralForm(category: category, year: year, parentId: parentId, template: template, onAdd: onAdd, dismiss: dismiss)
                }
            }
            .navigationTitle(parentId != nil ? "添加投资子项" : "添加成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }

    private var isInvestment: Bool {
        category.contains("投资") || category.contains("理财")
    }
}

// MARK: - General / habit form

private struct GeneralForm: View {
    let category: String; let year: Int; let parentId: UUID?
    let template: AchievementTemplate
    let onAdd: (AchievementInsert) -> Void
    let dismiss: DismissAction

    @State private var name = ""
    @State private var unit = "次"
    @State private var targetText = "10"

    private let unitPresets = ["次", "小时", "天", "本", "km", "kg"]

    var body: some View {
        Section("基本信息") {
            TextField("成就名称", text: $name)
            HStack {
                TextField("目标数值", text: $targetText).keyboardType(.decimalPad)
                Spacer()
                Picker("单位", selection: $unit) {
                    ForEach(unitPresets, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
            }
        }
        Section {
            Button("添加") {
                guard let target = Double(targetText),
                      let userId = AuthService.currentUserId else { return }
                onAdd(AchievementInsert(userId: userId, category: category, name: name, unit: unit,
                                        targetValue: target, year: year, template: template,
                                        metadata: nil, parentId: parentId))
                dismiss()
            }
            .disabled(name.isEmpty)
        }
    }
}

// MARK: - Dividend form

private struct DividendForm: View {
    let category: String; let year: Int; let parentId: UUID?
    let onAdd: (AchievementInsert) -> Void
    let dismiss: DismissAction

    @State private var name = ""
    @State private var currency = "CNY"
    @State private var sharesText = ""
    @State private var dividendPer10Text = ""

    private var calculatedTarget: Double {
        let s = Double(sharesText) ?? 0
        let d = Double(dividendPer10Text) ?? 0
        return s / 10 * d
    }

    var body: some View {
        Section("股票信息") {
            TextField("股票名称 / 代码", text: $name)
            Picker("货币", selection: $currency) {
                Text("人民币 ¥").tag("CNY")
                Text("美元 $").tag("USD")
            }
            .pickerStyle(.segmented)
            HStack {
                Text("持股数量")
                Spacer()
                TextField("股数", text: $sharesText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
            }
            HStack {
                Text("每10股股息")
                Spacer()
                TextField("金额", text: $dividendPer10Text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                Text(currency == "CNY" ? "¥" : "$").foregroundColor(.secondary)
            }
        }

        Section {
            HStack {
                Text("预计年收益")
                Spacer()
                Text(String(format: "%@ %.2f", currency == "CNY" ? "¥" : "$", calculatedTarget))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(calculatedTarget > 0 ? .green : .secondary)
            }
        }

        Section {
            Button("添加") {
                guard let userId = AuthService.currentUserId,
                      !name.isEmpty, calculatedTarget > 0 else { return }
                let meta = AchievementMetaWrapper(unit: nil, period: nil,
                                                  name: name, currency: currency,
                                                  shares: Double(sharesText) ?? 0,
                                                  dividendPer10: Double(dividendPer10Text) ?? 0,
                                                  principal: nil, rate: nil, costBasis: nil)
                let unit = currency == "CNY" ? "¥" : "$"
                onAdd(AchievementInsert(userId: userId, category: category, name: name, unit: unit,
                                        targetValue: calculatedTarget, year: year,
                                        template: .dividend, metadata: meta, parentId: parentId))
                dismiss()
            }
            .disabled(name.isEmpty || calculatedTarget <= 0)
        }
    }
}

// MARK: - Deposit form

private struct DepositForm: View {
    let category: String; let year: Int; let parentId: UUID?
    let onAdd: (AchievementInsert) -> Void
    let dismiss: DismissAction

    @State private var name = ""
    @State private var currency = "CNY"
    @State private var principalText = ""
    @State private var rateText = ""

    private var calculatedInterest: Double {
        let p = Double(principalText) ?? 0
        let r = Double(rateText) ?? 0
        return p * r / 100
    }

    var body: some View {
        Section("存款信息") {
            TextField("存款名称（银行/产品名）", text: $name)
            Picker("货币", selection: $currency) {
                Text("人民币 ¥").tag("CNY")
                Text("美元 $").tag("USD")
            }
            .pickerStyle(.segmented)
            HStack {
                Text("本金")
                Spacer()
                TextField("金额", text: $principalText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                Text(currency == "CNY" ? "¥" : "$").foregroundColor(.secondary)
            }
            HStack {
                Text("年利率")
                Spacer()
                TextField("利率", text: $rateText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("%").foregroundColor(.secondary)
            }
        }

        Section {
            HStack {
                Text("预计年利息")
                Spacer()
                Text(String(format: "%@ %.2f", currency == "CNY" ? "¥" : "$", calculatedInterest))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(calculatedInterest > 0 ? .green : .secondary)
            }
        }

        Section {
            Button("添加") {
                guard let userId = AuthService.currentUserId,
                      !name.isEmpty, calculatedInterest > 0 else { return }
                let meta = AchievementMetaWrapper(unit: nil, period: nil,
                                                  name: name, currency: currency,
                                                  shares: nil, dividendPer10: nil,
                                                  principal: Double(principalText) ?? 0,
                                                  rate: Double(rateText) ?? 0,
                                                  costBasis: nil)
                let unit = currency == "CNY" ? "¥" : "$"
                onAdd(AchievementInsert(userId: userId, category: category, name: name, unit: unit,
                                        targetValue: calculatedInterest, year: year,
                                        template: .deposit, metadata: meta, parentId: parentId))
                dismiss()
            }
            .disabled(name.isEmpty || calculatedInterest <= 0)
        }
    }
}

// MARK: - Stock profit form

private struct StockProfitForm: View {
    let category: String; let year: Int; let parentId: UUID?
    let onAdd: (AchievementInsert) -> Void
    let dismiss: DismissAction

    @State private var name = ""
    @State private var currency = "CNY"
    @State private var targetProfitText = ""
    @State private var costBasisText = ""

    var body: some View {
        Section("股票信息") {
            TextField("股票名称 / 代码", text: $name)
            Picker("货币", selection: $currency) {
                Text("人民币 ¥").tag("CNY")
                Text("美元 $").tag("USD")
            }
            .pickerStyle(.segmented)
            HStack {
                Text("目标盈利")
                Spacer()
                TextField("金额", text: $targetProfitText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                Text(currency == "CNY" ? "¥" : "$").foregroundColor(.secondary)
            }
            HStack {
                Text("成本基数（可选）")
                Spacer()
                TextField("金额", text: $costBasisText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                Text(currency == "CNY" ? "¥" : "$").foregroundColor(.secondary)
            }
        }

        Section {
            Button("添加") {
                guard let userId = AuthService.currentUserId,
                      !name.isEmpty,
                      let target = Double(targetProfitText), target > 0 else { return }
                let meta = AchievementMetaWrapper(unit: nil, period: nil,
                                                  name: name, currency: currency,
                                                  shares: nil, dividendPer10: nil,
                                                  principal: nil, rate: nil,
                                                  costBasis: costBasisText.isEmpty ? nil : Double(costBasisText))
                let unit = currency == "CNY" ? "¥" : "$"
                onAdd(AchievementInsert(userId: userId, category: category, name: name, unit: unit,
                                        targetValue: target, year: year,
                                        template: .stockProfit, metadata: meta, parentId: parentId))
                dismiss()
            }
            .disabled(name.isEmpty || (Double(targetProfitText) ?? 0) <= 0)
        }
    }
}
