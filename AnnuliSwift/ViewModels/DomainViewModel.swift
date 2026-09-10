import SwiftUI
import Combine
import Supabase

@MainActor
class DomainViewModel: ObservableObject {
    @Published var domains: [Domain] = []
    @Published var outputs: [DomainOutput] = []
    @Published var hobbyMinutes: [String: Int] = [:]   // label → minutes for selectedYear
    @Published var efficiencyMap: [String: String] = [:]  // "domainId_year" → label
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var isLoading = false

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let d = DomainService.fetchAll()
            async let o = OutputService.fetchAll()
            let (dd, oo) = try await (d, o)
            domains = dd
            outputs = oo
        } catch {}
    }

    func loadStats(prefs: PrefsViewModel) async {
        do {
            guard let userId = AuthService.currentUserId else { return }
            let yearEntries: [TimeEntry] = try await supabase
                .from("time_entries").select()
                .eq("user_id", value: userId)
                .like("date", pattern: "\(selectedYear)-%")
                .execute().value

            var map: [String: Int] = [:]
            for e in yearEntries { map[e.hobby, default: 0] += e.durationMinutes }
            hobbyMinutes = map
        } catch {}

        efficiencyMap = await PrefsService.shared.get(
            .domainEfficiency, as: [String: String].self, fallback: [:]
        )
    }

    // MARK: - Domain CRUD

    func createDomain(name: String, color: String) async throws {
        let d = try await DomainService.create(
            name: name, color: color, icon: "circle.fill", sortOrder: domains.count
        )
        domains.append(d)
    }

    func updateDomain(_ domain: Domain) async throws {
        try await DomainService.update(domain)
        if let i = domains.firstIndex(where: { $0.id == domain.id }) { domains[i] = domain }
    }

    func deleteDomain(_ domain: Domain) async throws {
        try await DomainService.delete(id: domain.id)
        domains.removeAll { $0.id == domain.id }
        outputs.removeAll { $0.domainId == domain.id }
    }

    // MARK: - Output CRUD

    func addOutput(form: OutputForm) async throws {
        let o = try await OutputService.save(form: form)
        outputs.append(o)
    }

    func updateOutput(_ output: DomainOutput, form: OutputForm) async throws {
        let updated = try await OutputService.save(form: form, id: output.id)
        if let i = outputs.firstIndex(where: { $0.id == output.id }) { outputs[i] = updated }
    }

    func deleteOutput(_ output: DomainOutput) async throws {
        try await OutputService.delete(id: output.id)
        outputs.removeAll { $0.id == output.id }
    }

    func outputs(for domainId: UUID) -> [DomainOutput] {
        outputs.filter { $0.domainId == domainId }.sorted { $0.date > $1.date }
    }

    // MARK: - Efficiency annotation

    func efficiency(for domainId: UUID, year: Int) -> String? {
        let v = efficiencyMap["\(domainId.uuidString)_\(year)"] ?? ""
        return v.isEmpty ? nil : v
    }

    func setEfficiency(_ label: String, for domainId: UUID, year: Int) async {
        let key = "\(domainId.uuidString)_\(year)"
        if label.isEmpty { efficiencyMap.removeValue(forKey: key) }
        else             { efficiencyMap[key] = label }
        await PrefsService.shared.set(.domainEfficiency, value: efficiencyMap)
    }
}
