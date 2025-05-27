import XCTest
@testable import FitDadNudge

final class WorkoutTests: XCTestCase {
    
    // MARK: - Workout Model Tests
    
    func testWorkoutInitialization() {
        // Given
        let id = UUID()
        let name = "Test HIIT"
        let duration: TimeInterval = 180
        let type = WorkoutType.hiit
        let difficulty = Workout.Difficulty.intermediate
        let instructions = ["Jump", "Rest", "Repeat"]
        
        // When
        let workout = Workout(
            id: id,
            name: name,
            duration: duration,
            type: type,
            difficulty: difficulty,
            instructions: instructions
        )
        
        // Then
        XCTAssertEqual(workout.id, id)
        XCTAssertEqual(workout.name, name)
        XCTAssertEqual(workout.duration, duration)
        XCTAssertEqual(workout.type, type)
        XCTAssertEqual(workout.difficulty, difficulty)
        XCTAssertEqual(workout.instructions, instructions)
        XCTAssertNil(workout.gifURL)
        XCTAssertNil(workout.videoURL)
        XCTAssertTrue(workout.equipment.isEmpty)
        XCTAssertTrue(workout.targetMuscles.isEmpty)
        XCTAssertFalse(workout.isDadKidFriendly)
        XCTAssertNil(workout.minimumAge)
    }
    
    func testWorkoutTypeIconNames() {
        XCTAssertEqual(WorkoutType.hiit.iconName, "bolt.fill")
        XCTAssertEqual(WorkoutType.stretching.iconName, "figure.flexibility")
        XCTAssertEqual(WorkoutType.strength.iconName, "dumbbell.fill")
        XCTAssertEqual(WorkoutType.cardio.iconName, "heart.circle.fill")
        XCTAssertEqual(WorkoutType.dadKid.iconName, "figure.2.and.child.holdinghands")
        XCTAssertEqual(WorkoutType.breathing.iconName, "wind")
    }
    
    func testWorkoutTypeRecommendedDuration() {
        XCTAssertEqual(WorkoutType.hiit.recommendedDuration, 3)
        XCTAssertEqual(WorkoutType.stretching.recommendedDuration, 5)
        XCTAssertEqual(WorkoutType.strength.recommendedDuration, 5)
        XCTAssertEqual(WorkoutType.cardio.recommendedDuration, 3)
        XCTAssertEqual(WorkoutType.dadKid.recommendedDuration, 5)
        XCTAssertEqual(WorkoutType.breathing.recommendedDuration, 1)
    }
    
    func testDifficultyColors() {
        XCTAssertEqual(Workout.Difficulty.beginner.color, "green")
        XCTAssertEqual(Workout.Difficulty.intermediate.color, "orange")
        XCTAssertEqual(Workout.Difficulty.advanced.color, "red")
    }
    
    // MARK: - Workout Session Tests
    
    func testWorkoutSessionInitialization() {
        // Given
        let workout = createTestWorkout()
        
        // When
        let session = WorkoutSession(workout: workout)
        
        // Then
        XCTAssertEqual(session.workout.id, workout.id)
        XCTAssertNil(session.startTime)
        XCTAssertEqual(session.elapsedTime, 0)
        XCTAssertFalse(session.isPaused)
        XCTAssertFalse(session.isComplete)
        XCTAssertEqual(session.currentInstructionIndex, 0)
    }
    
    func testWorkoutSessionProgress() {
        // Given
        let workout = createTestWorkout()
        let session = WorkoutSession(workout: workout)
        
        // When
        session.elapsedTime = 90 // Half of 180 seconds
        
        // Then
        XCTAssertEqual(session.progress, 0.5, accuracy: 0.01)
        XCTAssertEqual(session.remainingTime, 90, accuracy: 0.01)
    }
    
    func testWorkoutSessionInstructionNavigation() {
        // Given
        let workout = createTestWorkout()
        let session = WorkoutSession(workout: workout)
        
        // Then - Initial state
        XCTAssertEqual(session.currentInstruction, "Jump for 30 seconds")
        XCTAssertEqual(session.currentInstructionIndex, 0)
        
        // When - Next instruction
        session.nextInstruction()
        
        // Then
        XCTAssertEqual(session.currentInstruction, "Rest for 10 seconds")
        XCTAssertEqual(session.currentInstructionIndex, 1)
        
        // When - Previous instruction
        session.previousInstruction()
        
        // Then
        XCTAssertEqual(session.currentInstruction, "Jump for 30 seconds")
        XCTAssertEqual(session.currentInstructionIndex, 0)
        
        // When - Try to go before first
        session.previousInstruction()
        
        // Then - Should stay at first
        XCTAssertEqual(session.currentInstructionIndex, 0)
        
        // When - Go to last
        session.currentInstructionIndex = 2
        session.nextInstruction()
        
        // Then - Should stay at last
        XCTAssertEqual(session.currentInstructionIndex, 2)
    }
    
    // MARK: - Workout Completion Tests
    
    func testWorkoutCompletionInitialization() {
        // Given
        let workoutId = UUID()
        let userId = "test-user"
        let duration: TimeInterval = 180
        
        // When
        let completion = WorkoutCompletion(
            workoutId: workoutId,
            userId: userId,
            duration: duration
        )
        
        // Then
        XCTAssertNotNil(completion.id)
        XCTAssertEqual(completion.workoutId, workoutId)
        XCTAssertEqual(completion.userId, userId)
        XCTAssertEqual(completion.duration, duration)
        XCTAssertNil(completion.caloriesBurned)
        XCTAssertNil(completion.heartRate)
        XCTAssertNil(completion.notes)
        XCTAssertFalse(completion.withKid)
        XCTAssertNil(completion.kidId)
    }
    
    // MARK: - Helper Methods
    
    private func createTestWorkout() -> Workout {
        return Workout(
            name: "Test HIIT",
            duration: 180,
            type: .hiit,
            difficulty: .beginner,
            instructions: [
                "Jump for 30 seconds",
                "Rest for 10 seconds",
                "Burpees for 30 seconds"
            ],
            equipment: [.none],
            targetMuscles: [.fullBody]
        )
    }
} 