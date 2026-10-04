import SwiftUI

// MARK: - Root scroll view

struct LifeTreeView: View {
    @ObservedObject var vm: DomainViewModel
    @EnvironmentObject var prefs: PrefsViewModel

    var totalMins: Int { vm.hobbyMinutes.values.reduce(0, +) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {

                // Year summary
                if totalMins > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(vm.selectedYear) 年总投入")
                                .font(.caption).foregroundColor(.secondary)
                            Text(fmtMins(totalMins))
                                .font(.system(size: 24, weight: .bold))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }

                // Domain cards
                ForEach(vm.domains) { domain in
                    DomainCard(domain: domain, vm: vm)
                        .environmentObject(prefs)
                        .padding(.horizontal, 16)
                }

                // Unassigned hobbies
                let unassigned = prefs.resolvedHobbies.filter { prefs.domainId(for: $0.label) == nil }
                if !unassigned.isEmpty {
                    UnassignedCard(hobbies: unassigned, vm: vm)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 12)
        }
    }
}

// MARK: - Domain card

private struct DomainCard: View {
    let domain: Domain
    @ObservedObject var vm: DomainViewModel
    @EnvironmentObject var prefs: PrefsViewModel
    @State private var showAddOutput = false

    var hobbies: [HobbyItemMeta]  { prefs.hobbies(in: domain.id) }
    var outputs: [DomainOutput]   { vm.outputs(for: domain.id) }
    var totalMins: Int            { hobbies.reduce(0) { $0 + (vm.hobbyMinutes[$1.hobby.label] ?? 0) } }
    var maxMinsInDomain: Int      { hobbies.map { vm.hobbyMinutes[$0.hobby.label] ?? 0 }.max() ?? 1 }
    var currentEfficiency: String { vm.efficiency(for: domain.id, year: vm.selectedYear) ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ─────────────────────────────────────────────────
            HStack(spacing: 10) {
                Circle().fill(Color(hex: domain.color)).frame(width: 12, height: 12)
                Text(domain.name).font(.system(size: 16, weight: .semibold))
                Spacer()
                if totalMins > 0 {
                    Text(fmtMins(totalMins))
                        .font(.system(size: 13)).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider().padding(.leading, 16)

            // ── 输入 ───────────────────────────────────────────────────
            if !hobbies.isEmpty {
                CardSectionLabel("输入")
                ForEach(hobbies) { meta in
                    HobbyInputRow(
                        meta: meta,
                        minutes: vm.hobbyMinutes[meta.hobby.label] ?? 0,
                        maxMins: maxMinsInDomain,
                        rank: prefs.priorityIndex(of: meta.hobby.label)
                    )
                    if meta.id != hobbies.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
                Divider().padding(.leading, 16)
            }

            // ── 产出 ───────────────────────────────────────────────────
            CardSectionLabel("产出")
            if outputs.isEmpty {
                Text("暂无产出记录")
                    .font(.system(size: 13)).foregroundColor(Color(.tertiaryLabel))
                    .padding(.horizontal, 16).padding(.bottom, 6)
            } else {
                ForEach(outputs) { output in
                    OutputRow(output: output) {
                        Task { try? await vm.deleteOutput(output) }
                    }
                    if output.id != outputs.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            Button {
                showAddOutput = true
            } label: {
                Label("记录产出", systemImage: "plus")
                    .font(.system(size: 13)).foregroundColor(.blue)
            }
            .padding(.horizontal, 16).padding(.vertical, 9)

            Divider().padding(.leading, 16)

            // ── 效率标注 ────────────────────────────────────────────────
            EfficiencyRow(current: currentEfficiency) { label in
                Task { await vm.setEfficiency(label, for: domain.id, year: vm.selectedYear) }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .sheet(isPresented: $showAddOutput) {
            AddOutputSheet(vm: vm, domainId: domain.id)
        }
    }
}

// MARK: - Section label

private struct CardSectionLabel: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 10).padding(.bottom, 2)
    }
}

// MARK: - Hobby input row

private struct HobbyInputRow: View {
    let meta: HobbyItemMeta
    let minutes: Int
    let maxMins: Int
    let rank: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(rank < Int.max ? "#\(rank + 1)" : "  –")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)

            Circle().fill(Color(hex: meta.hobby.color)).frame(width: 8, height: 8)

            Text(meta.hobby.displayLabel)
                .font(.system(size: 14)).lineLimit(1)

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(minutes > 0 ? fmtMins(minutes) : "0m")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(minutes > 0 ? .primary : Color(.tertiaryLabel))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(.systemGray5)).frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: meta.hobby.color))
                            .frame(
                                width: geo.size.width * CGFloat(minutes) / CGFloat(max(1, maxMins)),
                                height: 4
                            )
                    }
                }
                .frame(width: 80, height: 4)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

