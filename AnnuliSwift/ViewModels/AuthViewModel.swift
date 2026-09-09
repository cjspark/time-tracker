import SwiftUI
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    init() {
        Task { await listenToAuthState() }
    }

    private func listenToAuthState() async {
        isLoading = true
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .initialSession:
                isAuthenticated = session != nil
                isLoading = false
            case .signedIn:
                isAuthenticated = true
            case .signedOut, .userDeleted:
                isAuthenticated = false
            default:
                break
            }
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            try await AuthService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        errorMessage = nil
        do {
            try await AuthService.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        try? await AuthService.signOut()
    }

    func resetPassword(email: String) async -> Bool {
        errorMessage = nil
        do {
            try await AuthService.resetPassword(email: email)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
