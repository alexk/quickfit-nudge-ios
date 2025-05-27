# FitDad Nudge — Setup & Operations Guide

## 1. Development Environment Setup

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **iOS Simulator**: iOS 16.0+
- **watchOS Simulator**: watchOS 9.0+
- **Git**: 2.39.0+

### Initial Setup

#### 1. Install Xcode
```bash
# Install from Mac App Store or:
xcode-select --install
```

#### 2. Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 3. Install Required Tools
```bash
# Install SwiftLint for code quality
brew install swiftlint

# Install Fastlane for deployment automation
brew install fastlane

# Install Git LFS for large files
brew install git-lfs
git lfs install

# Install xcbeautify for prettier build output
brew install xcbeautify
```

#### 4. Clone Repository
```bash
git clone https://github.com/your-org/fitdad-nudge.git
cd fitdad-nudge
```

#### 5. Install Ruby Dependencies
```bash
# Install bundler if needed
gem install bundler

# Install Ruby dependencies (for Fastlane)
bundle install
```

#### 6. Configure Git Hooks
```bash
# Setup pre-commit hooks
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Project Configuration

#### 1. Open Project
```bash
open FitDadNudge.xcodeproj
```

#### 2. Configure Signing
1. Select the project in navigator
2. Select each target (iOS, watchOS, Widget)
3. In "Signing & Capabilities":
   - Select your team
   - Ensure "Automatically manage signing" is checked
   - Bundle identifiers should be:
     - iOS: `com.fitdad.nudge`
     - watchOS: `com.fitdad.nudge.watchkitapp`
     - Widget: `com.fitdad.nudge.widget`

#### 3. Environment Configuration
Create `.env` file in project root:
```bash
cp .env.example .env
```

Edit `.env` with your values:
```bash
# Development Environment Variables
AMPLITUDE_API_KEY=dev_key_here
CLOUDKIT_CONTAINER=iCloud.com.fitdad.nudge
BUNDLE_IDENTIFIER=com.fitdad.nudge
DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

## 2. Apple Developer Account Setup

### App Store Connect Configuration

#### 1. Create App ID
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Create App IDs for:
   - `com.fitdad.nudge` (iOS App)
   - `com.fitdad.nudge.watchkitapp` (watchOS)
   - `com.fitdad.nudge.widget` (Widget)

#### 2. Enable Capabilities
For each App ID, enable:
- **iOS App**:
  - Sign In with Apple
  - CloudKit
  - Push Notifications
  - HealthKit
  - App Groups (create: `group.com.fitdad.nudge`)
  - Associated Domains
  
- **watchOS App**:
  - CloudKit
  - HealthKit
  - App Groups (same as iOS)

- **Widget**:
  - App Groups (same as iOS)

#### 3. Create CloudKit Container
1. Go to CloudKit Dashboard
2. Create container: `iCloud.com.fitdad.nudge`
3. Create schema:

```sql
-- Users Record Type
recordName: String (unique)
email: String
displayName: String
createdAt: Date
subscriptionStatus: String

-- Workouts Record Type
recordName: String (unique)
name: String
duration: Double
gifURL: String
category: String
difficulty: Int64

-- Completions Record Type
recordName: String (unique)
userReference: Reference(Users)
workoutReference: Reference(Workouts)
completedAt: Date
duration: Double

-- Streaks Record Type
recordName: String (unique)
userReference: Reference(Users)
currentStreak: Int64
longestStreak: Int64
lastCompletedDate: Date
```

#### 4. Configure Push Notifications
1. Create Push Notification certificate
2. Download and install in Keychain
3. Export as .p12 for CI/CD

### TestFlight Setup

#### 1. Create App in App Store Connect
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app:
   - Platform: iOS
   - Name: FitDad Nudge
   - Primary Language: English (U.S.)
   - Bundle ID: `com.fitdad.nudge`
   - SKU: `fitdadnudge001`

#### 2. Configure TestFlight
1. Go to TestFlight tab
2. Create Internal Testing group
3. Add test users
4. Configure test information

## 3. Third-Party Service Setup

### Amplitude Analytics

