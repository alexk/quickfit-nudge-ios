import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ForEach(AppState.Tab.allCases, id: \.self) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .tint(.blue)
    }
    
    @ViewBuilder
    private func tabContent(for tab: AppState.Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .streaks:
            StreaksView()
        case .library:
            LibraryView()
        case .kids:
            KidsView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Placeholder Views
// HomeView is now defined in Views/Home/HomeView.swift

// StreaksView is now defined in Views/Gamification/StreaksView.swift

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            Text("Workout Library")
                .navigationTitle("Library")
        }
    }
}

struct KidsView: View {
    var body: some View {
        NavigationStack {
            Text("Kids Activities")
                .navigationTitle("Kids")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings")
                .navigationTitle("Settings")
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AppState())
} 