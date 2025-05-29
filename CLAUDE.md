# CLAUDE.md

> **📝 Note**: Keep this file updated as the project evolves. Add new learnings, patterns, and best practices discovered during development.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**QuickFit Nudge** (formerly FitDadNudge) is an iOS/watchOS app that detects 1-5 minute calendar gaps and surfaces intelligent micro-workouts via widgets, haptics, and rich notifications. Built with SwiftUI, CloudKit backend, and integrates with Apple Health.

### Rebranding Notes
- **Old**: FitDad Nudge (dad-focused)
- **New**: QuickFit Nudge (inclusive for all busy people)
- Updated all user-facing copy to be inclusive
- Changed `dadKid` → `Family Challenge`, `isDadKidFriendly` → `isFamilyFriendly`

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -project QuickFitNudge.xcodeproj -scheme QuickFitNudge -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' build

# Build for device
xcodebuild -project QuickFitNudge.xcodeproj -scheme QuickFitNudge -destination 'platform=iOS,name=Your Device' build

# Run tests
xcodebuild test -project QuickFitNudge.xcodeproj -scheme QuickFitNudge -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# Build verification
xcodebuild -project QuickFitNudge.xcodeproj -scheme QuickFitNudge clean build

# SwiftLint (configured in .swiftlint.yml)
swiftlint

# Note: No Fastlane currently configured - using direct xcodebuild commands
```

## Architecture Overview

The app follows MVVM architecture with Clean Architecture principles:

```
QuickFitNudge/
├── Core/                    # Business logic and managers
│   ├── Analytics/           # User analytics and tracking
│   ├── Authentication/      # User authentication (Sign in with Apple)
│   ├── Calendar/           # EventKit integration & gap detection
│   ├── CloudKit/           # Cloud storage & sync
│   ├── Logging/            # Structured logging (Logger.swift)
│   ├── Notifications/      # Smart workout reminders
│   ├── Performance/        # Performance monitoring
│   ├── Storage/            # Local storage (Keychain)
│   ├── Subscription/       # StoreKit 2 integration
│   └── Watch/              # WatchConnectivity
├── Models/                 # Data models
│   ├── Gamification.swift  # Streaks and achievements
│   ├── User.swift          # User profile
│   └── Workout.swift       # Exercise definitions & sessions
├── Views/                  # SwiftUI views organized by feature
│   ├── Authentication/     # Login/signup flows
│   ├── Gamification/       # Streaks and rewards
│   ├── Home/              # Main dashboard
│   ├── Kids/              # Family features
│   ├── Library/           # Workout library
│   ├── Onboarding/        # First-time user experience
│   ├── Settings/          # App preferences
│   ├── Subscription/      # Paywall and billing
│   └── Workout/           # Exercise player & tracking
├── Extensions/            # Swift extensions
│   └── View+Accessibility.swift  # Accessibility helpers
├── Assets.xcassets/       # Images & colors
│   └── AppIcon.appiconset/ # App icons (placeholder + README)
└── Info.plist            # App permissions & configuration
```

### Key Components

1. **CloudKit Integration**: Backend using `iCloud.com.quickfit.nudge` container
2. **Gap Detection Engine**: Finds 1-5 minute calendar gaps with quality scoring
3. **Structured Logging**: Uses os_log with categorized logging (Logger.swift)
4. **Widget Extension**: Shows next workout gap on home screen
5. **watchOS Companion**: Syncs via WatchConnectivity for wrist workouts
6. **Gamification System**: Streaks, achievements, and motivational messages
7. **StoreKit 2**: Premium subscription management
8. **Accessibility**: Comprehensive VoiceOver and accessibility support

## Critical Configuration

### Bundle Identifiers
- **iOS**: `com.quickfit.nudge` (currently using `abk.QuickFitNudge` - needs update)
- **watchOS**: `com.quickfit.nudge.watchkitapp`
- **Widget**: `com.quickfit.nudge.widget`

### Required Capabilities
- Sign in with Apple
- CloudKit
- HealthKit
- App Groups (`group.com.quickfit.nudge`)
- Push Notifications

### Platform Support
- **iOS**: 16.0+ (verified)
- **macOS**: 13.0+ (with platform conditionals)
- **watchOS**: Companion app included
- **Widget**: iOS 16+ widget extension

## Development Best Practices

### Logging Standards
**✅ Use structured logging instead of print statements:**
```swift
// ❌ Don't use
print("Error occurred: \(error)")

// ✅ Use categorized logging
logError("Calendar access failed: \(error)", category: .calendar)
logInfo("User authenticated successfully", category: .auth)
logDebug("Processing workout completion", category: .analytics)
```

**Available categories**: `.analytics`, `.cloudKit`, `.calendar`, `.notification`, `.watch`, `.subscription`, `.auth`, `.general`

### Error Handling
**✅ Comprehensive error handling with user-friendly messages:**
```swift
// ❌ Don't use force unwrapping
let workout = workouts.randomElement()!

