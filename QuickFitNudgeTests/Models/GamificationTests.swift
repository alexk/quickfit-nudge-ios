import XCTest
@testable import FitDadNudge

final class GamificationTests: XCTestCase {
    
    // MARK: - Streak Tests
    
    func testStreakInitialization() {
        // Given
        let userId = "test-user"
        let type = Streak.StreakType.daily
        
        // When
        let streak = Streak(
            userId: userId,
            type: type,
            currentCount: 5,
            longestCount: 10
        )
        
        // Then
        XCTAssertNotNil(streak.id)
        XCTAssertEqual(streak.userId, userId)
        XCTAssertEqual(streak.type, type)
        XCTAssertEqual(streak.currentCount, 5)
        XCTAssertEqual(streak.longestCount, 10)
    }
    
    func testStreakIsActive() {
        // Given - Active streak (today)
        var activeStreak = Streak(
            userId: "user",
            type: .daily,
            lastActivityDate: Date()
        )
        
        // Then
        XCTAssertTrue(activeStreak.isActive)
        
        // Given - Active streak (yesterday)
        activeStreak.lastActivityDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        // Then
        XCTAssertTrue(activeStreak.isActive)
        
        // Given - Inactive streak (2 days ago)
        activeStreak.lastActivityDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        
        // Then
        XCTAssertFalse(activeStreak.isActive)
    }
    
    func testStreakIncrement() {
        // Given
        var streak = Streak(
            userId: "user",
            type: .daily,
            currentCount: 5,
            longestCount: 10
        )
        
        // When
        streak.incrementStreak()
        
        // Then
        XCTAssertEqual(streak.currentCount, 6)
        XCTAssertEqual(streak.longestCount, 10) // Should not change
        
        // When - Increment past longest
        streak.currentCount = 10
        streak.incrementStreak()
        
        // Then
        XCTAssertEqual(streak.currentCount, 11)
        XCTAssertEqual(streak.longestCount, 11) // Should update
    }
    
    func testStreakReset() {
        // Given
        var streak = Streak(
            userId: "user",
            type: .daily,
            currentCount: 5,
            longestCount: 10
        )
        let originalStartDate = streak.startDate
        
        // When
        Thread.sleep(forTimeInterval: 0.1) // Ensure time difference
        streak.resetStreak()
        
        // Then
        XCTAssertEqual(streak.currentCount, 0)
        XCTAssertEqual(streak.longestCount, 10) // Should not change
        XCTAssertNotEqual(streak.startDate, originalStartDate)
    }
    
    func testStreakTypeProperties() {
        // Test icon names
        XCTAssertEqual(Streak.StreakType.daily.iconName, "flame.fill")
        XCTAssertEqual(Streak.StreakType.weekly.iconName, "calendar.badge.checkmark")
        XCTAssertEqual(Streak.StreakType.familyFriendly.iconName, "figure.2.and.child.holdinghands")
        XCTAssertEqual(Streak.StreakType.earlyBird.iconName, "sunrise.fill")
        XCTAssertEqual(Streak.StreakType.consistency.iconName, "crown.fill")
        
        // Test descriptions
        XCTAssertFalse(Streak.StreakType.daily.description.isEmpty)
        XCTAssertFalse(Streak.StreakType.weekly.description.isEmpty)
    }
    
    // MARK: - Achievement Tests
    
    func testAchievementInitialization() {
        // Given
        let type = Achievement.AchievementType.firstWorkout
        let name = "First Steps"
        let description = "Complete your first workout"
        let iconName = "figure.walk"
        
        // When
        let achievement = Achievement(
            type: type,
            name: name,
            description: description,
            iconName: iconName,
            progress: 0,
            target: 1
        )
        
        // Then
        XCTAssertNotNil(achievement.id)
        XCTAssertEqual(achievement.type, type)
        XCTAssertEqual(achievement.name, name)
        XCTAssertEqual(achievement.description, description)
        XCTAssertEqual(achievement.iconName, iconName)
        XCTAssertNil(achievement.unlockedAt)
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertEqual(achievement.progress, 0)
        XCTAssertEqual(achievement.target, 1)
    }
    
    func testAchievementProgress() {
        // Given
        let achievement = Achievement(
            type: .weekWarrior,
            name: "Week Warrior",
            description: "Complete 7 workouts in a week",
            iconName: "calendar",
            progress: 5,
            target: 7
        )
        
        // Then
        XCTAssertEqual(achievement.progressPercentage, 5.0/7.0, accuracy: 0.01)
        
        // Given - Over 100%
        let overAchievement = Achievement(
            type: .centuryClub,
            name: "Century Club",
            description: "Complete 100 workouts",
            iconName: "100.circle",
            progress: 150,
            target: 100
        )
        
        // Then - Should cap at 1.0
        XCTAssertEqual(overAchievement.progressPercentage, 1.0)
    }
    
    func testAchievementTiers() {
        XCTAssertEqual(Achievement.AchievementType.firstWorkout.tier, .bronze)
        XCTAssertEqual(Achievement.AchievementType.weekWarrior.tier, .silver)
        XCTAssertEqual(Achievement.AchievementType.monthlyMaster.tier, .gold)
        XCTAssertEqual(Achievement.AchievementType.centuryClub.tier, .platinum)
        
        // Test tier colors
        XCTAssertEqual(Achievement.Tier.bronze.color, "brown")
        XCTAssertEqual(Achievement.Tier.silver.color, "gray")
        XCTAssertEqual(Achievement.Tier.gold.color, "yellow")
        XCTAssertEqual(Achievement.Tier.platinum.color, "purple")
    }
    
