import SwiftUI

// MARK: - Root sheet (领域管理入口)

struct DomainSettingsView: View {
    @EnvironmentObject var prefs: PrefsViewModel
    @StateObject private var vm = DomainViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddDomain = false

    var body: some View {
        NavigationStack {
            List {
                // ── 领域列表 ──────────────────────────────────────────
                Section("领域") {
                    ForEach(vm.domains) { domain in
                        NavigationLink {
                            DomainDetailView(domain: domain, vm: vm)
                                .environmentObject(prefs)
                        } label: {
                            DomainRowLabel(domain: domain, prefs: prefs)
                        }
                    }
                    .onDelete { idx in
                        Task {
                            for i in idx { try? await vm.deleteDomain(vm.domains[i]) }
                        }
                    }

                    Button { showAddDomain = true } label: {
                        Label("添加领域", systemImage: "plus")
                    }
                }

                // ── 全局优先级 ────────────────────────────────────────
                Section {
                    NavigationLink {
                        PriorityOrderView(domains: vm.domains)
                            .environmentObject(prefs)
                    } label: {
                        Label("调整全局优先级", systemImage: "arrow.up.arrow.down")
                    }
                } header: {
                    Text("优先级")
                } footer: {
                    Text("拖拽排序决定在生命树中各 Hobby 的展示顺序")
                }
            }
            .navigationTitle("领域管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddDomain) {
                AddDomainSheet(vm: vm)
            }
            .task { await vm.load() }
        }
    }
}

// MARK: - Domain row label

private struct DomainRowLabel: View {
    let domain: Domain
    let prefs: PrefsViewModel

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: domain.color)).frame(width: 12, height: 12)
            Text(domain.name)
            Spacer()
            Text("\(prefs.hobbies(in: domain.id).count) 项")
                .font(.caption).foregroundColor(.secondary)
        }
    }
}

// MARK: - Add domain sheet

private struct AddDomainSheet: View {
    @ObservedObject var vm: DomainViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name  = ""
    @State private var color = "#4A90E2"

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("领域名称，如：健康、英语、投资", text: $name)
                }
                Section("颜色") {
                    ColorPaletteRow(selected: $color)
                }
            }
            .navigationTitle("新建领域")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        Task { try? await vm.createDomain(name: name, color: color); dismiss() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Domain detail (edit name/color + hobby assignment)

struct DomainDetailView: View {
    @State var domain: Domain
    @ObservedObject var vm: DomainViewModel
    @EnvironmentObject var prefs: PrefsViewModel
    @State private var saved = false

    var body: some View {
        Form {
            Section("名称") {
                TextField("领域名称", text: $domain.name)
            }
            Section("颜色") {
                ColorPaletteRow(selected: $domain.color)
            }
            Section("归属此领域的 Hobby") {
                ForEach(prefs.resolvedHobbies, id: \.label) { hobby in
                    let isAssigned = prefs.domainId(for: hobby.label) == domain.id
                    Button {
                        Task {
                            await prefs.setDomain(isAssigned ? nil : domain.id, for: hobby.label)
                        }
                    } label: {
                        HStack {
                            Circle().fill(Color(hex: hobby.color)).frame(width: 10, height: 10)
                            Text(hobby.displayLabel).foregroundColor(.primary)
                            Spacer()
                            if isAssigned {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(domain.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    Task { try? await vm.updateDomain(domain); saved = true }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if saved {
                Text("已保存").font(.caption).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.black.opacity(0.7)).cornerRadius(8)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                    .onAppear { Task { try? await Task.sleep(nanoseconds: 1_200_000_000); saved = false } }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: saved)
    }
}

// MARK: - Priority drag-to-reorder

struct PriorityOrderView: View {
    let domains: [Domain]
    @EnvironmentObject var prefs: PrefsViewModel
    @State private var items: [HobbyItemMeta] = []

    var body: some View {
        List {
            ForEach(items) { meta in
                HStack(spacing: 12) {
                    Circle().fill(Color(hex: meta.hobby.color)).frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meta.hobby.displayLabel)
                        if let dId = meta.domainId,
                           let d = domains.first(where: { $0.id == dId }) {
                            Text(d.name).font(.caption).foregroundColor(.secondary)
                        } else {
                            Text("未分配领域").font(.caption).foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                }
            }
            .onMove { from, to in
                items.move(fromOffsets: from, toOffset: to)
                Task { await prefs.setPriorityOrder(items.map { $0.hobby.label }) }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("全局优先级")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { items = prefs.resolvedHobbiesWithMeta }
    }
}

// MARK: - Shared color palette picker

struct ColorPaletteRow: View {
    @Binding var selected: String
    private let palette = [
        "#FF6B6B","#FF9F43","#FECA57","#1DD1A1","#48CAE4",
        "#4A90E2","#5F27CD","#54A0FF","#8B5CF6","#F97316"
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
            ForEach(palette, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.8), lineWidth: selected == hex ? 2.5 : 0)
                            .padding(2)
                    )
                    .onTapGesture { selected = hex }
            }
        }
        .padding(.vertical, 4)
    }
}
