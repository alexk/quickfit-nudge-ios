import Foundation

// MARK: - Streak Model
struct Streak: Identifiable, Codable {
    let id: UUID
    let userId: String
    let type: StreakType
    var currentCount: Int
    var longestCount: Int
    var lastActivityDate: Date
    var startDate: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        type: StreakType,
        currentCount: Int = 0,
        longestCount: Int = 0,
        lastActivityDate: Date = Date(),
        startDate: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.currentCount = currentCount
        self.longestCount = longestCount
        self.lastActivityDate = lastActivityDate
        self.startDate = startDate
    }
    
    enum StreakType: String, Codable, CaseIterable {
        case daily = "Daily Workouts"
        case weekly = "Weekly Goal"
        case dadKid = "Dad-Kid Activities"
        case earlyBird = "Early Bird"
        case consistency = "Consistency King"
        
        var iconName: String {
            switch self {
            case .daily: return "flame.fill"
            case .weekly: return "calendar.badge.checkmark"
            case .dadKid: return "figure.2.and.child.holdinghands"
            case .earlyBird: return "sunrise.fill"
            case .consistency: return "crown.fill"
            }
        }
        
        var description: String {
            switch self {
            case .daily: return "Complete at least one workout every day"
            case .weekly: return "Hit your weekly workout goal"
            case .dadKid: return "Do activities with your kids"
            case .earlyBird: return "Complete workouts before 7 AM"
            case .consistency: return "Maintain regular workout schedule"
            }
        }
    }
    
    var isActive: Bool {
        Calendar.current.isDateInToday(lastActivityDate) ||
        Calendar.current.isDateInYesterday(lastActivityDate)
    }
    
    mutating func incrementStreak() {
        currentCount += 1
        if currentCount > longestCount {
            longestCount = currentCount
        }
        lastActivityDate = Date()
    }
    
    mutating func resetStreak() {
        currentCount = 0
        startDate = Date()
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: UUID
    let type: AchievementType
    let name: String
    let description: String
    let iconName: String
    let unlockedAt: Date?
    let progress: Double
    let target: Int
    
    init(
        id: UUID = UUID(),
        type: AchievementType,
        name: String,
        description: String,
        iconName: String,
        unlockedAt: Date? = nil,
        progress: Double = 0,
        target: Int
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.iconName = iconName
        self.unlockedAt = unlockedAt
        self.progress = progress
        self.target = target
    }
    
    enum AchievementType: String, Codable, CaseIterable {
        case firstWorkout = "first_workout"
        case weekWarrior = "week_warrior"
        case monthlyMaster = "monthly_master"
        case centuryClub = "century_club"
        case dadOfTheYear = "dad_of_year"
        case earlyRiser = "early_riser"
        case nightOwl = "night_owl"
        case speedDemon = "speed_demon"
        case varietyKing = "variety_king"
        case socialButterfly = "social_butterfly"
        
        var tier: Tier {
            switch self {
            case .firstWorkout: return .bronze
            case .weekWarrior, .earlyRiser, .nightOwl: return .silver
            case .monthlyMaster, .speedDemon, .varietyKing: return .gold
            case .centuryClub, .dadOfTheYear, .socialButterfly: return .platinum
            }
        }
    }
    
    enum Tier: String, CaseIterable {
        case bronze = "Bronze"
        case silver = "Silver"
        case gold = "Gold"
        case platinum = "Platinum"
        
        var color: String {
            switch self {
            case .bronze: return "brown"
            case .silver: return "gray"
            case .gold: return "yellow"
            case .platinum: return "purple"
            }
        }
    }
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    var progressPercentage: Double {
        min(progress / Double(target), 1.0)
    }
}

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Identifiable, Codable {
    let id: UUID
    let userId: String
    let userName: String
    let userAvatar: String?
    let score: Int
    let rank: Int
    let timeframe: Timeframe
    let lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        userName: String,
        userAvatar: String? = nil,
        score: Int,
        rank: Int,
        timeframe: Timeframe,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.score = score
        self.rank = rank
        self.timeframe = timeframe
        self.lastUpdated = lastUpdated
    }
    
    enum Timeframe: String, CaseIterable {
        case daily = "Today"
        case weekly = "This Week"
        case monthly = "This Month"
        case allTime = "All Time"
        
        var iconName: String {
            switch self {
            case .daily: return "sun.max.fill"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar.circle.fill"
            case .allTime: return "crown.fill"
            }
        }
    }
}

// MARK: - Points System
struct PointsSystem {
    static let workoutCompleted = 10
    static let dadKidWorkout = 20
    static let streakBonus = 5
    static let achievementUnlocked = 50
    static let weeklyGoalMet = 100
    static let socialShare = 15
    static let friendInvited = 30
    
    static func calculateWorkoutPoints(
        workout: Workout,
        duration: TimeInterval,
        withKid: Bool = false
    ) -> Int {
        var points = workoutCompleted
        
        // Duration bonus
        if duration >= workout.duration {
            points += 5
        }
        
        // Difficulty bonus
        switch workout.difficulty {
        case .beginner: break
        case .intermediate: points += 5
        case .advanced: points += 10
        }
        
        // Dad-kid bonus
        if withKid {
            points += dadKidWorkout
        }
        
        return points
    }
}

// MARK: - Challenge Model
struct Challenge: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let type: ChallengeType
    let startDate: Date
    let endDate: Date
    let targetValue: Int
    let rewardPoints: Int
    let participants: [String]
    var progress: [String: Int]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: ChallengeType,
        startDate: Date,
        endDate: Date,
        targetValue: Int,
        rewardPoints: Int,
        participants: [String] = [],
        progress: [String: Int] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.targetValue = targetValue
        self.rewardPoints = rewardPoints
        self.participants = participants
        self.progress = progress
    }
    
    enum ChallengeType: String, Codable, CaseIterable {
        case personal = "Personal"
        case dadKid = "Dad & Kid"
        case community = "Community"
        case seasonal = "Seasonal"
        
        var iconName: String {
            switch self {
            case .personal: return "person.fill"
            case .dadKid: return "figure.2.and.child.holdinghands"
            case .community: return "person.3.fill"
            case .seasonal: return "leaf.fill"
            }
        }
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    func userProgress(for userId: String) -> Double {
        guard let userProgress = progress[userId] else { return 0 }
        return Double(userProgress) / Double(targetValue)
    }
} 