// MARK: - Output row

private struct OutputRow: View {
    let output: DomainOutput
    let onDelete: () -> Void

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "M月d日"
        f.locale = Locale(identifier: "zh_CN"); return f
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(output.title).font(.system(size: 14, weight: .medium))
                    if let c = output.count {
                        Text("\(c)")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.blue)
                            .padding(.horizontal, 7).padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1)).cornerRadius(5)
                    }
                }
                if let notes = output.notes, !notes.isEmpty {
                    Text(notes).font(.system(size: 12)).foregroundColor(.secondary).lineLimit(2)
                }
            }
            Spacer()
            if let date = output.date.toDate() {
                Text(Self.dateFmt.string(from: date))
                    .font(.system(size: 11)).foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { onDelete() } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Efficiency row

private let efficiencyOptions = ["高效 🎯", "稳步积累 📈", "需调整 🔄", "暂停中 ⏸"]

private struct EfficiencyRow: View {
    let current: String
    let onChange: (String) -> Void

    var body: some View {
        HStack {
            Text("效率").font(.system(size: 12)).foregroundColor(.secondary)
            Spacer()
            Menu {
                ForEach(efficiencyOptions, id: \.self) { opt in
                    Button(opt) { onChange(opt) }
                }
                if !current.isEmpty {
                    Divider()
                    Button("清除标注", role: .destructive) { onChange("") }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(current.isEmpty ? "标注效率" : current)
                        .font(.system(size: 13))
                        .foregroundColor(current.isEmpty ? .secondary : .primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

// MARK: - Add output sheet

struct AddOutputSheet: View {
    @ObservedObject var vm: DomainViewModel
    let domainId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var title    = ""
    @State private var hasCount = false
    @State private var count    = 1
    @State private var date     = Date()
    @State private var notes    = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("标题（必填）") {
                    TextField("如：英语短视频、读书笔记、文章", text: $title)
                }
                Section {
                    Toggle("有具体数量", isOn: $hasCount.animation())
                    if hasCount {
                        Stepper("数量：\(count)", value: $count, in: 1...9999)
                    }
                } header: { Text("数量（可选）") }
                Section("日期") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                        .labelsHidden()
                }
                Section("备注（可选）") {
                    TextField("补充说明…", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("记录产出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let form = OutputForm(
                            domainId: domainId,
                            title: title,
                            date: date.localDateString(),
                            count: hasCount ? count : nil,
                            notes: notes
                        )
                        Task { try? await vm.addOutput(form: form); dismiss() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Unassigned hobbies card

private struct UnassignedCard: View {
    let hobbies: [HobbyItem]
    @ObservedObject var vm: DomainViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle").foregroundColor(Color(.tertiaryLabel))
                Text("未分配领域").font(.system(size: 15, weight: .semibold)).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().padding(.leading, 16)
            ForEach(hobbies, id: \.label) { hobby in
                HStack(spacing: 10) {
                    Circle().fill(Color(hex: hobby.color)).frame(width: 8, height: 8)
                    Text(hobby.displayLabel).font(.system(size: 14)).foregroundColor(.secondary)
                    Spacer()
                    if let m = vm.hobbyMinutes[hobby.label], m > 0 {
                        Text(fmtMins(m)).font(.system(size: 12)).foregroundColor(Color(.tertiaryLabel))
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 9)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14).opacity(0.7)
    }
}

// MARK: - Empty state

struct EmptyDomainsView: View {
    let onSetup: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 52)).foregroundColor(Color(.systemGray3))
            Text("还没有领域").font(.title3.weight(.semibold))
            Text("点击左上角图标，创建第一个领域\n（如：健康、英语、投资）")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("立即创建") { onSetup() }.buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// MARK: - Helper

private func fmtMins(_ mins: Int) -> String {
    guard mins > 0 else { return "0m" }
    let h = mins / 60; let m = mins % 60
    if h == 0  { return "\(m)m" }
    if m == 0  { return "\(h)h" }
    return "\(h)h \(m)m"
}
