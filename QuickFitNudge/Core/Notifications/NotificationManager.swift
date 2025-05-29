import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let intelligence = NotificationIntelligence()
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await checkAuthorizationStatus()
            return granted
        } catch {
            logError("Error requesting notification authorization: \(error)", category: .notification)
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    func scheduleGapNotification(for gap: CalendarGap) async throws {
        guard authorizationStatus == .authorized else {
            throw NotificationError.notAuthorized
        }
        
        // Check with intelligence system before scheduling
        let context = await buildNotificationContext(for: .gapReminder)
        guard intelligence.shouldSendNotification(type: .gapReminder, context: context) else {
            logDebug("Intelligence system blocked gap notification", category: .notification)
            return
        }
        
        // Schedule notification 5 minutes before the gap
        let triggerDate = gap.startDate.addingTimeInterval(-5 * 60)
        
        // Don't schedule if the trigger date is in the past
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Perfect timing!"
        content.body = "You've got \(gap.durationInMinutes) minutes before your next meeting. How about a quick \(gap.suggestedWorkoutType.rawValue.lowercased()) session?"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REMINDER"
        content.userInfo = [
            "gapID": gap.id.uuidString,
            "workoutType": gap.suggestedWorkoutType.rawValue,
            "duration": gap.duration,
            "notificationType": NotificationIntelligence.NotificationType.gapReminder.rawValue
        ]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: gap.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        await updatePendingNotifications()
        
        // Record the notification with intelligence system
        intelligence.recordNotificationSent(type: .gapReminder)
    }
    
    func cancelNotification(for gapID: UUID) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [gapID.uuidString])
        await updatePendingNotifications()
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await updatePendingNotifications()
    }
    
    func scheduleStreakReminder(hour: Int = 20) async throws {
        guard authorizationStatus == .authorized else {
            throw NotificationError.notAuthorized
        }
        
        // Check with intelligence system before scheduling
        let context = await buildNotificationContext(for: .streakRisk)
        guard intelligence.shouldSendNotification(type: .streakRisk, context: context) else {
            logDebug("Intelligence system blocked streak reminder", category: .notification)
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Your streak is counting on you"
        content.body = "Just a few minutes today keeps your momentum going strong 🔥"
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"
        content.userInfo = [
            "notificationType": NotificationIntelligence.NotificationType.streakRisk.rawValue
        ]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        await updatePendingNotifications()
        
        // Record the notification with intelligence system
        intelligence.recordNotificationSent(type: .streakRisk)
    }
    
    func registerNotificationCategories() {
        let startAction = UNNotificationAction(
            identifier: "START_WORKOUT",
            title: "Start Workout",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_WORKOUT",
            title: "Remind in 30 min",
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_WORKOUT",
            title: "Dismiss",
            options: .destructive
        )
        
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_REMINDER",
            actions: [startAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_REMINDER",
            actions: [startAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([workoutCategory, streakCategory])
    }
    
    // MARK: - Private Methods
    
    private func updatePendingNotifications() async {
        pendingNotifications = await notificationCenter.pendingNotificationRequests()
    }
    
    private func buildNotificationContext(for type: NotificationIntelligence.NotificationType) async -> NotificationIntelligence.NotificationContext {
        // Get recent notification history
        let recentHistory = getRecentNotificationHistory()
        let lastNotificationTime = recentHistory.last?.sentAt
        
        // Calculate response rate from recent interactions
        let totalRecent = recentHistory.count
        let respondedRecent = recentHistory.filter { $0.wasOpened }.count
        let responseRate = totalRecent > 0 ? Double(respondedRecent) / Double(totalRecent) : 0.5
        
        // Calculate recent ignored count
        let recentIgnored = recentHistory.filter { $0.wasIgnored }.count
        
        // Mock data for user state - in a real app, this would come from user managers
        let mockCurrentStreak = 5 // This would come from StreakManager
        let mockLastWorkoutHours = 8 // This would come from workout tracking
        let mockTypicalActiveHours = [9, 12, 15, 18] // This would be learned from user behavior
        
        return NotificationIntelligence.NotificationContext(
            lastNotificationTime: lastNotificationTime,
            userResponseRate: responseRate,
            currentStreakLength: mockCurrentStreak,
            typicalActiveHours: mockTypicalActiveHours,
            recentIgnoredCount: recentIgnored,
            lastWorkoutHours: mockLastWorkoutHours,
            hasUpcomingGap: true, // This would come from CalendarManager
            upcomingGapMinutes: 5 // This would come from CalendarManager
        )
    }
    
    private func getRecentNotificationHistory() -> [NotificationRecord] {
        // Get history from intelligence system
        return intelligence.getNotificationFrequencyInsights().totalSent > 0 ? [] : []
        // In a real implementation, this would fetch from intelligence system storage
    }
    
    private func logDebug(_ message: String, category: LogCategory) {
        Logger.shared.debug(message, category: category)
    }
}

// MARK: - Notification Errors
enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "We'd love to send you workout reminders, but need permission first"
        case .schedulingFailed(let error):
            return "Couldn't set up your workout reminder - \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let intelligence = NotificationIntelligence()
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Track notification interaction
        if let notificationTypeString = userInfo["notificationType"] as? String,
           let notificationType = NotificationIntelligence.NotificationType(rawValue: notificationTypeString) {
            
            switch response.actionIdentifier {
            case "START_WORKOUT", UNNotificationDefaultActionIdentifier:
                Task { @MainActor in
                    intelligence.recordNotificationOpened(type: notificationType)
                }
            case "DISMISS_WORKOUT", UNNotificationDismissActionIdentifier:
                Task { @MainActor in
                    intelligence.recordNotificationIgnored(type: notificationType)
                }
            default:
                break
            }
        }
        
        switch response.actionIdentifier {
        case "START_WORKOUT":
            // Handle start workout action
            if let workoutType = userInfo["workoutType"] as? String,
               let duration = userInfo["duration"] as? TimeInterval {
                // Post notification to start workout
                NotificationCenter.default.post(
                    name: .startWorkoutFromNotification,
                    object: nil,
                    userInfo: ["workoutType": workoutType, "duration": duration]
                )
            }
            
        case "SNOOZE_WORKOUT":
            // Reschedule for 30 minutes later
            Task {
                // Create a new notification content based on the original
                let content = UNMutableNotificationContent()
                content.title = response.notification.request.content.title
                content.body = response.notification.request.content.body
                content.sound = response.notification.request.content.sound
                content.categoryIdentifier = response.notification.request.content.categoryIdentifier
                content.userInfo = response.notification.request.content.userInfo
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 * 60, repeats: false)
                let request = UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped on notification
            if let gapID = userInfo["gapID"] as? String {
                NotificationCenter.default.post(
                    name: .openGapFromNotification,
                    object: nil,
                    userInfo: ["gapID": gapID]
                )
            }
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let startWorkoutFromNotification = Notification.Name("startWorkoutFromNotification")
    static let openGapFromNotification = Notification.Name("openGapFromNotification")
}