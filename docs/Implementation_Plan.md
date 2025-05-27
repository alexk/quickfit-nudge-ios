# FitDad Nudge — Implementation Blueprint

## 1. Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                     │
├─────────────────────────────────────────────────────────────┤
│  Presentation Layer                                          │
│  ├─ Views (SwiftUI)                                         │
│  ├─ ViewModels (ObservableObject)                          │
│  └─ Navigation (NavigationStack)                           │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer                                                │
│  ├─ Use Cases                                              │
│  ├─ Entities                                               │
│  └─ Repositories (Protocols)                               │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                  │
│  ├─ CloudKit Manager                                       │
│  ├─ Core Data Stack                                        │
│  ├─ EventKit Manager                                       │
│  └─ HealthKit Manager                                      │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure                                              │
│  ├─ Analytics (Amplitude)                                   │
│  ├─ Crash Reporting (Crashlytics)                         │
│  └─ StoreKit Manager                                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    watchOS App Extension                     │
├─────────────────────────────────────────────────────────────┤
│  ├─ Workout Session Manager                                 │
│  ├─ WatchConnectivity Handler                              │
│  └─ Haptic Feedback Controller                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      Widget Extension                        │
├─────────────────────────────────────────────────────────────┤
│  ├─ Timeline Provider                                       │
│  ├─ Widget Views                                            │
│  └─ Shared Container Access                                │
└─────────────────────────────────────────────────────────────┘
```

### Key Frameworks & Dependencies

| Component | Framework/Library | Version | Purpose |
|-----------|------------------|---------|---------|
| UI | SwiftUI | 5.0+ | Primary UI framework |
| Data Persistence | CloudKit | Latest | Cloud sync & storage |
| | Core Data | Latest | Local cache |
| Calendar | EventKit | Latest | Calendar access |
| Health | HealthKit | Latest | Activity tracking |
| ML | Core ML | 5.0+ | Gap detection |
| Payments | StoreKit 2 | Latest | Subscriptions |
| Analytics | Amplitude | 8.15.0 | User analytics |
| Crash Reporting | Firebase Crashlytics | 10.18.0 | Crash tracking |
| Networking | URLSession | Native | API calls |
| Watch | WatchConnectivity | Latest | iPhone-Watch sync |

### Third-Party Services

| Service | Purpose | Integration Type |
|---------|---------|------------------|
| Apple CloudKit | Primary backend | Native SDK |
| Sign in with Apple | Authentication | Native SDK |
| Amplitude | Analytics | SDK |
| Firebase | Crashlytics only | SDK |
| RevenueCat (optional) | Subscription management | SDK |

## 2. Milestone Table (12-Week Sprint)

| Week | Milestone | Key Deliverables | Exit Criteria |
|------|-----------|------------------|---------------|
| 1-2 | **Foundation & Auth** | • Project setup<br>• Sign in with Apple<br>• Core navigation<br>• CI/CD pipeline | • Successful auth flow<br>• Build passes all tests<br>• TestFlight distribution working |
| 3-4 | **Calendar Integration & ML** | • EventKit integration<br>• Gap detection algorithm<br>• Core ML model<br>• Basic widget | • 85%+ gap detection accuracy<br>• Widget displays next gap<br>• Calendar permissions handled |
| 5-6 | **Workout System** | • Workout player UI<br>• GIF/Video rendering<br>• watchOS app<br>• Watch sync | • 50 workouts playable<br>• Watch sync < 1s<br>• Smooth animations |
| 7-8 | **Gamification** | • Streak system<br>• Badge engine<br>• CloudKit sync<br>• Referral system | • Streaks persist correctly<br>• CloudKit sync < 5s<br>• QR codes generate |
| 9 | **Monetization** | • StoreKit 2 integration<br>• Paywall UI<br>• Subscription logic | • Sandbox purchases work<br>• Receipt validation<br>• Restore purchases |
| 10 | **Analytics & Polish** | • Amplitude integration<br>• Crashlytics setup<br>• Performance optimization | • All events firing<br>• < 150ms widget load<br>• Memory < 150MB |
| 11 | **Beta Testing** | • Closed beta (200 users)<br>• Bug fixes<br>• Performance tuning | • D1 retention ≥ 65%<br>• Crash-free ≥ 99%<br>• User feedback incorporated |
| 12 | **Launch Prep** | • Public TestFlight<br>• App Store assets<br>• Launch marketing | • App Store ready<br>• All KPIs green<br>• Go/no-go decision |

## 3. Task Breakdown

### Milestone 1: Foundation & Auth (Weeks 1-2)

#### Epic 1.1: Project Setup
- **Story 1.1.1**: Initialize Xcode project with iOS/watchOS/Widget targets
- **Story 1.1.2**: Configure Swift Package Manager dependencies
- **Story 1.1.3**: Set up SwiftLint and code formatting rules
- **Story 1.1.4**: Create base folder structure and architecture

#### Epic 1.2: Authentication
- **Story 1.2.1**: Implement Sign in with Apple
- **Story 1.2.2**: Create user onboarding flow
- **Story 1.2.3**: Implement secure token storage in Keychain
- **Story 1.2.4**: Handle auth state persistence

#### Epic 1.3: CI/CD Pipeline
- **Story 1.3.1**: Set up GitHub Actions for iOS
- **Story 1.3.2**: Configure automated testing
- **Story 1.3.3**: Set up Fastlane for TestFlight deployment
- **Story 1.3.4**: Configure code signing and provisioning

### Milestone 2: Calendar Integration & ML (Weeks 3-4)

#### Epic 2.1: EventKit Integration
- **Story 2.1.1**: Request calendar permissions
- **Story 2.1.2**: Fetch calendar events for next 48 hours
- **Story 2.1.3**: Implement gap detection algorithm
- **Story 2.1.4**: Handle multiple calendar sources

#### Epic 2.2: ML Model
- **Story 2.2.1**: Create Core ML training pipeline
- **Story 2.2.2**: Train gap quality classifier
- **Story 2.2.3**: Integrate model into app
- **Story 2.2.4**: Add confidence threshold logic

#### Epic 2.3: Widget Development
- **Story 2.3.1**: Create widget extension target
- **Story 2.3.2**: Implement timeline provider
- **Story 2.3.3**: Design widget UI variants
- **Story 2.3.4**: Set up shared data container

### Milestone 3: Workout System (Weeks 5-6)

#### Epic 3.1: Workout Player
- **Story 3.1.1**: Create workout data model
- **Story 3.1.2**: Build GIF player component
- **Story 3.1.3**: Implement countdown timer
- **Story 3.1.4**: Add completion tracking

#### Epic 3.2: watchOS App
- **Story 3.2.1**: Create watchOS target
- **Story 3.2.2**: Implement workout UI for watch
- **Story 3.2.3**: Add haptic feedback patterns
- **Story 3.2.4**: Handle background sessions

#### Epic 3.3: Device Sync
- **Story 3.3.1**: Set up WatchConnectivity
- **Story 3.3.2**: Implement bidirectional data sync
- **Story 3.3.3**: Handle offline scenarios
- **Story 3.3.4**: Optimize sync performance

### Milestone 4: Gamification (Weeks 7-8)

#### Epic 4.1: Streak System
- **Story 4.1.1**: Design streak data model
- **Story 4.1.2**: Implement streak calculation logic
- **Story 4.1.3**: Create streak UI components
- **Story 4.1.4**: Add streak notifications

#### Epic 4.2: Badges & Achievements
- **Story 4.2.1**: Define badge criteria
- **Story 4.2.2**: Create badge artwork
- **Story 4.2.3**: Implement achievement engine
- **Story 4.2.4**: Add celebration animations

#### Epic 4.3: Social Features
- **Story 4.3.1**: Build referral system
- **Story 4.3.2**: Generate QR codes
- **Story 4.3.3**: Handle deep links
- **Story 4.3.4**: Create kid profile system

### Milestone 5: Monetization (Week 9)

#### Epic 5.1: StoreKit Integration
- **Story 5.1.1**: Configure products in App Store Connect
- **Story 5.1.2**: Implement StoreKit 2 manager
- **Story 5.1.3**: Handle purchase flows
- **Story 5.1.4**: Implement receipt validation

#### Epic 5.2: Paywall
- **Story 5.2.1**: Design paywall UI
- **Story 5.2.2**: Implement trial logic
- **Story 5.2.3**: Add restore purchases
- **Story 5.2.4**: Handle edge cases

### Milestone 6: Analytics & Polish (Week 10)

#### Epic 6.1: Analytics
- **Story 6.1.1**: Integrate Amplitude SDK
- **Story 6.1.2**: Implement event tracking
- **Story 6.1.3**: Set up user properties
- **Story 6.1.4**: Create analytics dashboard

#### Epic 6.2: Performance
- **Story 6.2.1**: Profile app performance
- **Story 6.2.2**: Optimize memory usage
- **Story 6.2.3**: Improve widget load times
- **Story 6.2.4**: Reduce battery drain

## 4. Dependencies Matrix

| Component | Dependencies | Version | Notes |
|-----------|--------------|---------|-------|
| **Xcode** | | 15.0+ | Required for iOS 17 features |
| **Swift** | | 5.9+ | For latest concurrency features |
| **iOS Deployment** | | 16.0+ | Minimum supported version |
| **watchOS Deployment** | | 9.0+ | For workout sessions |
| **CloudKit** | Apple Developer Account | Active | Container: iCloud.com.fitdad.nudge |
| **Amplitude** | API Key | - | Store in CI secrets |
| **Firebase** | GoogleService-Info.plist | - | For Crashlytics only |
| **App Store Connect** | | - | Bundle ID: com.fitdad.nudge |

### Service Account Requirements

| Service | Requirement | Setup Location |
|---------|-------------|----------------|
| Apple Developer | Paid account ($99/year) | developer.apple.com |
| CloudKit | Container created | CloudKit Dashboard |
| Sign in with Apple | Service configured | Certificates portal |
| TestFlight | App created | App Store Connect |
| GitHub Actions | Secrets configured | Repo settings |

### Environment Variables

```bash
# .env.example
AMPLITUDE_API_KEY=<AMPLITUDE_KEY>
CLOUDKIT_CONTAINER=iCloud.com.fitdad.nudge
BUNDLE_IDENTIFIER=com.fitdad.nudge
WATCHKIT_BUNDLE_IDENTIFIER=com.fitdad.nudge.watchkitapp
WIDGET_BUNDLE_IDENTIFIER=com.fitdad.nudge.widget
```

## 5. Risk Register & Mitigations

| Risk | Probability | Impact | Mitigation | Owner |
|------|-------------|--------|------------|-------|
| **Calendar ML accuracy < 85%** | Medium | High | • Fallback to rule-based detection<br>• A/B test both approaches<br>• Gather training data in beta | Tech Lead |
| **Widget performance > 150ms** | Medium | Medium | • Precompute timeline entries<br>• Optimize image loading<br>• Use shared container efficiently | iOS Dev |
| **Watch sync latency > 1s** | Low | Medium | • Queue priority messages<br>• Batch non-critical updates<br>• Test on older devices | Watch Dev |
| **CloudKit rate limits** | Low | High | • Implement exponential backoff<br>• Cache aggressively<br>• Monitor quotas | Backend Dev |
| **App Store rejection** | Low | Critical | • Pre-review with Apple<br>• Ensure COPPA compliance<br>• Clear data usage disclosure | Product Manager |
| **Content library insufficient** | Medium | Medium | • Partner with fitness influencers<br>• Create content pipeline<br>• Allow user submissions (post-MVP) | Content Lead |

## 6. Definition of Done

### Code Quality
- [ ] All tests pass (unit, integration, UI)
- [ ] Code coverage ≥ 80%
- [ ] SwiftLint warnings = 0
- [ ] Code reviewed by ≥ 1 team member
- [ ] Documentation updated

### Design
- [ ] Follows Human Interface Guidelines
- [ ] Accessibility audit passed
- [ ] All states designed (empty, loading, error)
- [ ] Animations < 0.3s
- [ ] Tested on all device sizes

### QA
- [ ] Manual test cases passed
- [ ] Automated UI tests written
- [ ] Performance benchmarks met
- [ ] No P0/P1 bugs
- [ ] Tested on iOS 16.0+

### Release
- [ ] Version bumped appropriately
- [ ] Release notes written
- [ ] TestFlight build uploaded
- [ ] Crashlytics monitoring enabled
- [ ] Analytics events verified

## 7. Technical Decisions Log

| Decision | Rationale | Date | Alternatives Considered |
|----------|-----------|------|------------------------|
| **CloudKit vs Custom Backend** | • Zero server costs<br>• Apple integration<br>• Automatic sync | Week 1 | Firebase, AWS, Supabase |
| **SwiftUI vs UIKit** | • Modern framework<br>• Faster development<br>• Better for widgets | Week 1 | UIKit, React Native |
| **Core ML vs Server ML** | • Privacy-first<br>• No latency<br>• Offline support | Week 3 | Cloud ML APIs |
| **StoreKit 2 vs RevenueCat** | • Native solution<br>• No dependencies<br>• Latest features | Week 9 | RevenueCat, Adapty |

## 8. Sprint Planning Template

### Week N Sprint Planning
**Sprint Goal**: [One sentence describing the main outcome]

**Committed Stories**:
| Story ID | Description | Points | Assignee |
|----------|-------------|--------|----------|
| | | | |

**Risks & Dependencies**:
- 

**Success Metrics**:
- 

**Demo Plan**:
- 

---

This implementation blueprint provides a comprehensive roadmap from project inception to App Store launch. Each milestone builds upon the previous one, with clear dependencies and exit criteria to ensure quality and predictability. 