import Foundation
import SwiftUI

@MainActor
final class BadgeEngine: ObservableObject {
    static let shared = BadgeEngine()
    
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var recentlyUnlocked: [Achievement] = []
    @Published private(set) var totalPoints = 0
    
    private let cloudKitManager = CloudKitManager.shared
    private var completionHistory: [WorkoutCompletion] = []
    
    private init() {
        initializeAchievements()
    }
    
    // MARK: - Public Methods
    
    func checkAchievements(for completion: WorkoutCompletion) {
        completionHistory.append(completion)
        
        // Check each achievement
        for index in achievements.indices where !achievements[index].isUnlocked {
            if evaluateAchievement(achievements[index], with: completion) {
                unlockAchievement(at: index)
            }
        }
        
        // Update progress for all achievements
        updateAllProgress()
        
        // Award points
        let points = PointsSystem.calculateWorkoutPoints(
            workout: getWorkout(for: completion) ?? createDefaultWorkout(),
            duration: completion.duration,
            withKid: completion.withKid
        )
        totalPoints += points
    }
    
    func getAchievementsForTier(_ tier: Achievement.Tier) -> [Achievement] {
        achievements.filter { $0.type.tier == tier }
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        achievements.filter { $0.isUnlocked }
    }
    
    func getInProgressAchievements() -> [Achievement] {
        achievements.filter { !$0.isUnlocked && $0.progress > 0 }
    }
    
    // MARK: - Private Methods
    
    private func initializeAchievements() {
        achievements = [
            // Bronze Tier
            Achievement(
                type: .firstWorkout,
                name: "First Steps",
                description: "Complete your first workout",
                iconName: "star.fill",
                target: 1
            ),
            
            // Silver Tier
            Achievement(
                type: .weekWarrior,
                name: "Week Warrior",
                description: "Complete 7 workouts in a week",
                iconName: "calendar.badge.checkmark",
                target: 7
            ),
            Achievement(
                type: .earlyRiser,
                name: "Early Riser",
                description: "Complete 10 workouts before 7 AM",
                iconName: "sunrise.fill",
                target: 10
            ),
            Achievement(
                type: .nightOwl,
                name: "Night Owl",
                description: "Complete 10 workouts after 8 PM",
                iconName: "moon.stars.fill",
                target: 10
            ),
            
            // Gold Tier
            Achievement(
                type: .monthlyMaster,
                name: "Monthly Master",
                description: "Complete 30 workouts in a month",
                iconName: "calendar.circle.fill",
                target: 30
            ),
            Achievement(
                type: .speedDemon,
                name: "Speed Demon",
                description: "Complete 50 workouts under 3 minutes",
                iconName: "bolt.fill",
                target: 50
            ),
            Achievement(
                type: .varietyKing,
                name: "Variety King",
                description: "Try all workout types",
                iconName: "shuffle",
                target: WorkoutType.allCases.count
            ),
            
            // Platinum Tier
            Achievement(
                type: .centuryClub,
                name: "Century Club",
                description: "Complete 100 total workouts",
                iconName: "100.circle.fill",
                target: 100
            ),
            Achievement(
                type: .dadOfTheYear,
                name: "Dad of the Year",
                description: "Complete 50 dad-kid workouts",
                iconName: "figure.2.and.child.holdinghands",
                target: 50
            ),
            Achievement(
                type: .socialButterfly,
                name: "Social Butterfly",
                description: "Invite 10 friends to join",
                iconName: "person.3.fill",
                target: 10
            )
        ]
    }
    
    private func evaluateAchievement(_ achievement: Achievement, with completion: WorkoutCompletion) -> Bool {
        switch achievement.type {
        case .firstWorkout:
            return completionHistory.count >= 1
            
        case .weekWarrior:
            return getWorkoutsInCurrentWeek() >= achievement.target
            
        case .monthlyMaster:
            return getWorkoutsInCurrentMonth() >= achievement.target
            
        case .centuryClub:
            return completionHistory.count >= achievement.target
            
        case .dadOfTheYear:
            return completionHistory.filter { $0.withKid }.count >= achievement.target
            
        case .earlyRiser:
            let earlyWorkouts = completionHistory.filter { completion in
                Calendar.current.component(.hour, from: completion.completedAt) < 7
            }
            return earlyWorkouts.count >= achievement.target
            
        case .nightOwl:
            let lateWorkouts = completionHistory.filter { completion in
                Calendar.current.component(.hour, from: completion.completedAt) >= 20
            }
            return lateWorkouts.count >= achievement.target
            
        case .speedDemon:
            let quickWorkouts = completionHistory.filter { $0.duration < 180 }
            return quickWorkouts.count >= achievement.target
            
        case .varietyKing:
            let uniqueTypes = Set(completionHistory.compactMap { getWorkoutType(for: $0) })
            return uniqueTypes.count >= achievement.target
            
        case .socialButterfly:
            // This would check actual invites in production
            return false
        }
    }
    
