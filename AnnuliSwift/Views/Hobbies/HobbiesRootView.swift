import SwiftUI

struct HobbiesRootView: View {
    @StateObject private var vm = HobbiesViewModel()
    @EnvironmentObject private var prefs: PrefsViewModel
    @EnvironmentObject private var timer: TimerViewModel

    @State private var showAddHobby = false
    @State private var showAddCategory = false
    @State private var editingHobby: HobbyStats?

    var body: some View {
        NavigationView {
            List {
                ForEach(prefs.orderedCategories, id: \.self) { cat in
                    let catStats = vm.stats.filter { $0.category == cat }
                    Section(prefs.displayName(for: cat)) {
                        ForEach(catStats) { hobby in
                            HobbyRowView(
                                stat: hobby,
                                isTimerActive: timer.activeHobby == hobby.label,
                                onStartTimer: {
                                    if timer.activeHobby == hobby.label {
                                        Task { await timer.stop(save: true) }
                                    } else {
                                        timer.start(hobby: hobby.label, color: hobby.color)
                                    }
                                },
                                onEdit: { editingHobby = hobby }
                            )
                        }
                    }
                }

                // Uncategorized
                let uncategorized = vm.stats.filter { $0.category == nil }
                if !uncategorized.isEmpty {
                    Section("未分类") {
                        ForEach(uncategorized) { hobby in
                            HobbyRowView(
                                stat: hobby,
                                isTimerActive: timer.activeHobby == hobby.label,
                                onStartTimer: {
                                    if timer.activeHobby == hobby.label {
                                        Task { await timer.stop(save: true) }
                                    } else {
                                        timer.start(hobby: hobby.label, color: hobby.color)
                                    }
                                },
                                onEdit: { editingHobby = hobby }
                            )
                        }
                    }
                }
            }
            .navigationTitle("活动")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("添加活动") { showAddHobby = true }
                        Button("添加分类") { showAddCategory = true }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task { await vm.load(prefs: prefs) }
            .sheet(item: $editingHobby) { hobby in
                HobbyEditSheet(
                    stat: hobby,
                    categories: prefs.orderedCategories,
                    onSaveCategory: { cat in Task { await vm.updateCategory(hobby: hobby.label, category: cat) } },
                    onSaveHistorical: { mins in Task { await vm.updateHistorical(hobby: hobby.label, minutes: mins) } },
                    onSaveColor: { color in Task { await prefs.setColorOverride(color, for: hobby.label) } },
                    onSaveLabel: { label in Task { await prefs.setLabelRename(label, for: hobby.label) } },
                    onHide: { Task { await prefs.hide(hobby: hobby.label) } }
                )
            }
            .sheet(isPresented: $showAddHobby) {
                AddHobbySheet { label, color in
                    Task { await prefs.addCustomHobby(label: label, color: color) }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet { name in
                    Task { await prefs.addCustomCategory(name) }
                }
            }
        }
    }
}
