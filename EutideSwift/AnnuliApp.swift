import SwiftUI

@main
struct AnnuliApp: App {
    @StateObject private var auth  = AuthViewModel()
    @StateObject private var prefs = PrefsViewModel.shared
    @StateObject private var timer = TimerViewModel()

    init() {
        // 全局外壳：暖米导航栏 + 卡片色标签栏（Eutide 莫兰迪基调）
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(EU.bgPage)
        nav.shadowColor = UIColor(EU.borderSoft)
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(EU.bgCard)
        tab.shadowColor = UIColor(EU.borderSoft)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }

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
            .tint(EU.accent)
            .animation(.easeInOut(duration: 0.25), value: auth.isAuthenticated)
            .animation(.easeInOut(duration: 0.25), value: auth.isResettingPassword)
            .onOpenURL { url in
                Task { await auth.handleDeepLink(url: url) }
            }
        }
    }
}
