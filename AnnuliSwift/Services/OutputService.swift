import Foundation
import Supabase

struct OutputService {

    static func fetchAll() async throws -> [DomainOutput] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("outputs")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
            .value
    }

    static func fetch(domainId: UUID) async throws -> [DomainOutput] {
        guard let userId = AuthService.currentUserId else { return [] }
        return try await supabase
            .from("outputs")
            .select()
            .eq("user_id", value: userId)
            .eq("domain_id", value: domainId)
            .order("date", ascending: false)
            .execute()
            .value
    }

    static func save(form: OutputForm, id: UUID? = nil) async throws -> DomainOutput {
        guard let userId = AuthService.currentUserId else { throw AnnuliError.notAuthenticated }

        if let existingId = id {
            struct Update: Encodable {
                let title, date: String; let count: Int?; let notes: String?
                enum CodingKeys: String, CodingKey { case title, date, count, notes }
            }
            let u = Update(title: form.title, date: form.date, count: form.count,
                           notes: form.notes.isEmpty ? nil : form.notes)
            let updated: [DomainOutput] = try await supabase
                .from("outputs").update(u).eq("id", value: existingId).select().execute().value
            return updated[0]
        } else {
            struct Insert: Encodable {
                let userId: UUID; let domainId: UUID
                let title, date: String; let count: Int?; let notes: String?
                enum CodingKeys: String, CodingKey {
                    case title, date, count, notes
                    case userId   = "user_id"
                    case domainId = "domain_id"
                }
            }
            let i = Insert(userId: userId, domainId: form.domainId, title: form.title,
                           date: form.date, count: form.count,
                           notes: form.notes.isEmpty ? nil : form.notes)
            let created: [DomainOutput] = try await supabase
                .from("outputs").insert(i).select().execute().value
            return created[0]
        }
    }

    static func delete(id: UUID) async throws {
        try await supabase.from("outputs").delete().eq("id", value: id).execute()
    }
}
