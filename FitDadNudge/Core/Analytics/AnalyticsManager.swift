import Foundation

// MARK: - Analytics Manager
@MainActor
final class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private init() {
        setupAnalytics()
    }
    
    // MARK: - Setup
    
    private func setupAnalytics() {
        // In a real app, initialize Amplitude here
        // Amplitude.instance().initialize(apiKey: ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY"] ?? "")
        
        // Set user properties
        if let user = AuthenticationManager.shared.currentUser {
            identifyUser(user)
        }
    }
    
    // MARK: - User Identification
    
    func identifyUser(_ user: User) {
        let properties: [String: Any] = [
            "user_id": user.id,
            "subscription_status": user.subscriptionStatus.rawValue,
            "created_at": ISO8601DateFormatter().string(from: user.createdAt)
        ]
        
        logEvent(.userIdentified, properties: properties)
    }
    
    func resetUser() {
        // Reset user ID for analytics
        logEvent(.userLoggedOut)
    }
    
    // MARK: - Event Tracking
    
    func logEvent(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        var eventProperties = properties ?? [:]
        
        // Add common properties
        eventProperties["platform"] = "iOS"
        eventProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        eventProperties["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        // Log analytics events
        logDebug("Analytics Event: \(event.rawValue) - Properties: \(eventProperties)", category: .analytics)
        
        // In production, send to Amplitude
        // Amplitude.instance().logEvent(event.rawValue, withEventProperties: eventProperties)
    }
    
    // MARK: - Screen Tracking
    
    func trackScreen(_ screen: ScreenName) {
        logEvent(.screenViewed, properties: ["screen_name": screen.rawValue])
    }
    
    // MARK: - Workout Tracking
    
    func trackWorkoutStarted(_ workout: Workout, source: WorkoutSource) {
        logEvent(.workoutStarted, properties: [
            "workout_id": workout.id.uuidString,
            "workout_type": workout.type.rawValue,
            "workout_duration": workout.duration,
            "workout_difficulty": workout.difficulty.rawValue,
            "source": source.rawValue
        ])
    }
    
    func trackWorkoutCompleted(_ workout: Workout, actualDuration: TimeInterval, withKid: Bool = false) {
        let completionRate = actualDuration / workout.duration
        
        logEvent(.workoutCompleted, properties: [
            "workout_id": workout.id.uuidString,
            "workout_type": workout.type.rawValue,
            "planned_duration": workout.duration,
            "actual_duration": actualDuration,
            "completion_rate": completionRate,
            "with_kid": withKid,
            "difficulty": workout.difficulty.rawValue
        ])
    }
    
    func trackWorkoutSkipped(_ workout: Workout, reason: SkipReason) {
        logEvent(.workoutSkipped, properties: [
            "workout_id": workout.id.uuidString,
            "workout_type": workout.type.rawValue,
            "skip_reason": reason.rawValue
        ])
    }
    
    // MARK: - Gap Detection Tracking
    
    func trackGapDetected(count: Int, quality: CalendarGap.GapQuality) {
        logEvent(.gapDetected, properties: [
            "gap_count": count,
            "gap_quality": quality.rawValue
        ])
    }
    
    func trackGapIgnored(_ gap: CalendarGap) {
        logEvent(.gapIgnored, properties: [
            "gap_duration": gap.duration,
            "gap_quality": gap.quality.rawValue,
            "suggested_workout": gap.suggestedWorkoutType.rawValue
        ])
    }
    
    // MARK: - Subscription Tracking
    
    func trackPaywallViewed(source: PaywallSource) {
        logEvent(.paywallViewed, properties: ["source": source.rawValue])
    }
    
    func trackSubscriptionStarted(plan: SubscriptionStatus.PlanType, price: Double) {
        logEvent(.subscriptionStarted, properties: [
            "plan_type": plan.rawValue,
            "price": price
        ])
    }
    
    func trackSubscriptionCancelled(plan: SubscriptionStatus.PlanType, reason: String? = nil) {
        var properties: [String: Any] = ["plan_type": plan.rawValue]
        if let reason = reason {
            properties["cancellation_reason"] = reason
        }
        logEvent(.subscriptionCancelled, properties: properties)
    }
    
    // MARK: - Engagement Tracking
    
    func trackStreakUpdated(_ streak: Streak) {
        logEvent(.streakUpdated, properties: [
            "streak_type": streak.type.rawValue,
            "current_count": streak.currentCount,
            "longest_count": streak.longestCount,
            "is_active": streak.isActive
        ])
    }
    
    func trackAchievementUnlocked(_ achievement: Achievement) {
        logEvent(.achievementUnlocked, properties: [
            "achievement_type": achievement.type.rawValue,
            "achievement_tier": achievement.type.tier.rawValue
        ])
    }
    
    func trackNotificationReceived(type: NotificationType) {
        logEvent(.notificationReceived, properties: ["notification_type": type.rawValue])
    }
    
    func trackNotificationTapped(type: NotificationType) {
        logEvent(.notificationTapped, properties: ["notification_type": type.rawValue])
    }
    
    // MARK: - Performance Tracking
    
    func trackAppLaunch(launchTime: TimeInterval) {
        logEvent(.appLaunched, properties: ["launch_time_ms": Int(launchTime * 1000)])
    }
    
    func trackWidgetRefresh(success: Bool, duration: TimeInterval) {
        logEvent(.widgetRefreshed, properties: [
            "success": success,
            "refresh_duration_ms": Int(duration * 1000)
        ])
    }
}

