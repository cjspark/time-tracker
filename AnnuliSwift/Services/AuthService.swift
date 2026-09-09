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

    static func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "annuli://reset-password")!
        )
    }

    static func handleSession(from url: URL) async throws {
        try await supabase.auth.session(from: url)
    }

    static func updatePassword(_ newPassword: String) async throws {
        try await supabase.auth.update(user: UserAttributes(password: newPassword))
    }

    static var currentUserId: UUID? {
        supabase.auth.currentUser?.id
    }

    static var currentUser: User? {
        supabase.auth.currentUser
    }
}
