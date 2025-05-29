import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .unknown, .loading:
                LoadingView()
            case .unauthenticated:
                AuthenticationView()
            case .authenticated:
                if appState.showingOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            }
        }
        .animation(.easeInOut, value: authManager.authState)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.gray).opacity(0.1))
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(AppState())
} 