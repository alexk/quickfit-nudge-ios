import SwiftUI

struct HomeView: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingWorkoutPlayer = false
    @State private var selectedWorkout: Workout?
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    WelcomeHeader(userName: authManager.currentUser?.displayName ?? "Dad")
                    
                    // Next gap card
                    if let nextGap = calendarManager.upcomingGaps.first {
                        NextGapCard(gap: nextGap) {
                            selectedWorkout = createWorkoutForGap(nextGap)
                            showingWorkoutPlayer = true
                        }
                    } else {
                        NoGapsCard()
                    }
                    
                    // Quick actions
                    QuickActionsSection()
                    
                    // Recent activity
                    RecentActivitySection()
                    
                    // Daily tip
                    DailyTipCard()
                }
                .padding()
            }
            .navigationTitle("FitDad Nudge")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshGaps()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await refreshGaps()
            }
        }
        .task {
            if calendarManager.hasCalendarAccess {
                await calendarManager.scanForGaps()
            }
        }
        .sheet(isPresented: $showingWorkoutPlayer) {
            if let workout = selectedWorkout {
                WorkoutPlayerView(workout: workout)
            }
        }
        .id(refreshID)
    }
    
    private func refreshGaps() async {
        await calendarManager.refreshGaps()
        refreshID = UUID()
    }
    
    private func createWorkoutForGap(_ gap: CalendarGap) -> Workout {
        // Create a workout based on the gap
        let workoutType = gap.suggestedWorkoutType
        let duration = gap.duration
        
        return Workout(
            name: "\(Int(duration / 60))-Min \(workoutType.rawValue)",
            duration: duration,
            type: workoutType,
            difficulty: .beginner,
            instructions: getInstructionsForType(workoutType, duration: duration),
            equipment: [.none],
            targetMuscles: getTargetMusclesForType(workoutType)
        )
    }
    
    private func getInstructionsForType(_ type: WorkoutType, duration: TimeInterval) -> [String] {
        switch type {
        case .breathing:
            return ["Take a deep breath in for 4 counts", "Hold for 4 counts", "Exhale for 4 counts", "Repeat"]
        case .stretching:
            return ["Neck rolls - 30 seconds", "Shoulder shrugs - 30 seconds", "Arm circles - 30 seconds", "Torso twists - 30 seconds"]
        case .hiit:
            return ["Jumping jacks - 30 seconds", "Rest - 10 seconds", "High knees - 30 seconds", "Rest - 10 seconds", "Burpees - 20 seconds"]
        case .strength:
            return ["Push-ups - 30 seconds", "Rest - 15 seconds", "Squats - 30 seconds", "Rest - 15 seconds", "Plank - 30 seconds"]
        case .cardio:
            return ["March in place - 30 seconds", "Butt kicks - 30 seconds", "Mountain climbers - 30 seconds", "Rest - 30 seconds"]
        case .dadKid:
            return ["Animal walks together", "Dance party - 1 minute", "Balloon keep-up game", "Superhero poses", "Cool down high-fives"]
        }
    }
    
    private func getTargetMusclesForType(_ type: WorkoutType) -> [Workout.MuscleGroup] {
        switch type {
        case .breathing, .stretching:
            return [.fullBody]
        case .hiit, .cardio:
            return [.fullBody, .core]
        case .strength:
            return [.chest, .legs, .core]
        case .dadKid:
            return [.fullBody]
        }
    }
}

// MARK: - Welcome Header
struct WelcomeHeader: View {
    let userName: String
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(userName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                )
        }
    }
}

// MARK: - Next Gap Card
struct NextGapCard: View {
    let gap: CalendarGap
    let onStart: () -> Void
    
    var timeUntilGap: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: gap.startDate, relativeTo: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Workout Gap")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(timeUntilGap)
                        .font(.headline)
                }
                
                Spacer()
                
                // Quality indicator
                Circle()
                    .fill(Color(gap.quality.color).gradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("\(gap.durationInMinutes)")
                            .font(.headline)
                            .foregroundColor(.white)
                    )
            }
            
            Divider()
            
            HStack {
                Image(systemName: gap.suggestedWorkoutType.iconName)
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading) {
                    Text(gap.suggestedWorkoutType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("\(gap.durationInMinutes) minute workout")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onStart) {
                    Text("Start")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
            
            // Time slot
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(gap.startDate, style: .time) - \(gap.endDate, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - No Gaps Card
struct NoGapsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No workout gaps found")
                .font(.headline)
            
            Text("Your calendar is fully booked! Try a quick workout anyway?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {}) {
                Label("Browse Workouts", systemImage: "figure.run")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Quick Actions
struct QuickActionsSection: View {
    let quickWorkouts = [
        QuickAction(icon: "wind", title: "1-Min Breathing", color: .cyan),
        QuickAction(icon: "figure.flexibility", title: "2-Min Stretch", color: .green),
        QuickAction(icon: "bolt.fill", title: "3-Min HIIT", color: .orange),
        QuickAction(icon: "figure.2.and.child.holdinghands", title: "Dad-Kid Fun", color: .purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Workouts")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickWorkouts) { action in
                        QuickActionCard(action: action)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let action: QuickAction
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Circle()
                    .fill(action.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: action.icon)
                            .font(.title2)
                            .foregroundColor(action.color)
                    )
                
                Text(action.title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 80)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Activity
struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                Button("See all") {}
                    .font(.caption)
            }
            
            VStack(spacing: 8) {
                RecentActivityRow(
                    workout: "Morning Stretch",
                    time: "Today, 7:15 AM",
                    duration: "5 min",
                    icon: "figure.flexibility"
                )
                
                RecentActivityRow(
                    workout: "Dad-Kid Dance",
                    time: "Yesterday, 5:30 PM",
                    duration: "3 min",
                    icon: "figure.2.and.child.holdinghands"
                )
            }
        }
    }
}

// MARK: - Recent Activity Row
struct RecentActivityRow: View {
    let workout: String
    let time: String
    let duration: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(workout)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(duration)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Daily Tip
struct DailyTipCard: View {
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Tip")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text("Try doing desk stretches between meetings to stay limber throughout the day!")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Models
struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthenticationManager.shared)
    }
} 