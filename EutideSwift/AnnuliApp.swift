import SwiftUI

@main
struct AnnuliApp: App {
    @StateObject private var auth  = AuthViewModel()
    @StateObject private var prefs = PrefsViewModel.shared
    @StateObject private var timer = TimerViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if auth.isResettingPassword {
                    ResetPasswordView()
                        .environmentObject(auth)
                } else if auth.isAuthenticated {
                    MainTabView()
                        .environmentObject(prefs)
                        .environmentObject(timer)
                        .environmentObject(auth)
                } else {
                    LoginView()
                        .environmentObject(auth)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: auth.isAuthenticated)
            .animation(.easeInOut(duration: 0.25), value: auth.isResettingPassword)
            .onOpenURL { url in
                Task { await auth.handleDeepLink(url: url) }
            }
        }
    }
}
