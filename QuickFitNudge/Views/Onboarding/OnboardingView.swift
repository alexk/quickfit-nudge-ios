import SwiftUI
import EventKit
import HealthKit
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomeView()
                .tag(0)
            
            CalendarPermissionView()
                .tag(1)
            
            NotificationPermissionView()
                .tag(2)
            
            HealthKitPermissionView()
                .tag(3)
            
            ReadyView {
                appState.showingOnboarding = false
            }
            .tag(4)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 15) {
                Text("Welcome to QuickFit Nudge")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Stay fit with micro-workouts that fit into your busy schedule")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                
                Text("Swipe to continue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Calendar Permission
struct CalendarPermissionView: View {
    @State private var permissionGranted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 15) {
                Text("Calendar Access")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("We'll find workout gaps in your calendar and suggest the perfect times to exercise")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: requestCalendarPermission) {
                Label("Grant Calendar Access", systemImage: "calendar")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(permissionGranted ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .disabled(permissionGranted)
            
            if permissionGranted {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
    }
    
    private func requestCalendarPermission() {
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    permissionGranted = granted
                }
            }
        } else {
            // iOS 16 and earlier
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    permissionGranted = granted
                }
            }
        }
    }
}

// MARK: - Notification Permission
struct NotificationPermissionView: View {
    @State private var permissionGranted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 100))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 15) {
                Text("Smart Notifications")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Get nudged at the perfect time to squeeze in a quick workout")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: requestNotificationPermission) {
                Label("Enable Notifications", systemImage: "bell")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(permissionGranted ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .disabled(permissionGranted)
            
            if permissionGranted {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                permissionGranted = granted
            }
        }
    }
}

// MARK: - HealthKit Permission
struct HealthKitPermissionView: View {
    @State private var permissionGranted = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.fill")
                .font(.system(size: 100))
                .foregroundStyle(.red.gradient)
            
            VStack(spacing: 15) {
                Text("Health Integration")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track your workouts and see your fitness progress (optional)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: requestHealthKitPermission) {
                    Label("Connect to Health", systemImage: "heart")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(permissionGranted ? Color.green : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(permissionGranted)
                
                Button(action: { permissionGranted = true }) {
                    Text("Skip for now")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 40)
            
            if permissionGranted {
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
    }
    
    private func requestHealthKitPermission() {
        // HealthKit permission will be implemented in a future milestone
        permissionGranted = true
    }
}

// MARK: - Ready View
struct ReadyView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green.gradient)
            
            VStack(spacing: 15) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let's find your first workout gap and get moving")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(AppState())
} 