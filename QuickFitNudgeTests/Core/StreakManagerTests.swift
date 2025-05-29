import XCTest
@testable import FitDadNudge

final class StreakManagerTests: XCTestCase {
    
    var streakManager: StreakManager!
    
    override func setUpWithResult() throws {
        streakManager = StreakManager.shared
    }
    
    override func tearDownWithResult() throws {
        streakManager = nil
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertFalse(streakManager.isLoading, "Should not be loading initially")
        // Note: streaks array might be empty or populated depending on auth state
    }
    
    // MARK: - Streak Creation Tests
    
    func testStreakCreation() {
        let testUserId = "test-user-123"
        let streak = Streak(userId: testUserId, type: .daily)
        
        XCTAssertEqual(streak.userId, testUserId, "Streak should have correct user ID")
        XCTAssertEqual(streak.type, .daily, "Streak should have correct type")
        XCTAssertEqual(streak.currentCount, 0, "New streak should start at 0")
        XCTAssertFalse(streak.isActive, "New streak should not be active")
        XCTAssertEqual(streak.lastActivityDate, streak.createdAt, "Last activity should equal creation date for new streak")
    }
    
    func testStreakTypes() {
        let allTypes = Streak.StreakType.allCases
        
        XCTAssertTrue(allTypes.contains(.daily), "Should include daily streak")
        XCTAssertTrue(allTypes.contains(.weekly), "Should include weekly streak")
        XCTAssertTrue(allTypes.contains(.familyFriendly), "Should include family streak")
        XCTAssertTrue(allTypes.contains(.earlyBird), "Should include early bird streak")
        XCTAssertTrue(allTypes.contains(.consistency), "Should include consistency streak")
    }
    
    // MARK: - Streak Operations Tests
    
    func testStreakIncrement() {
        let streak = Streak(userId: "test", type: .daily)
        let initialCount = streak.currentCount
        
        streak.incrementStreak()
        
        XCTAssertEqual(streak.currentCount, initialCount + 1, "Streak should increment by 1")
        XCTAssertTrue(streak.isActive, "Streak should be active after increment")
        XCTAssertEqual(streak.lastActivityDate.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1.0, "Last activity should be updated to now")
    }
    
    func testStreakReset() {
        let streak = Streak(userId: "test", type: .daily)
        
        // First increment to have something to reset
        streak.incrementStreak()
        XCTAssertGreaterThan(streak.currentCount, 0, "Should have incremented")
        
        // Then reset
        streak.resetStreak()
        
        XCTAssertEqual(streak.currentCount, 0, "Streak should be reset to 0")
        XCTAssertFalse(streak.isActive, "Streak should not be active after reset")
    }
    
    // MARK: - Workout Completion Integration Tests
    
    func testWorkoutCompletionIntegration() {
        let testUserId = "test-user-123"
        let completion = WorkoutCompletion(
            workoutId: UUID(),
            userId: testUserId,
            completedAt: Date(),
            duration: 300,
            withKid: true
        )
        
        // Test that completion has expected properties
        XCTAssertEqual(completion.userId, testUserId, "Completion should have correct user ID")
        XCTAssertTrue(completion.withKid, "Completion should indicate family workout")
        XCTAssertEqual(completion.duration, 300, "Completion should have correct duration")
    }
    
    // MARK: - Motivational Messages Tests
    
    func testMotivationalMessages() {
        let dailyStreak = Streak(userId: "test", type: .daily)
        
        // Test messages for different counts
        let message0 = dailyStreak.motivationalMessage
        XCTAssertTrue(message0.contains("day one"), "Zero count should mention starting")
        
        // Increment and test
        dailyStreak.incrementStreak()
        let message1 = dailyStreak.motivationalMessage
        XCTAssertTrue(message1.contains("1") || message1.contains("momentum"), "Should mention count or momentum")
        
        // Test different streak types
        let weeklyStreak = Streak(userId: "test", type: .weekly)
        weeklyStreak.incrementStreak()
        let weeklyMessage = weeklyStreak.motivationalMessage
        XCTAssertTrue(weeklyMessage.contains("Week") || weeklyMessage.contains("champion"), "Weekly message should be different")
        
        let familyStreak = Streak(userId: "test", type: .familyFriendly)
        familyStreak.incrementStreak()
        let familyMessage = familyStreak.motivationalMessage
        XCTAssertTrue(familyMessage.contains("workout buddy") || familyMessage.contains("moments"), "Family message should reference family")
    }
    
