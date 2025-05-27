import SwiftUI
import AVKit

struct WorkoutPlayerView: View {
    @StateObject private var session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var showingCompletionView = false
    
    init(workout: Workout) {
        _session = StateObject(wrappedValue: WorkoutSession(workout: workout))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: session.progress)
                        .tint(.blue)
                        .scaleEffect(y: 2)
                        .padding(.horizontal)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Timer display
                            TimerView(
                                elapsedTime: session.elapsedTime,
                                remainingTime: session.remainingTime
                            )
                            
                            // Workout GIF/Video
                            WorkoutMediaView(
                                gifURL: session.workout.gifURL,
                                videoURL: session.workout.videoURL
                            )
                            .frame(height: 300)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Current instruction
                            if let instruction = session.currentInstruction {
                                InstructionCard(
                                    instruction: instruction,
                                    index: session.currentInstructionIndex,
                                    total: session.workout.instructions.count,
                                    onPrevious: session.previousInstruction,
                                    onNext: session.nextInstruction
                                )
                                .padding(.horizontal)
                            }
                            
                            // Control buttons
                            WorkoutControlButtons(
                                isPaused: session.isPaused,
                                onStart: session.start,
                                onPause: session.pause,
                                onResume: session.resume,
                                onComplete: {
                                    session.complete()
                                    showingCompletionView = true
                                },
                                hasStarted: session.startTime != nil
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle(session.workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCompletionView) {
                WorkoutCompletionView(
                    workout: session.workout,
                    duration: session.elapsedTime
                )
            }
        }
    }
}

// MARK: - Timer View
struct TimerView: View {
    let elapsedTime: TimeInterval
    let remainingTime: TimeInterval
    
    var body: some View {
        VStack(spacing: 8) {
            Text(timeString(from: elapsedTime))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
            
            HStack(spacing: 20) {
                Label("Elapsed", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Label("\(timeString(from: remainingTime)) left", systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Workout Media View
struct WorkoutMediaView: View {
    let gifURL: String?
    let videoURL: String?
    
    var body: some View {
        Group {
            if let videoURL = videoURL, let url = URL(string: videoURL) {
                VideoPlayer(player: AVPlayer(url: url))
            } else if let gifURL = gifURL {
                AsyncImage(url: URL(string: gifURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                }
            } else {
                // Placeholder animation
                Image(systemName: "figure.run")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            }
        }
    }
}

// MARK: - Instruction Card
struct InstructionCard: View {
    let instruction: String
    let index: Int
    let total: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Step \(index + 1) of \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: onPrevious) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(index == 0 ? .gray : .blue)
                    }
                    .disabled(index == 0)
                    
                    Button(action: onNext) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(index == total - 1 ? .gray : .blue)
                    }
                    .disabled(index == total - 1)
                }
            }
            
            Text(instruction)
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Control Buttons
struct WorkoutControlButtons: View {
    let isPaused: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onComplete: () -> Void
    let hasStarted: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if !hasStarted {
                Button(action: onStart) {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                HStack(spacing: 16) {
                    if isPaused {
                        Button(action: onResume) {
                            Label("Resume", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: onPause) {
                            Label("Pause", systemImage: "pause.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: onComplete) {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Completion View
struct WorkoutCompletionView: View {
    let workout: Workout
    let duration: TimeInterval
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfetti = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Success animation
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .scaleEffect(showingConfetti ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: showingConfetti)
                }
                
                Text("Great Job!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    StatRow(title: "Workout", value: workout.name)
                    StatRow(title: "Duration", value: formatDuration(duration))
                    StatRow(title: "Type", value: workout.type.rawValue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Workout Complete!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    showingConfetti = true
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview
#Preview {
    WorkoutPlayerView(workout: .preview)
}

extension Workout {
    static var preview: Workout {
        Workout(
            name: "Quick HIIT",
            duration: 180,
            type: .hiit,
            difficulty: .beginner,
            instructions: [
                "Start with jumping jacks for 30 seconds",
                "Rest for 10 seconds",
                "Do burpees for 30 seconds",
                "Rest for 10 seconds",
                "Finish with mountain climbers for 30 seconds"
            ],
            equipment: [.none],
            targetMuscles: [.fullBody]
        )
    }
} 