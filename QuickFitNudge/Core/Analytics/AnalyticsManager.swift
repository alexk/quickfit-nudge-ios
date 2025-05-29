import Foundation
import os.log
import UniversalAnalytics

// MARK: - Analytics Manager
@MainActor
final class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private init() {
        setupAnalytics()
    }
    
    // MARK: - Setup
    
    private func setupAnalytics() {
        // Initialize Amplitude SDK
        let amplitudeApiKey = ProcessInfo.processInfo.environment["AMPLITUDE_API_KEY"] ?? ""
        if !amplitudeApiKey.isEmpty {
            // TODO: Uncomment when Amplitude SDK is added
            // Amplitude.instance().initialize(apiKey: amplitudeApiKey)
            // Amplitude.instance().enableCoppaControl()
            // Amplitude.instance().trackingOptions.disableCarrier()
            // Amplitude.instance().trackingOptions.disableIDFV()
            logInfo("Amplitude initialized", category: .analytics)
        } else {
            logError("Amplitude API key not found in environment", category: .analytics)
        }
        
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
            "created_at": ISO8601DateFormatter().string(from: user.createdAt),
            "has_kids": !user.kids.isEmpty,
            "kids_count": user.kids.count,
            "onboarding_completed": user.hasCompletedOnboarding
        ]
        
        // Set Amplitude user ID
        // TODO: Uncomment when Amplitude SDK is added
        // Amplitude.instance().setUserId(user.id)
        // Amplitude.instance().setUserProperties(properties)
        
        // Forward to UniversalAnalytics
        Task { @MainActor in
            UniversalAnalytics.shared.identify(
                userId: user.id,
                userProperties: properties
            )
        }
        
        logEvent(.userIdentified, properties: properties)
    }
    
    func resetUser() {
        // Reset user ID for analytics
        // TODO: Uncomment when Amplitude SDK is added
        // Amplitude.instance().setUserId(nil)
        // Amplitude.instance().clearUserProperties()
        // Amplitude.instance().regenerateDeviceId()
        
        // Reset UniversalAnalytics user
        Task { @MainActor in
            UniversalAnalytics.shared.reset()
        }
        
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
        
        // Send to Amplitude
        // TODO: Uncomment when Amplitude SDK is added
        // Amplitude.instance().logEvent(event.rawValue, withEventProperties: eventProperties)
        
        // Forward to UniversalAnalytics
        Task { @MainActor in
            UniversalAnalytics.shared.track(
                event: event.rawValue,
                properties: eventProperties
            )
        }
        
        // Also send to os_log for debugging
        os_log("Analytics: %{public}@ - %{public}@", 
               log: OSLog(subsystem: "com.quickfit.nudge", category: "Analytics"),
               type: .info,
               event.rawValue,
               String(describing: eventProperties))
    }
    
    // MARK: - Screen Tracking
    
    func trackScreen(_ screen: ScreenName) {
        logEvent(.screenViewed, properties: ["screen_name": screen.rawValue])
        
        // Also track screen view in UniversalAnalytics
        Task { @MainActor in
            UniversalAnalytics.shared.trackScreenView(
                screenName: screen.rawValue,
                screenClass: String(describing: screen)
            )
        }
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
    
    // MARK: - Calendar/Gap Tracking
    
    func trackCalendarPermissionGranted() {
        logEvent(.calendarPermissionGranted)
    }
    
    func trackCalendarPermissionDenied() {
        logEvent(.calendarPermissionDenied)
    }
    
    func trackGapTapped(_ gap: CalendarGap) {
        logEvent(.gapTapped, properties: [
            "gap_duration": gap.duration,
            "gap_quality": gap.quality.rawValue,
            "suggested_workout": gap.suggestedWorkoutType.rawValue
        ])
    }
    
    func trackGapScanStarted() {
        logEvent(.gapScanStarted)
    }
    
    func trackGapScanCompleted(gapCount: Int, scanDuration: TimeInterval) {
        logEvent(.gapScanCompleted, properties: [
            "gap_count": gapCount,
            "scan_duration_ms": Int(scanDuration * 1000)
        ])
    }
    
    // MARK: - Workout Player Events
    
    func trackWorkoutPaused(_ workout: Workout, at time: TimeInterval) {
        logEvent(.workoutPaused, properties: [
            "workout_id": workout.id.uuidString,
            "workout_type": workout.type.rawValue,
            "paused_at_seconds": Int(time),
            "progress_percentage": Int((time / workout.duration) * 100)
        ])
    }
    
    func trackWorkoutResumed(_ workout: Workout, at time: TimeInterval) {
        logEvent(.workoutResumed, properties: [
            "workout_id": workout.id.uuidString,
            "workout_type": workout.type.rawValue,
            "resumed_at_seconds": Int(time)
        ])
    }
    
    func trackWorkoutCancelled(_ workout: Workout, at time: TimeInterval) {
        logEvent(.workoutCancelled, properties: [
            "workout_id": workout.id.uuidString,
            "workout_type": workout.type.rawValue,
            "cancelled_at_seconds": Int(time),
            "completion_percentage": Int((time / workout.duration) * 100)
        ])
    }
    
    func trackInstructionNavigated(workout: Workout, from: Int, to: Int, direction: String) {
        logEvent(.instructionNavigated, properties: [
            "workout_id": workout.id.uuidString,
            "from_index": from,
            "to_index": to,
            "direction": direction,
            "total_instructions": workout.instructions.count
        ])
    }
    
    func trackMediaLoadFailed(workout: Workout, mediaType: String, error: String?) {
        logEvent(.mediaLoadFailed, properties: [
            "workout_id": workout.id.uuidString,
            "media_type": mediaType,
            "error": error ?? "unknown",
            "has_video": workout.videoURL != nil,
            "has_gif": workout.gifURL != nil
        ])
    }
    
    // MARK: - Team/Social Features
    
    func trackTeamCreated(teamId: String, memberCount: Int) {
        logEvent(.teamCreated, properties: [
            "team_id": teamId,
            "initial_member_count": memberCount
        ])
    }
    
    func trackTeamJoined(teamId: String, inviteCode: String?) {
        logEvent(.teamJoined, properties: [
            "team_id": teamId,
            "used_invite_code": inviteCode != nil
        ])
    }
    
    func trackLeaderboardViewed(scope: String, position: Int?) {
        logEvent(.leaderboardViewed, properties: [
            "scope": scope,
            "user_position": position ?? -1
        ])
    }
    
    // MARK: - Settings/Preferences
    
    func trackSettingChanged(setting: String, oldValue: Any?, newValue: Any) {
        logEvent(.settingChanged, properties: [
            "setting_name": setting,
            "old_value": String(describing: oldValue),
            "new_value": String(describing: newValue)
        ])
    }
    
    func trackExportRequested(format: String) {
        logEvent(.exportRequested, properties: [
            "export_format": format
        ])
    }
    
    func trackExportCompleted(format: String, recordCount: Int) {
        logEvent(.exportCompleted, properties: [
            "export_format": format,
            "record_count": recordCount
        ])
    }
    
    // MARK: - Error Tracking
    
    func trackError(_ error: Error, context: String) {
        let properties: [String: Any] = [
            "error_type": String(describing: type(of: error)),
            "error_message": error.localizedDescription,
            "context": context
        ]
        
        // Log to UniversalAnalytics error tracking
        Task { @MainActor in
            UniversalAnalytics.shared.logError(
                error,
                additionalInfo: properties
            )
        }
        
        logEvent(.errorOccurred, properties: properties)
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
    case workoutCancelled = "workout_cancelled"
    case instructionNavigated = "instruction_navigated"
    case mediaLoadFailed = "media_load_failed"
    
    // Gap Events
    case gapDetected = "gap_detected"
    case gapIgnored = "gap_ignored"
    case gapTapped = "gap_tapped"
    case gapScanStarted = "gap_scan_started"
    case gapScanCompleted = "gap_scan_completed"
    
    // Calendar Events
    case calendarPermissionGranted = "calendar_permission_granted"
    case calendarPermissionDenied = "calendar_permission_denied"
    
    // Subscription Events
    case paywallViewed = "paywall_viewed"
    case subscriptionStarted = "subscription_started"
    case subscriptionCancelled = "subscription_cancelled"
    case subscriptionRenewed = "subscription_renewed"
    
    // Engagement Events
    case streakUpdated = "streak_updated"
    case achievementUnlocked = "achievement_unlocked"
    case leaderboardViewed = "leaderboard_viewed"
    
    // Team Events
    case teamCreated = "team_created"
    case teamJoined = "team_joined"
    
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
    
    // Settings Events
    case settingChanged = "setting_changed"
    case exportRequested = "export_requested"
    case exportCompleted = "export_completed"
    
    // Error Events
    case errorOccurred = "error_occurred"
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