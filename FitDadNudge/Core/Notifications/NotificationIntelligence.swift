import Foundation

@MainActor
final class NotificationIntelligence: ObservableObject {
    
    // MARK: - Types
    
    enum NotificationLevel: String, CaseIterable {
        case minimal = "Minimal (1/day max)"
        case balanced = "Balanced (2/day max)"
        case aggressive = "Aggressive (3/day max)"
        case off = "Off"
        
        var maxDailyNotifications: Int {
            switch self {
            case .minimal: return 1
            case .balanced: return 2
            case .aggressive: return 3
            case .off: return 0
            }
        }
    }
    
    enum NotificationType: String, CaseIterable {
        case gapReminder = "gap_reminder"
        case streakRisk = "streak_risk"
        case perfectGap = "perfect_gap"
        case dailyCheck = "daily_check"
    }
    
    struct NotificationContext {
        let lastNotificationTime: Date?
        let userResponseRate: Double
        let currentStreakLength: Int
        let typicalActiveHours: [Int]
        let recentIgnoredCount: Int
        let lastWorkoutHours: Int
        let hasUpcomingGap: Bool
        let upcomingGapMinutes: Int?
    }
    
    struct UserState {
        let lastWorkoutHours: Int
        let currentStreak: Int
        let recentResponseRate: Double
        let hasUpcomingGap: (minutes: Int, within: DateInterval) -> Bool
    }
    
    struct NotificationRule {
        let id: String
        let condition: (UserState) -> Bool
        let priority: Int
        let cooldownHours: Int
        let type: NotificationType
    }
    
    // MARK: - Properties
    
    @Published var notificationLevel: NotificationLevel = .balanced
    @Published var quietHoursEnabled: Bool = true
    @Published var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @Published var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    
    private let userDefaults = UserDefaults.standard
    private let notificationHistoryKey = "notification_history"
    private let notificationSettingsKey = "notification_settings"
    
    // MARK: - Notification Rules
    
    private lazy var notificationRules: [NotificationRule] = [
        NotificationRule(
            id: "streak_risk",
            condition: { state in
                state.lastWorkoutHours > 20 && state.currentStreak > 3
            },
            priority: 1,
            cooldownHours: 12,
            type: .streakRisk
        ),
        NotificationRule(
            id: "perfect_gap",
            condition: { state in
                state.hasUpcomingGap(5, DateInterval(start: Date(), duration: 3600)) // 5 min gap within 1 hour
            },
            priority: 2,
            cooldownHours: 24,
            type: .perfectGap
        ),
        NotificationRule(
            id: "daily_check",
            condition: { state in
                state.lastWorkoutHours > 24 && state.currentStreak == 0
            },
            priority: 3,
            cooldownHours: 48,
            type: .dailyCheck
        )
    ]
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func shouldSendNotification(type: NotificationType, context: NotificationContext) -> Bool {
        // Check if notifications are disabled
        guard notificationLevel != .off else { return false }
        
        // Check daily limit
        if hasReachedDailyLimit() {
            logDebug("Daily notification limit reached", category: .notification)
            return false
        }
        
        // Check quiet hours
        if quietHoursEnabled && isInQuietHours() {
            logDebug("In quiet hours, skipping notification", category: .notification)
            return false
        }
        
        // Check user engagement
        if context.recentIgnoredCount >= 3 && context.userResponseRate < 0.3 {
            logDebug("User has low engagement, reducing notifications", category: .notification)
            return false
        }
        
        // Check minimum time between notifications (30 minutes)
        if let lastTime = context.lastNotificationTime,
           Date().timeIntervalSince(lastTime) < 1800 {
            logDebug("Too soon since last notification", category: .notification)
            return false
        }
        
        // Check if this notification type should be sent based on rules
        return shouldSendBasedOnRules(type: type, context: context)
    }
    
    func recordNotificationSent(type: NotificationType) {
        let record = NotificationRecord(
            type: type,
            sentAt: Date(),
            wasOpened: false,
            wasIgnored: false
        )
        saveNotificationRecord(record)
    }
    
    func recordNotificationOpened(type: NotificationType) {
        updateLatestNotificationRecord(type: type) { record in
            record.wasOpened = true
        }
    }
    
    func recordNotificationIgnored(type: NotificationType) {
        updateLatestNotificationRecord(type: type) { record in
            record.wasIgnored = true
        }
    }
    
    func getNotificationFrequencyInsights() -> NotificationInsights {
        let history = getNotificationHistory()
        let last30Days = history.filter { $0.sentAt > Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date() }
        
        let totalSent = last30Days.count
        let totalOpened = last30Days.filter { $0.wasOpened }.count
        let totalIgnored = last30Days.filter { $0.wasIgnored }.count
        
        let responseRate = totalSent > 0 ? Double(totalOpened) / Double(totalSent) : 0.0
        let ignoreRate = totalSent > 0 ? Double(totalIgnored) / Double(totalSent) : 0.0
        
        return NotificationInsights(
            totalSent: totalSent,
            responseRate: responseRate,
            ignoreRate: ignoreRate,
            averagePerDay: Double(totalSent) / 30.0,
            recommendedLevel: getRecommendedLevel(responseRate: responseRate, ignoreRate: ignoreRate)
        )
    }
    
