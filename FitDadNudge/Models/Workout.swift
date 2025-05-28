import Foundation

// MARK: - Workout Type
enum WorkoutType: String, Codable, CaseIterable {
    case hiit = "HIIT"
    case stretching = "Stretching"
    case strength = "Strength"
    case cardio = "Cardio"
    case dadKid = "Family Challenge"
    case breathing = "Breathing"
    
    var iconName: String {
        switch self {
        case .hiit: return "bolt.fill"
        case .stretching: return "figure.flexibility"
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.circle.fill"
        case .dadKid: return "figure.2.and.child.holdinghands"
        case .breathing: return "wind"
        }
    }
    
    var recommendedDuration: Int {
        switch self {
        case .hiit: return 3
        case .stretching: return 5
        case .strength: return 5
        case .cardio: return 3
        case .dadKid: return 5
        case .breathing: return 1
        }
    }
}

// MARK: - Workout Model
struct Workout: Identifiable, Codable {
    let id: UUID
    let name: String
    let duration: TimeInterval
    let type: WorkoutType
    let difficulty: Difficulty
    let instructions: [String]
    let gifURL: String?
    let videoURL: String?
    let equipment: [Equipment]
    let targetMuscles: [MuscleGroup]
    let isFamilyFriendly: Bool
    let minimumAge: Int?
    
    init(
        id: UUID = UUID(),
        name: String,
        duration: TimeInterval,
        type: WorkoutType,
        difficulty: Difficulty,
        instructions: [String],
        gifURL: String? = nil,
        videoURL: String? = nil,
        equipment: [Equipment] = [],
        targetMuscles: [MuscleGroup] = [],
        isFamilyFriendly: Bool = false,
        minimumAge: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.type = type
        self.difficulty = difficulty
        self.instructions = instructions
        self.gifURL = gifURL
        self.videoURL = videoURL
        self.equipment = equipment
        self.targetMuscles = targetMuscles
        self.isFamilyFriendly = isFamilyFriendly
        self.minimumAge = minimumAge
    }
    
    enum Difficulty: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        
        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }
    
    enum Equipment: String, Codable, CaseIterable {
        case none = "No Equipment"
        case dumbbell = "Dumbbell"
        case resistanceBand = "Resistance Band"
        case kettlebell = "Kettlebell"
        case pullupBar = "Pull-up Bar"
        case mat = "Exercise Mat"
        case ball = "Exercise Ball"
        case chair = "Chair"
        
        var iconName: String {
            switch self {
            case .none: return "figure.stand"
            case .dumbbell: return "dumbbell.fill"
            case .resistanceBand: return "lasso"
            case .kettlebell: return "scalemass.fill"
            case .pullupBar: return "arrow.up.and.down"
            case .mat: return "rectangle.fill"
            case .ball: return "circle.fill"
            case .chair: return "chair.fill"
            }
        }
    }
    
    enum MuscleGroup: String, Codable, CaseIterable {
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case arms = "Arms"
        case core = "Core"
        case legs = "Legs"
        case glutes = "Glutes"
        case fullBody = "Full Body"
        
        var iconName: String {
            switch self {
            case .chest: return "figure.arms.open"
            case .back: return "figure.walk"
            case .shoulders: return "figure.wave"
            case .arms: return "figure.strengthtraining.traditional"
            case .core: return "figure.core.training"
            case .legs: return "figure.run"
            case .glutes: return "figure.jumprope"
            case .fullBody: return "figure.mixed.cardio"
            }
        }
    }
}

// MARK: - Workout Completion
struct WorkoutCompletion: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let userId: String
    let completedAt: Date
    let duration: TimeInterval
    let caloriesBurned: Int?
    let heartRate: HeartRateData?
    let notes: String?
    let withKid: Bool
    let kidId: String?
    
    init(
        id: UUID = UUID(),
        workoutId: UUID,
        userId: String,
        completedAt: Date = Date(),
        duration: TimeInterval,
        caloriesBurned: Int? = nil,
        heartRate: HeartRateData? = nil,
        notes: String? = nil,
        withKid: Bool = false,
        kidId: String? = nil
    ) {
        self.id = id
        self.workoutId = workoutId
        self.userId = userId
        self.completedAt = completedAt
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.heartRate = heartRate
        self.notes = notes
        self.withKid = withKid
        self.kidId = kidId
    }
}

// MARK: - Heart Rate Data
struct HeartRateData: Codable {
    let average: Int
    let max: Int
    let min: Int
    let samples: [HeartRateSample]
}

struct HeartRateSample: Codable {
    let timestamp: Date
    let value: Int
}

// MARK: - Workout Session
class WorkoutSession: ObservableObject {
    @Published var workout: Workout
    @Published var startTime: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused = false
    @Published var isComplete = false
    @Published var currentInstructionIndex = 0
    
    private var timer: Timer?
    
    init(workout: Workout) {
        self.workout = workout
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func start() {
        startTime = Date()
        isPaused = false
        startTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
    }
    
    func resume() {
        isPaused = false
        startTimer()
    }
    
    func complete() {
        isComplete = true
        timer?.invalidate()
    }
    
    func nextInstruction() {
        if currentInstructionIndex < workout.instructions.count - 1 {
            currentInstructionIndex += 1
        }
    }
    
    func previousInstruction() {
        if currentInstructionIndex > 0 {
            currentInstructionIndex -= 1
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let startTime = self.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
                
                // Auto-complete if we've reached the workout duration
                if self.elapsedTime >= self.workout.duration {
                    self.complete()
                }
            }
        }
    }
    
    var progress: Double {
        guard workout.duration > 0 else { return 0 }
        return min(elapsedTime / workout.duration, 1.0)
    }
    
    var remainingTime: TimeInterval {
        max(workout.duration - elapsedTime, 0)
    }
    
    var currentInstruction: String? {
        guard currentInstructionIndex < workout.instructions.count else { return nil }
        return workout.instructions[currentInstructionIndex]
    }
} 