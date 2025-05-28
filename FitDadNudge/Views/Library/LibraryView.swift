import SwiftUI

struct LibraryView: View {
    @State private var searchText = ""
    @State private var selectedType: WorkoutType?
    @State private var selectedDifficulty: Workout.Difficulty?
    @State private var showingWorkoutPlayer = false
    @State private var selectedWorkout: Workout?
    
    // Sample workouts - in production, these would come from CloudKit
    let sampleWorkouts = [
        Workout(
            name: "Quick HIIT Blast",
            duration: 180,
            type: .hiit,
            difficulty: .intermediate,
            instructions: ["Jumping jacks - 30s", "Rest - 10s", "Burpees - 30s", "Rest - 10s", "Mountain climbers - 30s"],
            equipment: [.none],
            targetMuscles: [.fullBody, .core]
        ),
        Workout(
            name: "Dad Strength Builder",
            duration: 300,
            type: .strength,
            difficulty: .beginner,
            instructions: ["Push-ups - 45s", "Rest - 15s", "Squats - 45s", "Rest - 15s", "Plank - 45s"],
            equipment: [.none],
            targetMuscles: [.chest, .legs, .core]
        ),
        Workout(
            name: "Morning Energizer",
            duration: 120,
            type: .stretching,
            difficulty: .beginner,
            instructions: ["Neck rolls - 30s", "Arm circles - 30s", "Hip circles - 30s", "Toe touches - 30s"],
            equipment: [.none],
            targetMuscles: [.fullBody]
        ),
        Workout(
            name: "Desk Break Stretch",
            duration: 60,
            type: .stretching,
            difficulty: .beginner,
            instructions: ["Shoulder shrugs - 15s", "Neck stretch - 15s each side", "Wrist circles - 15s"],
            equipment: [.none],
            targetMuscles: [.shoulders, .back]
        ),
        Workout(
            name: "Superhero Training",
            duration: 240,
            type: .dadKid,
            difficulty: .beginner,
            instructions: ["Superhero poses - 1 min", "Bear crawls - 30s", "Frog jumps - 30s", "Dance party - 1 min", "High fives!"],
            equipment: [.none],
            targetMuscles: [.fullBody],
            isDadKidFriendly: true,
            minimumAge: 4
        )
    ]
    
    var filteredWorkouts: [Workout] {
        sampleWorkouts.filter { workout in
            let matchesSearch = searchText.isEmpty || workout.name.localizedCaseInsensitiveContains(searchText)
            let matchesType = selectedType == nil || workout.type == selectedType
            let matchesDifficulty = selectedDifficulty == nil || workout.difficulty == selectedDifficulty
            
            return matchesSearch && matchesType && matchesDifficulty
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search workouts...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Filters
                    VStack(spacing: 12) {
                        // Workout type filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(WorkoutType.allCases, id: \.self) { type in
                                    FilterChip(
                                        title: type.rawValue,
                                        isSelected: selectedType == type,
                                        action: {
                                            withAnimation {
                                                selectedType = selectedType == type ? nil : type
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Difficulty filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Workout.Difficulty.allCases, id: \.self) { difficulty in
                                    FilterChip(
                                        title: difficulty.rawValue,
                                        isSelected: selectedDifficulty == difficulty,
                                        color: Color(difficulty.color),
                                        action: {
                                            withAnimation {
                                                selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Workout list
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Available Workouts")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(filteredWorkouts.count) workouts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if filteredWorkouts.isEmpty {
                            EmptyStateView()
                        } else {
                            ForEach(filteredWorkouts) { workout in
                                WorkoutLibraryCard(workout: workout) {
                                    selectedWorkout = workout
                                    showingWorkoutPlayer = true
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Workout Library")
            .sheet(isPresented: $showingWorkoutPlayer) {
                if let workout = selectedWorkout {
                    WorkoutPlayerView(workout: workout)
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct WorkoutLibraryCard: View {
    let workout: Workout
    let action: () -> Void
    
    var durationText: String {
        let minutes = Int(workout.duration / 60)
        return minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(workout.difficulty.color).opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: workout.type.iconName)
                            .font(.largeTitle)
                            .foregroundColor(Color(workout.difficulty.color))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(durationText) • \(workout.difficulty.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        ForEach(workout.targetMuscles.prefix(2), id: \.self) { muscle in
                            Text(muscle.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if workout.targetMuscles.count > 2 {
                            Text("+\(workout.targetMuscles.count - 2)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack {
                    if workout.isDadKidFriendly {
                        Image(systemName: "figure.2.and.child.holdinghands")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            
            Text("No workouts found")
                .font(.headline)
            
            Text("Try adjusting your filters or search terms")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview
#Preview {
    LibraryView()
} 