    // MARK: - Private Methods
    
    private func hasReachedDailyLimit() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let history = getNotificationHistory()
        let todayCount = history.filter { Calendar.current.isDate($0.sentAt, inSameDayAs: today) }.count
        
        return todayCount >= notificationLevel.maxDailyNotifications
    }
    
    private func isInQuietHours() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: quietHoursStart)
        let endComponents = calendar.dateComponents([.hour, .minute], from: quietHoursEnd)
        
        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else {
            return false
        }
        
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        guard let currentHour = nowComponents.hour,
              let currentMinute = nowComponents.minute else {
            return false
        }
        
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        let startTimeInMinutes = startHour * 60 + startMinute
        let endTimeInMinutes = endHour * 60 + endMinute
        
        if startTimeInMinutes < endTimeInMinutes {
            // Same day quiet hours
            return currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes < endTimeInMinutes
        } else {
            // Overnight quiet hours
            return currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes < endTimeInMinutes
        }
    }
    
    private func shouldSendBasedOnRules(type: NotificationType, context: NotificationContext) -> Bool {
        let applicableRules = notificationRules.filter { $0.type == type }
        
        for rule in applicableRules.sorted(by: { $0.priority < $1.priority }) {
            // Check cooldown
            if let lastTime = getLastNotificationTime(for: rule.type),
               Date().timeIntervalSince(lastTime) < TimeInterval(rule.cooldownHours * 3600) {
                continue
            }
            
            // Convert context to user state
            let userState = UserState(
                lastWorkoutHours: context.lastWorkoutHours,
                currentStreak: context.currentStreakLength,
                recentResponseRate: context.userResponseRate,
                hasUpcomingGap: { minutes, within in
                    context.hasUpcomingGap && (context.upcomingGapMinutes ?? 0) >= minutes
                }
            )
            
            if rule.condition(userState) {
                return true
            }
        }
        
        return false
    }
    
    private func getRecommendedLevel(responseRate: Double, ignoreRate: Double) -> NotificationLevel {
        if ignoreRate > 0.7 || responseRate < 0.1 {
            return .minimal
        } else if responseRate > 0.6 && ignoreRate < 0.2 {
            return .aggressive
        } else {
            return .balanced
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: notificationSettingsKey),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.notificationLevel = settings.level
            self.quietHoursEnabled = settings.quietHoursEnabled
            self.quietHoursStart = settings.quietHoursStart
            self.quietHoursEnd = settings.quietHoursEnd
        }
    }
    
    private func saveSettings() {
        let settings = NotificationSettings(
            level: notificationLevel,
            quietHoursEnabled: quietHoursEnabled,
            quietHoursStart: quietHoursStart,
            quietHoursEnd: quietHoursEnd
        )
        
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: notificationSettingsKey)
        }
    }
    
    private func getNotificationHistory() -> [NotificationRecord] {
        guard let data = userDefaults.data(forKey: notificationHistoryKey),
              let history = try? JSONDecoder().decode([NotificationRecord].self, from: data) else {
            return []
        }
        return history
    }
    
    private func saveNotificationRecord(_ record: NotificationRecord) {
        var history = getNotificationHistory()
        history.append(record)
        
        // Keep only last 1000 records
        if history.count > 1000 {
            history = Array(history.suffix(1000))
        }
        
        if let data = try? JSONEncoder().encode(history) {
            userDefaults.set(data, forKey: notificationHistoryKey)
        }
    }
    
    private func updateLatestNotificationRecord(type: NotificationType, update: (inout NotificationRecord) -> Void) {
        var history = getNotificationHistory()
        
        if let index = history.lastIndex(where: { $0.type == type }) {
            update(&history[index])
            
            if let data = try? JSONEncoder().encode(history) {
                userDefaults.set(data, forKey: notificationHistoryKey)
            }
        }
    }
    
    private func getLastNotificationTime(for type: NotificationType) -> Date? {
        let history = getNotificationHistory()
        return history.filter { $0.type == type }.last?.sentAt
    }
}

// MARK: - Supporting Types

struct NotificationRecord: Codable {
    let id = UUID()
    let type: NotificationIntelligence.NotificationType
    let sentAt: Date
    var wasOpened: Bool
    var wasIgnored: Bool
}

struct NotificationSettings: Codable {
    let level: NotificationIntelligence.NotificationLevel
    let quietHoursEnabled: Bool
    let quietHoursStart: Date
    let quietHoursEnd: Date
}

struct NotificationInsights {
    let totalSent: Int
    let responseRate: Double
    let ignoreRate: Double
    let averagePerDay: Double
    let recommendedLevel: NotificationIntelligence.NotificationLevel
}

// MARK: - Logger Integration

extension NotificationIntelligence {
    private func logDebug(_ message: String, category: LogCategory) {
        Logger.shared.debug(message, category: category)
    }
}