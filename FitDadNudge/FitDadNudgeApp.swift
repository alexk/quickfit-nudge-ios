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
    
    private let notificationDelegate = NotificationDelegate()
    
    init() {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
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
            return ["Take a deep breath in", "Hold", "Exhale slowly", "Repeat"]
        case .stretching:
            return ["Neck rolls", "Shoulder shrugs", "Arm circles", "Torso twists"]
        case .hiit:
            return ["Jumping jacks", "High knees", "Burpees", "Mountain climbers"]
        case .strength:
            return ["Push-ups", "Squats", "Plank", "Lunges"]
        case .cardio:
            return ["March in place", "Butt kicks", "Jump rope", "Shadow boxing"]
        case .dadKid:
            return ["Animal walks", "Dance party", "Simon says", "High fives"]
        }
    }
}

// AppState is now defined in Core/AppState.swift
