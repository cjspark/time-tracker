import SwiftUI

struct TreeRootView: View {
    @StateObject private var vm = DomainViewModel()
    @EnvironmentObject private var prefs: PrefsViewModel
    @State private var showDomainSettings = false

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView("加载中…")
                } else if vm.domains.isEmpty {
                    EmptyDomainsView { showDomainSettings = true }
                } else {
                    LifeTreeView(vm: vm)
                        .environmentObject(prefs)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showDomainSettings = true } label: {
                        Image(systemName: "square.3.layers.3d")
                    }
                }
                ToolbarItem(placement: .principal) {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    Picker("年份", selection: $vm.selectedYear) {
                        ForEach((currentYear - 3)...currentYear, id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .task {
            await vm.load()
            await vm.loadStats(prefs: prefs)
        }
        .onChange(of: vm.selectedYear) { _ in
            Task { await vm.loadStats(prefs: prefs) }
        }
        .onChange(of: showDomainSettings) { isShowing in
            if !isShowing { Task { await vm.load() } }
        }
        .sheet(isPresented: $showDomainSettings) {
            DomainSettingsView().environmentObject(prefs)
        }
    }
}
