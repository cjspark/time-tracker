import SwiftUI
import Combine

@MainActor
class HobbiesViewModel: ObservableObject {
    @Published var stats: [HobbyStats] = []
    @Published var isLoading = false
    @Published var editingHobby: HobbyStats?
    @Published var showEditSheet = false

    func load(prefs: PrefsViewModel) async {
        isLoading = true
        do {
            async let history = HobbyService.fetchHistory()
            async let entries = TimeEntryService.fetchAll()
            async let hobbyPrefs = HobbyService.fetchPreferences()

            let (hist, allEntries, hPrefs) = try await (history, entries, hobbyPrefs)

            let histMap  = Dictionary(hist.map { ($0.hobby, $0.historicalMinutes) }, uniquingKeysWith: { $1 })
            let prefMap  = Dictionary(hPrefs.map { ($0.hobby, $0.category) }, uniquingKeysWith: { $1 })

            // Sum calendar minutes per hobby
            var calMap: [String: Int] = [:]
            for e in allEntries {
                calMap[e.hobby, default: 0] += e.durationMinutes
            }

            stats = prefs.resolvedHobbies.map { hobby in
                HobbyStats(
                    label: hobby.label,
                    displayLabel: hobby.displayLabel,
                    color: hobby.color,
                    historicalMinutes: histMap[hobby.label] ?? 0,
                    calendarMinutes: calMap[hobby.label] ?? 0,
                    category: prefMap[hobby.label]
                )
            }.sorted { $0.totalMinutes > $1.totalMinutes }
        } catch {}
        isLoading = false
    }

    func updateHistorical(hobby: String, minutes: Int) async {
        try? await HobbyService.updateHistorical(hobby: hobby, minutes: minutes)
        if let idx = stats.firstIndex(where: { $0.label == hobby }) {
            stats[idx].historicalMinutes = minutes
        }
    }

    func updateCategory(hobby: String, category: String) async {
        try? await HobbyService.updateCategory(hobby: hobby, category: category)
        if let idx = stats.firstIndex(where: { $0.label == hobby }) {
            stats[idx].category = category
        }
    }
}
