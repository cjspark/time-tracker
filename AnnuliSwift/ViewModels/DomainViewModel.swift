import SwiftUI

@MainActor
class DomainViewModel: ObservableObject {
    @Published var domains: [Domain] = []
    @Published var outputs: [DomainOutput] = []
    @Published var isLoading = false

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
}