    private func unlockAchievement(at index: Int) {
        achievements[index] = Achievement(
            id: achievements[index].id,
            type: achievements[index].type,
            name: achievements[index].name,
            description: achievements[index].description,
            iconName: achievements[index].iconName,
            unlockedAt: Date(),
            progress: Double(achievements[index].target),
            target: achievements[index].target
        )
        
        recentlyUnlocked.append(achievements[index])
        
        // Award points
        totalPoints += PointsSystem.achievementUnlocked
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: nil,
            userInfo: ["achievement": achievements[index]]
        )
        
        // Schedule celebration notification
        scheduleAchievementNotification(achievements[index])
    }
    
    private func updateAllProgress() {
        for index in achievements.indices where !achievements[index].isUnlocked {
            let progress = calculateProgress(for: achievements[index].type)
            
            achievements[index] = Achievement(
                id: achievements[index].id,
                type: achievements[index].type,
                name: achievements[index].name,
                description: achievements[index].description,
                iconName: achievements[index].iconName,
                unlockedAt: nil,
                progress: progress,
                target: achievements[index].target
            )
        }
    }
    
    private func calculateProgress(for type: Achievement.AchievementType) -> Double {
        switch type {
        case .firstWorkout:
            return Double(min(completionHistory.count, 1))
            
        case .weekWarrior:
            return Double(getWorkoutsInCurrentWeek())
            
        case .monthlyMaster:
            return Double(getWorkoutsInCurrentMonth())
            
        case .centuryClub:
            return Double(completionHistory.count)
            
        case .dadOfTheYear:
            return Double(completionHistory.filter { $0.withKid }.count)
            
        case .earlyRiser:
            return Double(completionHistory.filter {
                Calendar.current.component(.hour, from: $0.completedAt) < 7
            }.count)
            
        case .nightOwl:
            return Double(completionHistory.filter {
                Calendar.current.component(.hour, from: $0.completedAt) >= 20
            }.count)
            
        case .speedDemon:
            return Double(completionHistory.filter { $0.duration < 180 }.count)
            
        case .varietyKing:
            return Double(Set(completionHistory.compactMap { getWorkoutType(for: $0) }).count)
            
        case .socialButterfly:
            return 0 // Would track actual invites
        }
    }
    
    private func getWorkoutsInCurrentWeek() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return completionHistory.filter { completion in
            completion.completedAt >= weekStart
        }.count
    }
    
    private func getWorkoutsInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return completionHistory.filter { completion in
            completion.completedAt >= monthStart
        }.count
    }
    
    private func getWorkout(for completion: WorkoutCompletion) -> Workout? {
        // In production, this would fetch the actual workout
        return nil
    }
    
    private func getWorkoutType(for completion: WorkoutCompletion) -> WorkoutType? {
        // In production, this would get the actual workout type
        return WorkoutType.allCases.randomElement()
    }
    
    private func createDefaultWorkout() -> Workout {
        Workout(
            name: "Quick Workout",
            duration: 180,
            type: .hiit,
            difficulty: .beginner,
            instructions: ["Exercise"],
            equipment: [.none],
            targetMuscles: [.fullBody]
        )
    }
    
    private func scheduleAchievementNotification(_ achievement: Achievement) {
        Task {
            let content = UNMutableNotificationContent()
            content.title = "Achievement Unlocked! 🏆"
            content.body = "\(achievement.name): \(achievement.description)"
            content.sound = .default
            content.categoryIdentifier = "ACHIEVEMENT"
            
            let request = UNNotificationRequest(
                identifier: "achievement_\(achievement.id)",
                content: content,
                trigger: nil // Show immediately
            )
            
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Achievement Extensions
extension Achievement {
    var shareText: String {
        "I just unlocked the '\(name)' achievement in FitDad Nudge! 🏆 \(description)"
    }
    
    var celebrationEmoji: String {
        switch type.tier {
        case .bronze: return "🥉"
        case .silver: return "🥈"
        case .gold: return "🥇"
        case .platinum: return "💎"
        }
    }
}