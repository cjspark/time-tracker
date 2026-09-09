import SwiftUI

struct TreeRootView: View {
    @StateObject private var vm = TreeViewModel()
    @EnvironmentObject private var prefs: PrefsViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Sub-tab picker
                Picker("视图", selection: $selectedTab) {
                    Text("列表").tag(0)
                    Text("森林").tag(1)
                    Text("树形").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Group {
                    switch selectedTab {
                    case 0: TreeListView(vm: vm)
                    case 1: TreeBoardView(vm: vm)
                    default: TreeCanvasView(vm: vm)
                    }
                }
            }
            .navigationTitle("生命树")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("年份", selection: $vm.selectedYear) {
                        ForEach((Calendar.current.component(.year, from: Date()) - 3)...
                                (Calendar.current.component(.year, from: Date())), id: \.self) { y in
                            Text("\(y)").tag(y)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .task { await vm.load(prefs: prefs) }
        .onChange(of: vm.selectedYear) { _ in Task { await vm.load(prefs: prefs) } }
        .sheet(isPresented: $vm.showAchievementSheet) {
            AchievementSheet(category: vm.sheetCategory, year: vm.selectedYear) { insert in
                Task { await vm.addAchievement(insert: insert) }
            }
        }
        .sheet(item: $vm.selectedAchievement) { ach in
            RecordSheet(achievement: ach, vm: vm)
        }
    }
}
