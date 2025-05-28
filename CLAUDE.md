# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FitDadNudge is an iOS/watchOS app that detects 1-5 minute calendar gaps and surfaces AI-curated micro-workouts via widgets, haptics, and rich notifications. Built with SwiftUI, CloudKit backend, and integrates with Apple Health.

## Build Commands

```bash
# Build for iOS Simulator
xcodebuild -scheme FitDadNudge -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Build with Fastlane
fastlane ios build_debug

# Run tests
fastlane ios test

# Run UI tests
fastlane ios ui_test

# Lint code
swiftlint

# Deploy to TestFlight
fastlane ios beta

# Deploy to App Store
fastlane ios release
```

## Architecture Overview

The app follows MVVM architecture with Clean Architecture principles:

```
FitDadNudge/
├── Core/                    # Business logic and managers
│   ├── Authentication/      # Sign in with Apple
│   ├── CloudKit/           # Backend sync
│   ├── Calendar/           # EventKit integration
│   └── Storage/            # Keychain & local storage
├── Models/                 # Data models
├── Views/                  # SwiftUI views organized by feature
│   ├── Authentication/
│   ├── Onboarding/
│   └── Workout/
└── Extensions/            # Swift extensions
```

### Key Components

1. **CloudKit Integration**: Primary backend using `iCloud.com.fitdad.nudge` container
2. **Calendar Gap Detection**: ML-powered algorithm to find workout opportunities
3. **Widget Extension**: Shows next workout gap on home screen
4. **watchOS Companion**: Syncs via WatchConnectivity for wrist workouts
5. **Gamification System**: Streaks, badges, and achievements

## Critical Configuration

- **Bundle IDs**:
  - iOS: `com.fitdad.nudge` (currently using `abk.FitDadNudge` - needs update)
  - watchOS: `com.fitdad.nudge.watchkitapp`
  - Widget: `com.fitdad.nudge.widget`

- **Required Capabilities**:
  - Sign in with Apple
  - CloudKit
  - HealthKit
  - App Groups (`group.com.fitdad.nudge`)
  - Push Notifications

## Known Issues & Fixes

1. **WorkoutType enum missing**: The `CalendarManager` expects a `WorkoutType` enum in `Models/Workout.swift`
2. **UIKit on macOS**: `View+Accessibility.swift` needs platform conditionals for macOS compatibility
3. **Bundle ID conflict**: Change from default "abk.FitDadNudge" in Xcode project settings

## Testing Strategy

- **Unit Tests**: Located in `FitDadNudgeTests/`
- **UI Tests**: Located in `FitDadNudgeUITests/`
- **Performance Targets**:
  - Widget render time: < 150ms p95
  - Memory usage: < 150MB
  - Crash-free sessions: ≥ 99.3%

## Development Workflow

1. Branch from `develop` for features
2. Follow conventional commits: `feat(scope): message`
3. Ensure all tests pass before PR
4. Code review required for merge
5. Deploy to TestFlight from `main` branch