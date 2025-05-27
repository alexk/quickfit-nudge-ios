# FitDad Nudge

Micro-workouts for busy dads - an iOS & watchOS app that finds workout gaps in your calendar and nudges you to stay fit.

## 🎯 Overview

FitDad Nudge is an iOS + watchOS app that detects 1- to 5-minute calendar gaps and surfaces AI-curated micro-workouts or kid-inclusive challenges via widgets, haptics, and rich notifications.

### Key Features
- 📅 **Smart Calendar Integration** - Finds workout opportunities in your busy schedule
- ⚡ **Micro-Workouts** - 1-5 minute exercises that fit anywhere
- 👨‍👧 **Dad-Kid Challenges** - Fun activities to do with your children
- 🔥 **Streak Tracking** - Build consistency with gamification
- ⌚ **Apple Watch Support** - Start workouts from your wrist
- 📊 **Home Screen Widget** - See your next gap at a glance

## 🚀 Getting Started

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Apple Developer Account
- iOS 16.0+ device for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/fitdad-nudge.git
   cd fitdad-nudge
   ```

2. **Install dependencies**
   ```bash
   # Install Homebrew if needed
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Install required tools
   brew install swiftlint fastlane git-lfs xcbeautify
   
   # Install Ruby dependencies
   bundle install
   ```

3. **Set up environment**
   ```bash
   cp env.example .env
   # Edit .env with your values
   ```

4. **Open in Xcode**
   ```bash
   open FitDadNudge.xcodeproj
   ```

5. **Configure signing**
   - Select your team in Xcode
   - Update bundle identifiers if needed

## 📱 Project Structure

```
FitDadNudge/
├── Core/
│   ├── Authentication/     # Sign in with Apple
│   ├── CloudKit/          # Backend integration
│   └── Storage/           # Keychain & local storage
├── Models/                # Data models
├── Views/                 # SwiftUI views
│   ├── Authentication/    # Login flow
│   ├── Onboarding/       # First-time setup
│   └── Main/             # Tab views
├── Assets.xcassets/      # Images & colors
└── Info.plist           # App permissions
```

## 🏗️ Architecture

- **UI Framework**: SwiftUI
- **Architecture Pattern**: MVVM
- **Backend**: CloudKit
- **Authentication**: Sign in with Apple
- **Persistence**: Core Data + CloudKit
- **Analytics**: Amplitude
- **Crash Reporting**: Firebase Crashlytics

## 🔧 Development

### Running the app
```bash
# Build and run in simulator
xcodebuild -scheme FitDadNudge -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Or use Fastlane
fastlane ios build_debug
```

### Running tests
```bash
fastlane ios test
```

### Code quality
```bash
# Run SwiftLint
swiftlint

# Run all checks
fastlane ios lint
```

## 📦 Deployment

### TestFlight
```bash
fastlane ios beta
```

### App Store
```bash
fastlane ios release
```

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes following our [commit guidelines](docs/Dev_Standards.md)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

## 📄 Documentation

- [Product Requirements](docs/PRD_v1.md)
- [Implementation Plan](docs/Implementation_Plan.md)
- [Development Standards](docs/Dev_Standards.md)
- [Setup Guide](docs/Setup_Guide.md)
- [Implementation Log](docs/Impl_Log.md)

## 🎯 Roadmap

### MVP (12 weeks)
- [x] Week 1-2: Foundation & Authentication
- [ ] Week 3-4: Calendar Integration & ML
- [ ] Week 5-6: Workout System
- [ ] Week 7-8: Gamification
- [ ] Week 9: Monetization
- [ ] Week 10: Analytics & Polish
- [ ] Week 11: Beta Testing
- [ ] Week 12: Launch Prep

### Post-MVP
- Family plans
- Social features
- Android version
- Web dashboard

## 📈 Success Metrics

- **D1 Retention**: ≥ 65%
- **Crash-free sessions**: ≥ 99.3%
- **Widget render time**: < 150ms p95
- **Avg workouts/day**: ≥ 2

## ⚖️ License

This project is proprietary software. All rights reserved.

## 👥 Team

- **Product**: Your Product Manager
- **Engineering**: Your Dev Team
- **Design**: Your Design Team
- **QA**: Your QA Team

## 📞 Support

- Email: support@fitdadnudge.com
- Twitter: @fitdadnudge
- Website: https://fitdadnudge.com

---

Built with ❤️ for busy dads everywhere 