import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    @State private var showingSignOutAlert = false
    
    // Notification settings
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("workoutRemindersEnabled") private var workoutRemindersEnabled = true
    @AppStorage("streakRemindersEnabled") private var streakRemindersEnabled = true
    
    // Workout preferences
    @AppStorage("preferredWorkoutDuration") private var preferredWorkoutDuration = 3
    @AppStorage("includeKidWorkouts") private var includeKidWorkouts = true
    @AppStorage("autoStartWorkouts") private var autoStartWorkouts = false
    
    // Display preferences
    @AppStorage("showWorkoutGifs") private var showWorkoutGifs = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                accountSection
                
                // Subscription Section
                subscriptionSection
                
                // Notifications Section
                notificationsSection
                
                // Workout Preferences Section
                workoutPreferencesSection
                
                // Display Section
                displaySection
                
                // Support Section
                supportSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Section("Account") {
            HStack {
                VStack(alignment: .leading) {
                    Text(authManager.currentUser?.displayName ?? "FitDad User")
                        .font(.headline)
                    Text(authManager.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )
            }
            .padding(.vertical, 4)
            
            Button(action: { showingSignOutAlert = true }) {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                VStack(alignment: .leading) {
                    Text(subscriptionManager.subscriptionStatus.displayName)
                        .font(.headline)
                    
                    if case .premium(let plan) = subscriptionManager.subscriptionStatus {
                        Text("Renews \(plan.rawValue.lowercased())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if !subscriptionManager.subscriptionStatus.isActive {
                    Button("Upgrade") {
                        showingPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
            
            if subscriptionManager.subscriptionStatus.isActive {
                Button(action: {}) {
                    Label("Manage Subscription", systemImage: "creditcard")
                }
            }
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        Section("Notifications") {
            NavigationLink(destination: NotificationSettingsView()) {
                Label("Notification Settings", systemImage: "bell.badge")
            }
            
            Toggle(isOn: $workoutRemindersEnabled) {
                Label("Workout Gap Reminders", systemImage: "clock")
            }
            .disabled(!notificationsEnabled)
            
            Toggle(isOn: $streakRemindersEnabled) {
                Label("Streak Reminders", systemImage: "flame")
            }
            .disabled(!notificationsEnabled)
        }
    }
    
    // MARK: - Workout Preferences Section
    
    private var workoutPreferencesSection: some View {
        Section("Workout Preferences") {
            Picker(selection: $preferredWorkoutDuration) {
                ForEach(1...5, id: \.self) { duration in
                    Text("\(duration) minutes").tag(duration)
                }
            } label: {
                Label("Preferred Duration", systemImage: "timer")
            }
            
            Toggle(isOn: $includeKidWorkouts) {
                Label("Include Dad-Kid Workouts", systemImage: "figure.2.and.child.holdinghands")
            }
            
            Toggle(isOn: $autoStartWorkouts) {
                Label("Auto-Start Workouts", systemImage: "play.circle")
            }
        }
    }
    
    // MARK: - Display Section
    
    private var displaySection: some View {
        Section("Display") {
            Toggle(isOn: $showWorkoutGifs) {
                Label("Show Workout Animations", systemImage: "photo.stack")
            }
            
            Toggle(isOn: $hapticFeedbackEnabled) {
                Label("Haptic Feedback", systemImage: "waveform")
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section("Support") {
            Link(destination: URL(string: "https://fitdadnudge.com/help")!) {
                Label("Help Center", systemImage: "questionmark.circle")
            }
            
            Link(destination: URL(string: "mailto:support@fitdadnudge.com")!) {
                Label("Contact Support", systemImage: "envelope")
            }
            
            Button(action: requestReview) {
                Label("Rate FitDad Nudge", systemImage: "star")
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            
            Link(destination: URL(string: "https://fitdadnudge.com/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            
            Link(destination: URL(string: "https://fitdadnudge.com/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            
            Button(action: shareApp) {
                Label("Share FitDad Nudge", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    // MARK: - Helpers
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/fitdad-nudge/id123456789")!
        let activityVC = UIActivityViewController(
            activityItems: ["Check out FitDad Nudge - micro workouts for busy dads!", url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthenticationManager.shared)
    }
} 