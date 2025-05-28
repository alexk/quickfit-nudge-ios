import Foundation
import SwiftUI

@MainActor
final class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    @Published private(set) var streaks: [Streak] = []
    @Published private(set) var isLoading = false
    
    private let cloudKitManager = CloudKitManager.shared
    private let calendar = Calendar.current
    
    private init() {
        loadStreaks()
    }
    
    // MARK: - Public Methods
    
    func loadStreaks() {
        guard let userId = AuthenticationManager.shared.currentUser?.id else { return }
        
        // Initialize default streaks if needed
        if streaks.isEmpty {
            streaks = Streak.StreakType.allCases.map { type in
                Streak(userId: userId, type: type)
            }
        }
    }
    
    func updateStreak(for completion: WorkoutCompletion) {
        guard let userId = AuthenticationManager.shared.currentUser?.id,
              completion.userId == userId else { return }
        
        let completionDate = completion.completedAt
        
        // Update daily streak
        if let dailyIndex = streaks.firstIndex(where: { $0.type == .daily }) {
            updateDailyStreak(at: dailyIndex, completionDate: completionDate)
        }
        
        // Update dad-kid streak if applicable
        if completion.withKid,
           let dadKidIndex = streaks.firstIndex(where: { $0.type == .dadKid }) {
            updateDadKidStreak(at: dadKidIndex, completionDate: completionDate)
        }
        
        // Update early bird streak if before 7 AM
        let hour = calendar.component(.hour, from: completionDate)
        if hour < 7,
           let earlyBirdIndex = streaks.firstIndex(where: { $0.type == .earlyBird }) {
            updateEarlyBirdStreak(at: earlyBirdIndex, completionDate: completionDate)
        }
        
        // Update weekly streak
        updateWeeklyStreak()
        
        // Update consistency streak
        updateConsistencyStreak()
        
        // Save to CloudKit
        Task {
            await saveStreaksToCloudKit()
        }
    }
    
    func checkAndResetStreaks() {
        let today = Date()
        
        for index in streaks.indices {
            let streak = streaks[index]
            
            switch streak.type {
            case .daily:
                // Reset if last activity was not today or yesterday
                if !calendar.isDateInToday(streak.lastActivityDate) &&
                   !calendar.isDateInYesterday(streak.lastActivityDate) {
                    streaks[index].resetStreak()
                }
                
            case .weekly:
                // Reset if new week started
                if !calendar.isDate(streak.lastActivityDate, equalTo: today, toGranularity: .weekOfYear) {
                    let workoutsThisWeek = getWorkoutCountForCurrentWeek()
                    if workoutsThisWeek < 5 { // Weekly goal is 5 workouts
                        streaks[index].resetStreak()
                    }
                }
                
            case .earlyBird:
                // Reset if missed more than 2 days
                let daysDiff = calendar.dateComponents([.day], from: streak.lastActivityDate, to: today).day ?? 0
                if daysDiff > 2 {
                    streaks[index].resetStreak()
                }
                
            default:
                break
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateDailyStreak(at index: Int, completionDate: Date) {
        let lastActivity = streaks[index].lastActivityDate
        
        if calendar.isDateInToday(completionDate) {
            // Check if this is the first workout today
            if !calendar.isDateInToday(lastActivity) {
                if calendar.isDateInYesterday(lastActivity) {
                    // Continue streak
                    streaks[index].incrementStreak()
                } else {
                    // Reset and start new streak
                    streaks[index].resetStreak()
                    streaks[index].incrementStreak()
                }
            }
        }
    }
    
    private func updateDadKidStreak(at index: Int, completionDate: Date) {
        let lastActivity = streaks[index].lastActivityDate
        
        if !calendar.isDate(lastActivity, inSameDayAs: completionDate) {
            let daysDiff = calendar.dateComponents([.day], from: lastActivity, to: completionDate).day ?? 0
            
            if daysDiff <= 7 { // Allow weekly dad-kid activities
                streaks[index].incrementStreak()
            } else {
                streaks[index].resetStreak()
                streaks[index].incrementStreak()
            }
        }
    }
    
    private func updateEarlyBirdStreak(at index: Int, completionDate: Date) {
        let lastActivity = streaks[index].lastActivityDate
        
        if !calendar.isDate(lastActivity, inSameDayAs: completionDate) {
            let daysDiff = calendar.dateComponents([.day], from: lastActivity, to: completionDate).day ?? 0
            
            if daysDiff <= 2 { // Allow 2 days gap for early bird
                streaks[index].incrementStreak()
            } else {
                streaks[index].resetStreak()
                streaks[index].incrementStreak()
            }
        }
    }
    
    private func updateWeeklyStreak() {
        guard let weeklyIndex = streaks.firstIndex(where: { $0.type == .weekly }) else { return }
        
        let workoutsThisWeek = getWorkoutCountForCurrentWeek()
        
        if workoutsThisWeek >= 5 { // Weekly goal
            let lastWeekEnd = calendar.dateInterval(of: .weekOfYear, for: streaks[weeklyIndex].lastActivityDate)?.end ?? Date()
            let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            
            if lastWeekEnd >= currentWeekStart {
                // Consecutive weeks
                streaks[weeklyIndex].incrementStreak()
            } else {
                // Gap in weeks
                streaks[weeklyIndex].resetStreak()
                streaks[weeklyIndex].incrementStreak()
            }
        }
    }
    
    private func updateConsistencyStreak() {
        guard let consistencyIndex = streaks.firstIndex(where: { $0.type == .consistency }) else { return }
        
        // Check workout pattern over last 30 days
        let workoutPattern = getWorkoutPatternForLastDays(30)
        let consistencyScore = calculateConsistencyScore(workoutPattern)
        
        if consistencyScore >= 0.7 { // 70% consistency
            streaks[consistencyIndex].incrementStreak()
        } else if consistencyScore < 0.5 {
            streaks[consistencyIndex].resetStreak()
        }
    }
    
    private func getWorkoutCountForCurrentWeek() -> Int {
        // In production, this would query actual workout completions
        // For now, return a mock value
        return 3
    }
    
    private func getWorkoutPatternForLastDays(_ days: Int) -> [Bool] {
        // In production, this would check actual workout history
        // For now, return a mock pattern
        return Array(repeating: true, count: days * 3 / 4) + Array(repeating: false, count: days / 4)
    }
    
    private func calculateConsistencyScore(_ pattern: [Bool]) -> Double {
        guard !pattern.isEmpty else { return 0 }
        
        let workoutDays = pattern.filter { $0 }.count
        let totalDays = pattern.count
        
        // Calculate consistency based on regularity, not just total
        var consistencyPoints = 0.0
        var currentStreak = 0
        
        for worked in pattern {
            if worked {
                currentStreak += 1
                consistencyPoints += Double(currentStreak) * 0.1
            } else {
                currentStreak = 0
            }
        }
        
        return min(Double(workoutDays) / Double(totalDays) + consistencyPoints * 0.1, 1.0)
    }
    
    private func saveStreaksToCloudKit() async {
        // Save streaks to CloudKit
        // Implementation depends on CloudKit manager
        print("Saving streaks to CloudKit")
    }
}

// MARK: - Streak Extensions
extension Streak {
    var motivationalMessage: String {
        switch type {
        case .daily:
            if currentCount == 0 {
                return "Every fitness journey starts with day one"
            } else if currentCount < 7 {
                return "Building momentum - \(currentCount) days and counting!"
            } else if currentCount < 30 {
                return "You're on fire! \(currentCount) days of showing up!"
            } else {
                return "Legend status: \(currentCount) consecutive days!"
            }
            
        case .weekly:
            return "Week \(currentCount) champion - your dedication is inspiring"
            
        case .dadKid:
            return "\(currentCount) awesome moments with your little workout buddy!"
            
        case .earlyBird:
            return "\(currentCount) early morning victories - before the world wakes up!"
            
        case .consistency:
            return "The steady achiever: \(currentCount) weeks of reliable self-care"
        }
    }
    
    var nextMilestone: Int {
        let milestones = [3, 7, 14, 30, 60, 100, 365]
        return milestones.first { $0 > currentCount } ?? currentCount + 100
    }
    
    var progressToNextMilestone: Double {
        let next = nextMilestone
        let previous = currentCount == 0 ? 0 : [3, 7, 14, 30, 60, 100, 365].reversed().first { $0 <= currentCount } ?? 0
        
        let range = next - previous
        let progress = currentCount - previous
        
        return range > 0 ? Double(progress) / Double(range) : 0
    }
}