#### 1. Create Amplitude Account
1. Sign up at [amplitude.com](https://amplitude.com)
2. Create new project: "FitDad Nudge"
3. Get API keys for Dev and Prod environments

#### 2. Configure Events
Set up the following events in Amplitude:
- `app_launch`
- `permission_granted`
- `nudge_shown`
- `nudge_started`
- `nudge_completed`
- `streak_updated`
- `paywall_view`
- `subscription_started`

### Firebase (Crashlytics Only)

#### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project: "FitDad Nudge"
3. Add iOS app with bundle ID
4. Download `GoogleService-Info.plist`

#### 2. Add to Project
```bash
# Place in project root
cp ~/Downloads/GoogleService-Info.plist FitDadNudge/
```

## 4. Secrets Management

### Local Development
Use `.env` file (git-ignored) for local secrets.

### CI/CD Secrets
Configure in GitHub repository settings:

```yaml
# Required GitHub Secrets
APPLE_ID                    # Apple ID for deployment
APP_STORE_CONNECT_API_KEY   # Base64 encoded .p8 file
APP_STORE_CONNECT_KEY_ID    # Key ID from App Store Connect
APP_STORE_CONNECT_ISSUER_ID # Issuer ID
MATCH_PASSWORD              # Fastlane match password
AMPLITUDE_API_KEY_DEV       # Development API key
AMPLITUDE_API_KEY_PROD      # Production API key
```

### Fastlane Match Setup
```bash
# Initialize match for code signing
fastlane match init

# Generate certificates
fastlane match development
fastlane match appstore
```

## 5. Build & Run Instructions

### Local Development

#### Build & Run iOS App
```bash
# Command line build
xcodebuild -scheme FitDadNudge -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Or use Fastlane
fastlane ios build_debug
```

#### Build & Run watchOS App
1. In Xcode, select watchOS scheme
2. Choose Apple Watch simulator
3. Press Cmd+R to build and run

#### Build Widget
Widget builds automatically with main app.

### Testing

#### Run Unit Tests
```bash
# Command line
xcodebuild test -scheme FitDadNudge -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Or use Fastlane
fastlane ios test
```

#### Run UI Tests
```bash
fastlane ios ui_test
```

#### Manual Testing Checklist
- [ ] Sign in with Apple works
- [ ] Calendar permissions requested
- [ ] Widget appears on home screen
- [ ] Watch app syncs with phone
- [ ] Workouts complete successfully
- [ ] Streaks update correctly
- [ ] Subscription flow works in sandbox

## 6. CI/CD Pipeline

### GitHub Actions Configuration

#### `.github/workflows/ci.yml`
```yaml
name: CI

on:
  push:
    branches: [ develop, main ]
  pull_request:
    branches: [ develop ]

jobs:
  test:
    runs-on: macos-13
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Xcode
      uses: maxim-lobanov/setup-xcode@v1
      with:
        xcode-version: '15.0'
    
    - name: Install dependencies
      run: |
        brew install swiftlint
        bundle install
    
    - name: Run tests
      run: fastlane ios test
    
    - name: Run SwiftLint
      run: swiftlint
```

### Deployment Process

#### Deploy to TestFlight
```bash
# Ensure you're on main branch
git checkout main
git pull origin main

# Run deployment
fastlane ios beta
```

#### Deploy to App Store
```bash
# Create release branch
git checkout -b release/1.0.0

# Update version and build number
fastlane ios bump_version version:1.0.0

# Submit to App Store
fastlane ios release
```

## 7. Monitoring & Operations

### CloudKit Dashboard
1. Monitor at [CloudKit Dashboard](https://icloud.developer.apple.com)
2. Check:
   - Request rates
   - Error rates
   - Storage usage
   - Active users

### Crashlytics Dashboard
1. View at [Firebase Console](https://console.firebase.google.com)
2. Monitor:
   - Crash-free users rate
   - Top crashes
   - Affected versions

### Amplitude Dashboard
1. Access at [Amplitude](https://analytics.amplitude.com)
2. Track:
   - User retention
   - Feature adoption
   - Conversion funnels

### Alerts Setup
Configure alerts for:
- Crash rate > 1%
- CloudKit errors > 5%
- Subscription failures > 10%

## 8. Troubleshooting

### Common Issues

#### Code Signing Issues
```bash
# Reset certificates
fastlane match nuke development
fastlane match nuke distribution
fastlane match development --force
fastlane match appstore --force
```

#### CloudKit Sync Issues
1. Check CloudKit Dashboard for errors
2. Verify container permissions
3. Check device is signed into iCloud

#### Widget Not Updating
1. Check shared App Group configuration
2. Verify timeline provider implementation
3. Check memory usage in widget

### Debug Tools

#### Enable Verbose Logging
```swift
// In AppDelegate or App struct
#if DEBUG
UserDefaults.standard.set(true, forKey: "VERBOSE_LOGGING")
#endif
```

#### CloudKit Debugging
```swift
// Enable CloudKit logging
CKContainer.default().accountStatus { status, error in
    print("CloudKit Status: \(status)")
}
```

## 9. Release Checklist

### Pre-Release
- [ ] All tests passing
- [ ] No SwiftLint warnings
- [ ] Version number updated
- [ ] Release notes written
- [ ] Screenshots updated
- [ ] App Store description current

### Release
- [ ] Create release branch
- [ ] Submit to TestFlight
- [ ] Internal testing complete
- [ ] External beta testing complete
- [ ] Submit to App Store
- [ ] Monitor crash reports

### Post-Release
- [ ] Tag release in Git
- [ ] Update documentation
- [ ] Monitor user feedback
- [ ] Plan next sprint

---

This guide provides everything needed to set up, develop, test, and ship FitDad Nudge. Keep it updated as the project evolves! 