//
//  FitDadNudgeApp.swift
//  FitDadNudge
//
//  Created by Alex Koff on 5/26/25.
//

import SwiftUI

@main
struct FitDadNudgeApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(appState)
                .task {
                    await authManager.checkAuthenticationStatus()
                }
        }
    }
}

// AppState is now defined in Core/AppState.swift
