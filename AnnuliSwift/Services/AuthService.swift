import Foundation
import Supabase

struct AuthService {
    static func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }

    static func signUp(email: String, password: String) async throws {
        try await supabase.auth.signUp(email: email, password: password)
    }

    static func signOut() async throws {
        try await supabase.auth.signOut()
    }

    static var currentUserId: UUID? {
        supabase.auth.currentUser?.id
    }

    static var currentUser: User? {
        supabase.auth.currentUser
    }
}
