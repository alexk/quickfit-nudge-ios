# FitDad Nudge - Remaining Tasks Checklist

## 🔴 Critical Issues to Fix

### 1. Missing Type Definitions
- [ ] Create `WorkoutType` enum in `Models/Workout.swift` (required by CalendarManager)
- [ ] Ensure `Workout` model is properly defined with all required properties
- [ ] Fix imports in all files to ensure types are accessible

### 2. Platform-Specific Code Issues
- [ ] Fix UIKit-dependent code in `View+Accessibility.swift` for macOS compatibility
- [ ] Add platform conditionals (#if canImport(UIKit)) around iOS-specific code
- [ ] Replace UIAccessibility with cross-platform alternatives

### 3. Build Configuration
- [ ] Configure bundle identifiers in Xcode (currently using default "abk.FitDadNudge")
- [ ] Set up code signing with your Apple Developer account
- [ ] Configure CloudKit container identifier
- [ ] Add app groups for widget/watch app data sharing

### 4. Missing Dependencies/Files
- [ ] Ensure all model files are properly created and imported
- [ ] Check that all view files can find their required types
- [ ] Verify AuthenticationManager is accessible where needed

## 📱 iOS-Specific Setup

1. **In Xcode Project Settings:**
   - [ ] Change bundle identifier from "abk.FitDadNudge" to your own
   - [ ] Select your development team
   - [ ] Enable required capabilities:
     - [ ] Sign in with Apple
     - [ ] CloudKit
     - [ ] HealthKit
     - [ ] App Groups
     - [ ] Push Notifications

2. **Info.plist Entries (already added):**
   - ✅ Calendar access descriptions
   - ✅ Health data descriptions
   - ✅ Notification descriptions
   - ✅ Camera usage description
   - ✅ Motion usage description

## 🖥 macOS-Specific Setup

1. **Code Adjustments:**
   - [ ] Remove or conditionally compile UIKit-dependent code
   - [ ] Replace iOS-specific UI elements with macOS equivalents
   - [ ] Adjust navigation patterns for macOS

2. **Entitlements:**
   - [ ] Add macOS-specific entitlements if needed
   - [ ] Configure sandboxing appropriately

## 🧪 Testing Requirements

1. **Unit Tests:**
   - ✅ WorkoutTests
   - ✅ GamificationTests
   - ✅ PerformanceTests
   - [ ] CalendarManager tests
   - [ ] AuthenticationManager tests
   - [ ] SubscriptionManager tests

2. **UI Tests:**
   - [ ] Create basic UI test flow
   - [ ] Test onboarding flow
   - [ ] Test workout player
   - [ ] Test subscription flow

## 📦 External Dependencies

Currently, the project has no external dependencies. If you need to add any:

1. **For Swift Package Manager:**
   - [ ] Add dependencies in Xcode: File → Add Package Dependencies
   - [ ] Common packages you might need:
     - Amplitude iOS SDK (for analytics)
     - Firebase SDK (for Crashlytics)

## 🚀 Launch Preparation (Milestone 8)

1. **App Store Assets:**
   - [ ] App icon (1024x1024)
   - [ ] Screenshots for all supported devices
   - [ ] App preview video (optional)
   - [ ] App Store description
   - [ ] Keywords for ASO

2. **Legal:**
   - [ ] Privacy policy
   - [ ] Terms of service
   - [ ] EULA if required

3. **TestFlight:**
   - [ ] Upload first build
   - [ ] Create beta testing group
   - [ ] Gather feedback

## 📝 Next Immediate Steps

1. **Open the project in Xcode**
2. **Configure your development team and bundle ID**
3. **Try building for iOS Simulator first**
4. **Fix any remaining compilation errors shown in Xcode**
5. **Test basic functionality**
6. **Then try building for macOS**

## 🛠 Known Issues Summary

1. **WorkoutType not found** - Need to verify Models/Workout.swift has this enum
2. **UIKit on macOS** - Need platform conditionals in View+Accessibility.swift
3. **Missing imports** - Some files can't find types defined in other files
4. **Bundle ID conflict** - Need to change from default "abk.FitDadNudge"

## 📱 Supported Platforms

- ✅ iOS 16.0+
- ✅ macOS 13.0+
- ❌ visionOS (removed as requested)
- 🔄 watchOS (companion app created but needs testing)
- 🔄 Widget Extension (created but needs testing) 