    // MARK: - Leaderboard Tests
    
    func testLeaderboardEntryInitialization() {
        // Given
        let userId = "user123"
        let userName = "John Doe"
        let score = 1250
        let rank = 1
        let timeframe = LeaderboardEntry.Timeframe.weekly
        
        // When
        let entry = LeaderboardEntry(
            userId: userId,
            userName: userName,
            score: score,
            rank: rank,
            timeframe: timeframe
        )
        
        // Then
        XCTAssertNotNil(entry.id)
        XCTAssertEqual(entry.userId, userId)
        XCTAssertEqual(entry.userName, userName)
        XCTAssertEqual(entry.score, score)
        XCTAssertEqual(entry.rank, rank)
        XCTAssertEqual(entry.timeframe, timeframe)
        XCTAssertNil(entry.userAvatar)
    }
    
    func testLeaderboardTimeframes() {
        XCTAssertEqual(LeaderboardEntry.Timeframe.daily.iconName, "sun.max.fill")
        XCTAssertEqual(LeaderboardEntry.Timeframe.weekly.iconName, "calendar.badge.clock")
        XCTAssertEqual(LeaderboardEntry.Timeframe.monthly.iconName, "calendar.circle.fill")
        XCTAssertEqual(LeaderboardEntry.Timeframe.allTime.iconName, "crown.fill")
    }
    
    // MARK: - Points System Tests
    
    func testPointsCalculation() {
        // Given - Basic workout
        let basicWorkout = Workout(
            name: "Basic",
            duration: 180,
            type: .stretching,
            difficulty: .beginner,
            instructions: ["Stretch"]
        )
        
        // When
        let basicPoints = PointsSystem.calculateWorkoutPoints(
            workout: basicWorkout,
            duration: 180,
            withKid: false
        )
        
        // Then
        XCTAssertEqual(basicPoints, 15) // 10 base + 5 duration bonus
        
        // Given - Advanced workout with kid
        let advancedWorkout = Workout(
            name: "Advanced",
            duration: 300,
            type: .hiit,
            difficulty: .advanced,
            instructions: ["Work hard"]
        )
        
        // When
        let advancedPoints = PointsSystem.calculateWorkoutPoints(
            workout: advancedWorkout,
            duration: 300,
            withKid: true
        )
        
        // Then
        XCTAssertEqual(advancedPoints, 45) // 10 base + 5 duration + 10 difficulty + 20 dad-kid
    }
    
    // MARK: - Challenge Tests
    
    func testChallengeInitialization() {
        // Given
        let name = "7-Day Streak"
        let type = Challenge.ChallengeType.personal
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let targetValue = 7
        let rewardPoints = 100
        
        // When
        let challenge = Challenge(
            name: name,
            description: "Complete workouts for 7 days straight",
            type: type,
            startDate: startDate,
            endDate: endDate,
            targetValue: targetValue,
            rewardPoints: rewardPoints
        )
        
        // Then
        XCTAssertNotNil(challenge.id)
        XCTAssertEqual(challenge.name, name)
        XCTAssertEqual(challenge.type, type)
        XCTAssertEqual(challenge.targetValue, targetValue)
        XCTAssertEqual(challenge.rewardPoints, rewardPoints)
        XCTAssertTrue(challenge.participants.isEmpty)
        XCTAssertTrue(challenge.progress.isEmpty)
    }
    
    func testChallengeActive() {
        // Given - Active challenge
        let activeChallenge = Challenge(
            name: "Active",
            description: "Test",
            type: .personal,
            startDate: Date().addingTimeInterval(-3600), // 1 hour ago
            endDate: Date().addingTimeInterval(3600), // 1 hour from now
            targetValue: 10,
            rewardPoints: 50
        )
        
        // Then
        XCTAssertTrue(activeChallenge.isActive)
        
        // Given - Future challenge
        let futureChallenge = Challenge(
            name: "Future",
            description: "Test",
            type: .personal,
            startDate: Date().addingTimeInterval(3600), // 1 hour from now
            endDate: Date().addingTimeInterval(7200), // 2 hours from now
            targetValue: 10,
            rewardPoints: 50
        )
        
        // Then
        XCTAssertFalse(futureChallenge.isActive)
    }
    
    func testChallengeUserProgress() {
        // Given
        var challenge = Challenge(
            name: "Test",
            description: "Test",
            type: .personal,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            targetValue: 10,
            rewardPoints: 50
        )
        
        let userId = "user123"
        challenge.progress[userId] = 5
        
        // When
        let progress = challenge.userProgress(for: userId)
        
        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
        
        // Test unknown user
        XCTAssertEqual(challenge.userProgress(for: "unknown"), 0.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestWorkout() -> Workout {
        return Workout(
            name: "Test Workout",
            duration: 180,
            type: .hiit,
            difficulty: .beginner,
            instructions: ["Do something"],
            equipment: [.none],
            targetMuscles: [.fullBody]
        )
    }
} 