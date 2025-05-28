import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var pendingNotifications: [UNNotificationRequest] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
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
            "duration": gap.duration
        ]
        
        // Category identifier is already set above
        
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
        
        let content = UNMutableNotificationContent()
        content.title = "Your streak is counting on you"
        content.body = "Just a few minutes today keeps your momentum going strong 🔥"
        content.sound = .default
        content.categoryIdentifier = "STREAK_REMINDER"
        
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
                guard let content = response.notification.request.content.mutableCopy() as? UNMutableNotificationContent else { completionHandler(); return }
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