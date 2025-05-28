import SwiftUI

// MARK: - App State
@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showingOnboarding = false
    @Published var hasCompletedOnboarding = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingWorkoutPlayer = false
    @Published var pendingWorkout: Workout?
    
    // MARK: - Tab Enum
    enum Tab: Int, CaseIterable {
        case home = 0
        case streaks = 1
        case library = 2
        case kids = 3
        case settings = 4
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .streaks: return "Progress"
            case .library: return "Library"
            case .kids: return "Kids"
            case .settings: return "Settings"
            }
        }
        
        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .streaks: return "flame.fill"
            case .library: return "books.vertical.fill"
            case .kids: return "figure.2.and.child.holdinghands"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    // MARK: - Methods
    
    func navigateToTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        showingOnboarding = false
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func checkOnboardingStatus() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        showingOnboarding = !hasCompletedOnboarding
    }
    
    func setError(_ error: Error?) {
        self.error = error
    }
    
    func clearError() {
        error = nil
    }
} 