// MARK: - Analytics Event Types
enum AnalyticsEvent: String {
    // User Events
    case userIdentified = "user_identified"
    case userLoggedOut = "user_logged_out"
    
    // Screen Events
    case screenViewed = "screen_viewed"
    
    // Workout Events
    case workoutStarted = "workout_started"
    case workoutCompleted = "workout_completed"
    case workoutSkipped = "workout_skipped"
    case workoutPaused = "workout_paused"
    case workoutResumed = "workout_resumed"
    
    // Gap Events
    case gapDetected = "gap_detected"
    case gapIgnored = "gap_ignored"
    case gapTapped = "gap_tapped"
    
    // Subscription Events
    case paywallViewed = "paywall_viewed"
    case subscriptionStarted = "subscription_started"
    case subscriptionCancelled = "subscription_cancelled"
    case subscriptionRenewed = "subscription_renewed"
    
    // Engagement Events
    case streakUpdated = "streak_updated"
    case achievementUnlocked = "achievement_unlocked"
    case leaderboardViewed = "leaderboard_viewed"
    
    // Notification Events
    case notificationReceived = "notification_received"
    case notificationTapped = "notification_tapped"
    case notificationPermissionGranted = "notification_permission_granted"
    case notificationPermissionDenied = "notification_permission_denied"
    
    // App Events
    case appLaunched = "app_launched"
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"
    
    // Widget Events
    case widgetRefreshed = "widget_refreshed"
    case widgetTapped = "widget_tapped"
}

// MARK: - Screen Names
enum ScreenName: String {
    case home = "home"
    case streaks = "streaks"
    case library = "library"
    case kids = "kids"
    case settings = "settings"
    case workoutPlayer = "workout_player"
    case paywall = "paywall"
    case onboarding = "onboarding"
    case authentication = "authentication"
}

// MARK: - Supporting Enums
enum WorkoutSource: String {
    case gap = "calendar_gap"
    case quickAction = "quick_action"
    case library = "library"
    case widget = "widget"
    case notification = "notification"
}

enum SkipReason: String {
    case tooShort = "too_short"
    case tooLong = "too_long"
    case notInterested = "not_interested"
    case noTime = "no_time"
    case other = "other"
}

enum PaywallSource: String {
    case onboarding = "onboarding"
    case settings = "settings"
    case featureLocked = "feature_locked"
    case trial = "trial_ended"
}

enum NotificationType: String {
    case workoutGap = "workout_gap"
    case streakReminder = "streak_reminder"
    case achievement = "achievement"
    case challenge = "challenge"
} 