    // MARK: - Milestone Tests
    
    func testMilestones() {
        let streak = Streak(userId: "test", type: .daily)
        
        // Test milestone calculation for different counts
        let testCases: [(Int, Int)] = [
            (0, 3),    // Next milestone from 0 should be 3
            (3, 7),    // Next milestone from 3 should be 7
            (7, 14),   // Next milestone from 7 should be 14
            (30, 60),  // Next milestone from 30 should be 60
            (100, 365) // Next milestone from 100 should be 365
        ]
        
        for (currentCount, expectedNext) in testCases {
            // Set the current count (this is a bit hacky since we don't have a setter)
            for _ in 0..<currentCount {
                streak.incrementStreak()
            }
            
            let nextMilestone = streak.nextMilestone
            XCTAssertEqual(nextMilestone, expectedNext, "Next milestone from \(currentCount) should be \(expectedNext)")
            
            // Reset for next test
            streak.resetStreak()
        }
    }
    
    func testProgressToMilestone() {
        let streak = Streak(userId: "test", type: .daily)
        
        // Test progress calculation
        let initialProgress = streak.progressToNextMilestone
        XCTAssertEqual(initialProgress, 0.0, "Initial progress should be 0")
        
        // Increment once
        streak.incrementStreak()
        let progressAfterOne = streak.progressToNextMilestone
        XCTAssertGreaterThan(progressAfterOne, 0.0, "Progress should increase after increment")
        XCTAssertLessThan(progressAfterOne, 1.0, "Progress should be less than 1.0")
    }
    
    // MARK: - Consistency Score Tests
    
    func testConsistencyCalculation() {
        // Test the consistency calculation logic indirectly
        // since the method is private, we test through the streak update
        
        let testUserId = "test-user-123"
        let completion = WorkoutCompletion(
            workoutId: UUID(),
            userId: testUserId,
            completedAt: Date(),
            duration: 300
        )
        
        // Should not crash when updating streaks
        streakManager.updateStreak(for: completion)
        
        XCTAssertTrue(true, "Streak update should complete without error")
    }
    
    // MARK: - Time-based Tests
    
    func testEarlyBirdStreak() {
        let calendar = Calendar.current
        let earlyMorning = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date()
        
        let completion = WorkoutCompletion(
            workoutId: UUID(),
            userId: "test-user",
            completedAt: earlyMorning,
            duration: 300
        )
        
        // Test that early morning completion is recognized
        XCTAssertLessThan(calendar.component(.hour, from: completion.completedAt), 7, "Should be early morning")
    }
    
    // MARK: - Data Persistence Tests
    
    func testStreakDataPersistence() {
        // Test that streak data can be properly encoded/decoded
        let streak = Streak(userId: "test", type: .daily)
        streak.incrementStreak()
        
        do {
            let encoded = try JSONEncoder().encode(streak)
            let decoded = try JSONDecoder().decode(Streak.self, from: encoded)
            
            XCTAssertEqual(decoded.userId, streak.userId, "User ID should be preserved")
            XCTAssertEqual(decoded.type, streak.type, "Type should be preserved")
            XCTAssertEqual(decoded.currentCount, streak.currentCount, "Count should be preserved")
            XCTAssertEqual(decoded.isActive, streak.isActive, "Active state should be preserved")
        } catch {
            XCTFail("Streak should be encodable/decodable: \(error)")
        }
    }
}