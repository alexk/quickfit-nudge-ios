import SwiftUI
import WatchKit
import HealthKit

struct WorkoutWatchView: View {
    @StateObject private var workoutManager = WatchWorkoutManager()
    @State private var selectedWorkout: Workout?
    
    var body: some View {
        NavigationStack {
            if let activeWorkout = workoutManager.activeWorkout {
                ActiveWorkoutView(workout: activeWorkout, manager: workoutManager)
            } else if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout) {
                    workoutManager.startWorkout(workout)
                }
            } else {
                WorkoutListView(onSelect: { workout in
                    selectedWorkout = workout
                })
            }
        }
    }
}

// MARK: - Workout List View
struct WorkoutListView: View {
    let onSelect: (Workout) -> Void
    
    // Sample workouts for watch
    let quickWorkouts = [
        Workout(
            name: "1-Min Breathing",
            duration: 60,
            type: .breathing,
            difficulty: .beginner,
            instructions: ["Deep breath in for 4 counts", "Hold for 4 counts", "Exhale for 4 counts"],
            equipment: [.none],
            targetMuscles: [.core]
        ),
        Workout(
            name: "2-Min Stretch",
            duration: 120,
            type: .stretching,
            difficulty: .beginner,
            instructions: ["Neck rolls", "Shoulder shrugs", "Arm circles", "Torso twists"],
            equipment: [.none],
            targetMuscles: [.fullBody]
        ),
        Workout(
            name: "3-Min HIIT",
            duration: 180,
            type: .hiit,
            difficulty: .intermediate,
            instructions: ["Jumping jacks - 30s", "Rest - 10s", "Burpees - 30s", "Rest - 10s", "Mountain climbers - 30s"],
            equipment: [.none],
            targetMuscles: [.fullBody]
        )
    ]
    
    var body: some View {
        List(quickWorkouts) { workout in
            Button(action: { onSelect(workout) }) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: workout.type.iconName)
                            .foregroundColor(.blue)
                        Text(workout.name)
                            .font(.headline)
                    }
                    
                    Text("\(Int(workout.duration / 60)) minutes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Quick Workouts")
    }
}

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    let workout: Workout
    let onStart: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Workout icon
                Image(systemName: workout.type.iconName)
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Circle())
                
                // Workout info
                VStack(spacing: 8) {
                    Text(workout.name)
                        .font(.headline)
                    
                    HStack {
                        Label("\(Int(workout.duration / 60))m", systemImage: "clock")
                        Text("•")
                        Text(workout.difficulty.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                // Instructions preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(workout.instructions.prefix(3).enumerated()), id: \.offset) { index, instruction in
                        Text("\(index + 1). \(instruction)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if workout.instructions.count > 3 {
                        Text("And \(workout.instructions.count - 3) more...")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                
                // Start button
                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Active Workout View
struct ActiveWorkoutView: View {
    let workout: Workout
    let manager: WatchWorkoutManager
    @State private var showingControls = false
    
    var body: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { _ in
            VStack(spacing: 8) {
                // Timer
                Text(timeString(from: manager.elapsedTime))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: manager.progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: manager.progress)
                }
                .frame(width: 100, height: 100)
                
                // Current instruction
                if let instruction = manager.currentInstruction {
                    Text(instruction)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Controls
                HStack(spacing: 20) {
                    Button(action: manager.togglePause) {
                        Image(systemName: manager.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .background(Color.orange)
                    .clipShape(Circle())
                    
                    Button(action: manager.complete) {
                        Image(systemName: "checkmark")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .background(Color.green)
                    .clipShape(Circle())
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Watch Workout Manager
class WatchWorkoutManager: ObservableObject {
    @Published var activeWorkout: Workout?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused = false
    @Published var currentInstructionIndex = 0
    
    private var startTime: Date?
    private var timer: Timer?
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    
    var progress: Double {
        guard let workout = activeWorkout else { return 0 }
        return min(elapsedTime / workout.duration, 1.0)
    }
    
    var currentInstruction: String? {
        guard let workout = activeWorkout,
              currentInstructionIndex < workout.instructions.count else { return nil }
        return workout.instructions[currentInstructionIndex]
    }
    
    func startWorkout(_ workout: Workout) {
        activeWorkout = workout
        startTime = Date()
        isPaused = false
        elapsedTime = 0
        currentInstructionIndex = 0
        
        startTimer()
        startHealthKitWorkout()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.start)
    }
    
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            timer?.invalidate()
            WKInterfaceDevice.current().play(.stop)
        } else {
            startTimer()
            WKInterfaceDevice.current().play(.start)
        }
    }
    
    func complete() {
        timer?.invalidate()
        
        // Success haptic
        WKInterfaceDevice.current().play(.success)
        
        // Save to HealthKit
        if let workoutSession = workoutSession {
            healthStore.end(workoutSession)
        }
        
        // Clear workout
        activeWorkout = nil
        elapsedTime = 0
        isPaused = false
        currentInstructionIndex = 0
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = self.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
                
                // Update instruction based on time
                if let workout = self.activeWorkout {
                    let instructionDuration = workout.duration / Double(workout.instructions.count)
                    let newIndex = Int(self.elapsedTime / instructionDuration)
                    
                    if newIndex != self.currentInstructionIndex && newIndex < workout.instructions.count {
                        self.currentInstructionIndex = newIndex
                        // Haptic for instruction change
                        WKInterfaceDevice.current().play(.click)
                    }
                    
                    // Auto-complete
                    if self.elapsedTime >= workout.duration {
                        self.complete()
                    }
                }
            }
        }
    }
    
    private func startHealthKitWorkout() {
        // Configure workout
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor
        
        // Create and start session
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            healthStore.start(workoutSession!)
        } catch {
            logError("Failed to start workout session: \(error)", category: .watch)
        }
    }
} 