import SwiftUI
import UIKit

// MARK: - Accessibility Extensions
extension View {
    
    // MARK: - Workout Accessibility
    
    func workoutAccessibility(name: String, duration: Int, type: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(name), \(duration) minute \(type) workout")
            .accessibilityHint("Double tap to start workout")
    }
    
    func workoutCompletionAccessibility(workout: String, duration: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Workout completed: \(workout), duration \(duration)")
            .accessibilityAddTraits(.isStaticText)
    }
    
    // MARK: - Gap Accessibility
    
    func gapAccessibility(minutes: Int, quality: String, time: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(minutes) minute workout gap at \(time), quality: \(quality)")
            .accessibilityHint("Double tap to view workout options")
    }
    
    // MARK: - Streak Accessibility
    
    func streakAccessibility(type: String, count: Int, isActive: Bool) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(type) streak: \(count) days\(isActive ? ", active" : ", inactive")")
            .accessibilityAddTraits(.isStaticText)
    }
    
    // MARK: - Achievement Accessibility
    
    func achievementAccessibility(name: String, isUnlocked: Bool, progress: Int = 0, target: Int = 0) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isUnlocked ? 
                "\(name) achievement unlocked" : 
                "\(name) achievement: \(progress) of \(target) completed")
            .accessibilityAddTraits(isUnlocked ? [.isStaticText, .startsMediaSession] : .isStaticText)
    }
    
    // MARK: - Navigation Accessibility
    
    func tabAccessibility(title: String, isSelected: Bool) -> some View {
        self
            .accessibilityLabel("\(title) tab")
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint(isSelected ? "Currently selected" : "Double tap to select")
    }
    
    // MARK: - Button Accessibility
    
    func primaryButtonAccessibility(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double tap to activate")
    }
    
    func timerAccessibility(elapsed: String, remaining: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Timer: \(elapsed) elapsed, \(remaining) remaining")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Progress Accessibility
    
    func progressAccessibility(value: Double, label: String) -> some View {
        self
            .accessibilityLabel("\(label): \(Int(value * 100)) percent complete")
            .accessibilityValue("\(Int(value * 100)) percent")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    // MARK: - Announcement Helpers
    
    func announceChange(_ announcement: String) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }
    
    func announceScreenChange(_ screenName: String) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .screenChanged, argument: "\(screenName) screen")
            }
        }
    }
}

// MARK: - Accessibility Identifiers
struct AccessibilityIdentifiers {
    // Authentication
    static let signInButton = "sign_in_button"
    static let signOutButton = "sign_out_button"
    
    // Navigation
    static let homeTab = "home_tab"
    static let streaksTab = "streaks_tab"
    static let libraryTab = "library_tab"
    static let kidsTab = "kids_tab"
    static let settingsTab = "settings_tab"
    
    // Workout
    static let startWorkoutButton = "start_workout_button"
    static let pauseWorkoutButton = "pause_workout_button"
    static let resumeWorkoutButton = "resume_workout_button"
    static let completeWorkoutButton = "complete_workout_button"
    static let workoutTimer = "workout_timer"
    static let workoutProgress = "workout_progress"
    
    // Gap Detection
    static let nextGapCard = "next_gap_card"
    static let refreshGapsButton = "refresh_gaps_button"
    
    // Subscription
    static let subscribeButton = "subscribe_button"
    static let restorePurchasesButton = "restore_purchases_button"
    
    // Settings
    static let notificationToggle = "notification_toggle"
    static let calendarAccessButton = "calendar_access_button"
    static let healthKitToggle = "healthkit_toggle"
}

// MARK: - Dynamic Type Support
extension View {
    func dynamicTypeSize(_ range: ClosedRange<DynamicTypeSize>) -> some View {
        self.dynamicTypeSize(range)
    }
    
    func scaledFont(_ style: Font.TextStyle, size: CGFloat) -> Font {
        return Font.system(size: UIFontMetrics(forTextStyle: UIFont.TextStyle(style)).scaledValue(for: size))
    }
}

// MARK: - High Contrast Support
extension View {
    func adaptiveBackground() -> some View {
        self.modifier(AdaptiveBackgroundModifier())
    }
    
    func adaptiveForeground() -> some View {
        self.modifier(AdaptiveForegroundModifier())
    }
}

struct AdaptiveBackgroundModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast
    
    func body(content: Content) -> some View {
        content
            .background(contrast == .increased ? Color.black : Color(.systemGray6))
    }
}

struct AdaptiveForegroundModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) var contrast
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(contrast == .increased ? .white : .primary)
    }
}

// MARK: - Reduce Motion Support
extension View {
    func reducedMotionAnimation<V>(_ value: V) -> some View where V: Equatable {
        self.modifier(ReducedMotionModifier(value: value))
    }
}

struct ReducedMotionModifier<V>: ViewModifier where V: Equatable {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let value: V
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : .default, value: value)
    }
}

// MARK: - VoiceOver Helpers
extension View {
    var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    func voiceOverOnly() -> some View {
        self.opacity(isVoiceOverRunning ? 1 : 0)
    }
    
    func hideFromVoiceOver() -> some View {
        self.accessibilityHidden(!isVoiceOverRunning)
    }
}

// MARK: - Font Style Extension
extension Font.TextStyle {
    init(_ textStyle: UIFont.TextStyle) {
        switch textStyle {
        case .largeTitle: self = .largeTitle
        case .title1: self = .title
        case .title2: self = .title2
        case .title3: self = .title3
        case .headline: self = .headline
        case .subheadline: self = .subheadline
        case .body: self = .body
        case .callout: self = .callout
        case .footnote: self = .footnote
        case .caption1: self = .caption
        case .caption2: self = .caption2
        default: self = .body
        }
    }
} 