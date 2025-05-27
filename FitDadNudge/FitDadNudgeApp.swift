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

// MARK: - App State
final class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var showingOnboarding = false
    
    enum Tab: Int, CaseIterable {
        case home
        case streaks
        case library
        case kids
        case settings
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .streaks: return "Streaks"
            case .library: return "Library"
            case .kids: return "Kids"
            case .settings: return "Settings"
            }
        }
        
        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .streaks: return "flame.fill"
            case .library: return "books.vertical.fill"
            case .kids: return "figure.2.and.child.holdinghands"
            case .settings: return "gearshape.fill"
            }
        }
    }
}
