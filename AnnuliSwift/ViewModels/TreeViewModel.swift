import SwiftUI
import Combine
import Supabase

@MainActor
class TreeViewModel: ObservableObject {
    @Published var branches: [BranchData] = []
    @Published var isLoading = false
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // Sheet state
    @Published var showAchievementSheet = false
    @Published var showRecordSheet = false
    @Published var selectedAchievement: Achievement?
    @Published var sheetCategory: String = ""

    func load(prefs: PrefsViewModel) async {
        isLoading = true
        do {
            async let hPrefs     = HobbyService.fetchPreferences()
            async let hist       = HobbyService.fetchHistory()
            async let yearEntries = fetchYearEntries()
            async let achievements = AchievementService.fetchAchievements(year: selectedYear)

            let (prefList, histList, yearEnts, achs) = try await (hPrefs, hist, yearEntries, achievements)

            let prefMap = Dictionary(prefList.map { ($0.hobby, $0.category) }, uniquingKeysWith: { $1 })
            let histMap = Dictionary(histList.map { ($0.hobby, $0.historicalMinutes) }, uniquingKeysWith: { $1 })

            // Calendar minutes per hobby for current year
            var calMap: [String: Int] = [:]
            for e in yearEnts { calMap[e.hobby, default: 0] += e.durationMinutes }

            let allCategories = prefs.orderedCategories
            let resolved = prefs.resolvedHobbies

            branches = allCategories.map { cat in
                let catHobbies: [HobbyLeaf] = resolved
                    .filter { prefMap[$0.label] == cat }
                    .map { h in
                        let mins = (histMap[h.label] ?? 0) + (calMap[h.label] ?? 0)
                        return HobbyLeaf(label: h.label, displayLabel: h.displayLabel,
                                         color: h.color, totalMinutes: mins,
                                         isInactive: prefs.inactiveHobbies.contains(h.label))
                    }
                let catAchs = achs.filter { $0.category == cat && $0.parentId == nil }
                let maxMins = catHobbies.map(\.totalMinutes).max() ?? 1
                return BranchData(category: cat, displayName: prefs.displayName(for: cat),
                                   hobbies: catHobbies, achievements: catAchs, maxMinutes: maxMins)
            }
        } catch {}
        isLoading = false
    }

    private func fetchYearEntries() async throws -> [TimeEntry] {
        guard let userId = AuthService.currentUserId else { return [] }
        let yearPrefix = "\(selectedYear)"
        return try await supabase
            .from("time_entries").select()
            .eq("user_id", value: userId)
            .like("date", pattern: "\(yearPrefix)-%")
            .execute().value
    }

    // MARK: - Achievement CRUD

    func addAchievement(insert: AchievementInsert) async {
        guard let ach = try? await AchievementService.add(insert) else { return }
        appendAchievementToBranch(ach)
    }

    func deleteAchievement(id: UUID) async {
        try? await AchievementService.delete(id: id)
        removeAchievementFromBranch(id: id)
    }

    func renameAchievement(id: UUID, name: String) async {
        try? await AchievementService.rename(id: id, name: name)
        updateAchievementInBranch(id: id) { $0.name = name }
    }

    func archiveAchievement(id: UUID) async {
        try? await AchievementService.archive(id: id)
        updateAchievementInBranch(id: id) { $0.archivedAt = ISO8601DateFormatter().string(from: Date()) }
    }

    func unarchiveAchievement(id: UUID) async {
        try? await AchievementService.unarchive(id: id)
        updateAchievementInBranch(id: id) { $0.archivedAt = nil }
    }

    func updateAchievementTarget(id: UUID, value: Double) async {
        try? await AchievementService.updateTarget(id: id, targetValue: value)
        updateAchievementInBranch(id: id) { $0.targetValue = value }
    }

    func addRecord(_ insert: AchievementRecordInsert, to achievementId: UUID) async {
        guard let rec = try? await AchievementService.addRecord(insert) else { return }
        updateAchievementInBranch(id: achievementId) { $0.records.append(rec) }
    }

    func deleteRecord(id: UUID, from achievementId: UUID) async {
        try? await AchievementService.deleteRecord(id: id)
        updateAchievementInBranch(id: achievementId) { ach in
            ach.records.removeAll { $0.id == id }
        }
    }

    // MARK: - Branch mutation helpers

    private func appendAchievementToBranch(_ ach: Achievement) {
        for i in branches.indices where branches[i].category == ach.category {
            branches[i].achievements.append(ach)
        }
    }

    private func removeAchievementFromBranch(id: UUID) {
        for i in branches.indices {
            branches[i].achievements.removeAll { $0.id == id }
        }
    }

    private func updateAchievementInBranch(id: UUID, mutation: (inout Achievement) -> Void) {
        for i in branches.indices {
            if let j = branches[i].achievements.firstIndex(where: { $0.id == id }) {
                mutation(&branches[i].achievements[j])
            }
        }
    }
}
