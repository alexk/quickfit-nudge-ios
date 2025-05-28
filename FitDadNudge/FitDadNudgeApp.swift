//
//  FitDadNudgeApp.swift
//  FitDadNudge
//
//  Created by Alex Koff on 5/26/25.
//

import SwiftUI
import UserNotifications

@main
struct FitDadNudgeApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Store as static to ensure it's not deallocated
    private static let notificationDelegate = NotificationDelegate()
    
    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = Self.notificationDelegate
        
        // Register notification categories
        NotificationManager.shared.registerNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(appState)
                .environmentObject(notificationManager)
                .task {
                    await authManager.checkAuthenticationStatus()
                }
                .onReceive(NotificationCenter.default.publisher(for: .startWorkoutFromNotification)) { notification in
                    handleStartWorkoutNotification(notification)
                }
                .onReceive(NotificationCenter.default.publisher(for: .openGapFromNotification)) { notification in
                    handleOpenGapNotification(notification)
                }
        }
    }
    
    private func handleStartWorkoutNotification(_ notification: Notification) {
        // Handle starting workout from notification
        if let userInfo = notification.userInfo,
           let workoutTypeString = userInfo["workoutType"] as? String,
           let duration = userInfo["duration"] as? TimeInterval,
           let workoutType = WorkoutType(rawValue: workoutTypeString) {
            
            // Create and show workout
            appState.pendingWorkout = Workout(
                name: "\(Int(duration / 60))-Min \(workoutType.rawValue)",
                duration: duration,
                type: workoutType,
                difficulty: .beginner,
                instructions: getDefaultInstructions(for: workoutType),
                equipment: [.none],
                targetMuscles: [.fullBody]
            )
            appState.showingWorkoutPlayer = true
        }
    }
    
    private func handleOpenGapNotification(_ notification: Notification) {
        // Navigate to home tab to show the gap
        appState.selectedTab = .home
    }
    
    private func getDefaultInstructions(for type: WorkoutType) -> [String] {
        switch type {
        case .breathing:
            return ["Take a slow, deep breath in", "Hold it for a moment", "Let it all out slowly", "Feel that calm? Do it again"]
        case .stretching:
            return ["Gentle neck rolls to release tension", "Shoulder shrugs to drop the stress", "Arm circles to wake everything up", "Twist that torso and feel the stretch"]
        case .hiit:
            return ["Power through jumping jacks", "Get those knees up high", "Burpees - you've got this", "Mountain climbers to finish strong"]
        case .strength:
            return ["Push-ups at your own pace", "Squats like you mean it", "Hold that plank with pride", "Lunges to round it out"]
        case .cardio:
            return ["March it out, stay moving", "Butt kicks for that energy boost", "Pretend jump rope if you need to", "Shadow box away the stress"]
        case .dadKid:
            return ["Animal walks around the space", "Dance party - let them pick the song", "Simon says (you be Simon)", "Victory high fives all around"]
        }
    }
}

// AppState is now defined in Core/AppState.swift
