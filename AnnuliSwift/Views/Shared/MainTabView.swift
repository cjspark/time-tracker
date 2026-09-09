import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var prefs: PrefsViewModel
    @EnvironmentObject var timer: TimerViewModel

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                CalendarRootView()
                    .tabItem { Label("日历", systemImage: "calendar") }

                TreeRootView()
                    .tabItem { Label("生命树", systemImage: "tree") }

                HobbiesRootView()
                    .tabItem { Label("活动", systemImage: "heart.circle") }

                ReviewRootView()
                    .tabItem { Label("复盘", systemImage: "chart.bar") }
            }

            // Timer bar floats above tab bar
            TimerBarView()
        }
        .task { await prefs.load() }
    }
}