// ✅ Use safe unwrapping with fallback
let workout = workouts.randomElement() ?? defaultWorkout
```

### Platform Compatibility
**✅ Use platform conditionals for UIKit code:**
```swift
#if canImport(UIKit)
import UIKit
// iOS-specific code
#endif

// Cross-platform code here
```

### Testing Patterns
**✅ Comprehensive unit test coverage:**
- Test business logic thoroughly
- Use mock classes for external dependencies
- Test error conditions and edge cases
- Verify state transitions and data persistence

### Accessibility Standards
**✅ Built-in accessibility support:**
```swift
.workoutAccessibility(name: workout.name, duration: workout.duration, type: workout.type.rawValue)
.accessibilityLabel("Clear, descriptive label")
.accessibilityHint("Double tap to activate")
```

### Code Organization
**✅ Follow established patterns:**
- Keep managers in `Core/` with single responsibility
- Use `@MainActor` for UI-bound classes
- Implement proper `deinit` for cleanup (timers, etc.)
- Use `ObservableObject` for state management

## Known Issues & Solutions ✅

### ✅ RESOLVED: Missing Type Definitions
- **Issue**: `WorkoutType` enum missing
- **Solution**: Complete enum defined in `Models/Workout.swift` with inclusive language

### ✅ RESOLVED: Platform Compatibility  
- **Issue**: UIKit code on macOS
- **Solution**: `View+Accessibility.swift` has proper `#if canImport(UIKit)` conditionals

### ✅ RESOLVED: Print Statement Cleanup
- **Issue**: Debug print statements throughout codebase
- **Solution**: Replaced with structured logging using `Logger.swift`

### ⚠️ REMAINING: Bundle ID Configuration
- **Issue**: Using default "abk.QuickFitNudge" 
- **Action**: Change in Xcode project settings to your developer account

## Testing Strategy

### Unit Tests ✅
- **Location**: `QuickFitNudgeTests/Core/`
- **Coverage**: 95+ tests covering all core managers
- **Files**: CalendarManagerTests, AuthenticationManagerTests, SubscriptionManagerTests, NotificationManagerTests, StreakManagerTests

### UI Tests 🔄
- **Location**: `QuickFitNudgeUITests/` (needs expansion)
- **Todo**: Add comprehensive UI test flows

### Performance Targets
- Widget render time: < 150ms p95
- Memory usage: < 150MB  
- Crash-free sessions: ≥ 99.3%
- Build time: < 60 seconds

## Git Workflow & Commit Standards

### Commit Message Format
```
type(scope): description

feat: add new feature
fix: resolve bug
docs: update documentation
test: add test coverage
refactor: improve code structure
style: format code
chore: maintenance tasks
```

### Branch Strategy
- `main`: Production-ready code
- Feature branches: `feature/description`
- Release branches: `release/version`

## External Dependencies

**Current**: Zero external dependencies (intentional for simplicity)

**Potential Future Additions**:
- Amplitude iOS SDK (analytics)
- Firebase Crashlytics (crash reporting)
- SwiftLint (code quality - configured but not required)

## App Store Preparation Checklist

### ✅ Code Ready
- All compilation errors resolved
- Comprehensive test coverage
- Structured logging implemented
- Platform compatibility verified
- Inclusive language throughout

### 🔄 Assets Needed
- [ ] Final app icon (1024x1024) - placeholder currently in place
- [ ] Screenshots for all device sizes
- [ ] App Store description
- [ ] Privacy policy and terms of service

### 🔄 Configuration Needed
- [ ] Bundle IDs updated to your developer account
- [ ] Code signing certificates
- [ ] CloudKit container configured
- [ ] App Groups enabled
- [ ] Required capabilities enabled

## Performance Optimization Lessons

1. **Memory Management**: Always invalidate timers in `deinit`
2. **State Management**: Use `@MainActor` for UI updates
3. **Logging Performance**: Use appropriate log levels (debug only in DEBUG builds)
4. **Calendar Access**: Cache gap detection results to avoid repeated EventKit calls

## Security Best Practices

1. **Keychain Storage**: Sensitive data stored securely in KeychainManager
2. **CloudKit Privacy**: User data stays in private database
3. **Logging Safety**: Never log sensitive user information
4. **Error Messages**: User-friendly without exposing internal details

---

## 🔄 Update History

**Latest Update**: 2025-05-28
- Added comprehensive automation improvements
- Documented structured logging patterns
- Added inclusive language guidelines
- Expanded testing strategy documentation
- Added performance optimization notes

**Next Review**: Keep updating as new patterns and learnings emerge during development.