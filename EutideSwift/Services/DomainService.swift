import Foundation
import Supabase

struct DomainService {

    static func fetchAll() async throws -> [Domain] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("domains")
            .select()
            .eq("user_id", value: userId)
            .order("sort_order")
            .execute()
            .value
    }

    static func create(name: String, color: String, icon: String, sortOrder: Int) async throws -> Domain {
        guard let userId = AuthService.currentUserId else { throw AnnuliError.notAuthenticated }
        struct Insert: Encodable {
            let userId: UUID; let name, color, icon: String; let sortOrder: Int
            enum CodingKeys: String, CodingKey {
                case name, color, icon
                case userId    = "user_id"
                case sortOrder = "sort_order"
            }
        }
        let row = Insert(userId: userId, name: name, color: color, icon: icon, sortOrder: sortOrder)
        let created: [Domain] = try await supabase.from("domains").insert(row).select().execute().value
        return created[0]
    }

    static func update(_ domain: Domain) async throws {
        struct Update: Encodable {
            let name, color, icon: String; let sortOrder: Int
            enum CodingKeys: String, CodingKey {
                case name, color, icon
                case sortOrder = "sort_order"
            }
        }
        let u = Update(name: domain.name, color: domain.color, icon: domain.icon, sortOrder: domain.sortOrder)
        try await supabase.from("domains").update(u).eq("id", value: domain.id).execute()
    }

    static func reorder(_ domains: [Domain]) async throws {
        for (i, d) in domains.enumerated() {
            var updated = d; updated.sortOrder = i
            try await update(updated)
        }
    }

    static func delete(id: UUID) async throws {
        try await supabase.from("domains").delete().eq("id", value: id).execute()
    }
}
