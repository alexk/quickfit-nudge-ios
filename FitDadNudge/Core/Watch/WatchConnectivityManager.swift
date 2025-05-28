import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published private(set) var isReachable = false
    @Published private(set) var isPaired = false
    @Published private(set) var isWatchAppInstalled = false
    @Published private(set) var lastSyncDate: Date?
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Public Methods
    
    func sendWorkout(_ workout: Workout) {
        guard let session = session,
              session.isReachable else {
            logDebug("Watch not reachable", category: .watch)
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(workout)
            let message = ["workout": data]
            
            session.sendMessage(message, replyHandler: nil) { [weak self] error in
                logError("Error sending workout: \(error)", category: .watch)
            }
        } catch {
            logError("Error encoding workout: \(error)", category: .watch)
        }
    }
    
    func sendWorkoutCompletion(_ completion: WorkoutCompletion) {
        guard let session = session else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(completion)
            let userInfo = ["completion": data]
            
            // Use transferUserInfo for reliable delivery
            session.transferUserInfo(userInfo)
            lastSyncDate = Date()
        } catch {
            logError("Error encoding completion: \(error)", category: .watch)
        }
    }
    
    func syncUserData() {
        guard let session = session,
              let user = AuthenticationManager.shared.currentUser else { return }
        
        do {
            let encoder = JSONEncoder()
            let userData = try encoder.encode(user)
            let context: [String: Any] = ["user": userData, "timestamp": Date()]
            
            // Update application context for latest state
            try session.updateApplicationContext(context)
        } catch {
            logError("Error syncing user data: \(error)", category: .watch)
        }
    }
    
    func requestWorkoutLibrary() {
        guard let session = session,
              session.isReachable else { return }
        
        session.sendMessage(["request": "workoutLibrary"], replyHandler: { reply in
            // Handle workout library response
            if let workoutsData = reply["workouts"] as? Data {
                self.handleReceivedWorkouts(workoutsData)
            }
        }) { error in
            logError("Error requesting workout library: \(error)", category: .watch)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleReceivedWorkouts(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let workouts = try decoder.decode([Workout].self, from: data)
            
            // Post notification for views to update
            NotificationCenter.default.post(
                name: .workoutsReceivedFromWatch,
                object: nil,
                userInfo: ["workouts": workouts]
            )
        } catch {
            logError("Error decoding workouts: \(error)", category: .watch)
        }
    }
    
    private func handleReceivedCompletion(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let completion = try decoder.decode(WorkoutCompletion.self, from: data)
            
            // Save completion to CloudKit
            Task {
                await saveCompletionToCloudKit(completion)
            }
            
            // Post notification
            NotificationCenter.default.post(
                name: .workoutCompletedOnWatch,
                object: nil,
                userInfo: ["completion": completion]
            )
        } catch {
            logError("Error decoding completion: \(error)", category: .watch)
        }
    }
    
    private func saveCompletionToCloudKit(_ completion: WorkoutCompletion) async {
        // Save to CloudKit (implementation depends on CloudKit manager)
        logInfo("Saving workout completion from watch: \(completion.id)", category: .cloudKit)
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                logError("WCSession activation failed: \(error)", category: .watch)
            } else {
                logInfo("WCSession activated with state: \(activationState.rawValue)", category: .watch)
                updateSessionState()
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        logInfo("WCSession became inactive", category: .watch)
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        logInfo("WCSession deactivated", category: .watch)
        // Reactivate session
        session.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            updateSessionState()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            let reply = await handleReceivedMessageWithReply(message)
            replyHandler(reply)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            handleReceivedUserInfo(userInfo)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            handleReceivedApplicationContext(applicationContext)
        }
    }
    
    // MARK: - Message Handlers
    
    @MainActor
    private func updateSessionState() {
        if let session = session {
            isPaired = session.isPaired
            isWatchAppInstalled = session.isWatchAppInstalled
            isReachable = session.isReachable
        }
    }
    
    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        if let completionData = message["completion"] as? Data {
            handleReceivedCompletion(completionData)
        }
        
        if let request = message["request"] as? String {
            switch request {
            case "sync":
                syncUserData()
            case "workouts":
                sendWorkoutLibrary()
            default:
                break
            }
        }
    }
    
    @MainActor
    private func handleReceivedMessageWithReply(_ message: [String: Any]) async -> [String: Any] {
        if message["request"] as? String == "workoutLibrary" {
            // Return workout library
            return getWorkoutLibraryResponse()
        }
        
        return ["status": "unknown request"]
    }
    
    @MainActor
    private func handleReceivedUserInfo(_ userInfo: [String: Any]) {
        if let completionData = userInfo["completion"] as? Data {
            handleReceivedCompletion(completionData)
        }
    }
    
    @MainActor
    private func handleReceivedApplicationContext(_ context: [String: Any]) {
        // Handle updated application context
        if let userData = context["user"] as? Data {
            // Update local user data if needed
        }
    }
    
    private func sendWorkoutLibrary() {
        // Get workout library and send to watch
        let workouts = getDefaultWorkouts()
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(workouts)
            let message = ["workouts": data]
            
            session?.sendMessage(message, replyHandler: nil, errorHandler: { [weak self] error in
                logError("Error sending workout library: \(error)", category: .watch)
            })
        } catch {
            logError("Error encoding workout library: \(error)", category: .watch)
        }
    }
    
    private func getWorkoutLibraryResponse() -> [String: Any] {
        let workouts = getDefaultWorkouts()
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(workouts)
            return ["workouts": data]
        } catch {
            return ["error": "Failed to encode workouts"]
        }
    }
    
    private func getDefaultWorkouts() -> [Workout] {
        // Return default workout library
        return [
            Workout(
                name: "Quick Breathing",
                duration: 60,
                type: .breathing,
                difficulty: .beginner,
                instructions: ["Inhale deeply", "Hold", "Exhale slowly"],
                equipment: [.none],
                targetMuscles: [.core]
            ),
            Workout(
                name: "Desk Stretch",
                duration: 120,
                type: .stretching,
                difficulty: .beginner,
                instructions: ["Neck rolls", "Shoulder shrugs", "Wrist stretches"],
                equipment: [.none],
                targetMuscles: [.shoulders, .back]
            ),
            Workout(
                name: "Energy Boost",
                duration: 180,
                type: .hiit,
                difficulty: .intermediate,
                instructions: ["Jumping jacks", "High knees", "Burpees"],
                equipment: [.none],
                targetMuscles: [.fullBody]
            )
        ]
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let workoutsReceivedFromWatch = Notification.Name("workoutsReceivedFromWatch")
    static let workoutCompletedOnWatch = Notification.Name("workoutCompletedOnWatch")
}