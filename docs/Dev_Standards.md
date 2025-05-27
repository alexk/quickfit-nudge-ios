# FitDad Nudge — Engineering Standards & Workflow

## 1. Swift Style Guide

### Naming Conventions

#### General Rules
- Use descriptive names that clearly express intent
- Avoid abbreviations except well-known ones (URL, ID, etc.)
- Use American English spelling

#### Types & Protocols
```swift
// ✅ Good
class WorkoutSession { }
struct CalendarGap { }
protocol WorkoutDataSource { }
enum WorkoutType { }

// ❌ Bad
class workout_session { }
struct Gap { }
protocol DataSource { }
enum Type { }
```

#### Properties & Variables
```swift
// ✅ Good
let maximumWorkoutDuration = 300
var currentStreak = 0
private let calendarManager: CalendarManager

// ❌ Bad
let max_duration = 300
var streak = 0
private let mgr: CalendarManager
```

#### Functions & Methods
```swift
// ✅ Good
func startWorkout(with exercise: Exercise) async throws
func calculateGapDuration(between start: Date, and end: Date) -> TimeInterval

// ❌ Bad
func start(_ e: Exercise) async throws
func gap(_ s: Date, _ e: Date) -> TimeInterval
```

### Code Organization

#### File Structure
```swift
// MARK: - Imports
import SwiftUI
import Combine

// MARK: - Types
struct WorkoutView: View {
    // MARK: - Properties
    @StateObject private var viewModel: WorkoutViewModel
    @State private var isShowingDetail = false
    
    // MARK: - Body
    var body: some View {
        content
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var content: some View {
        // Implementation
    }
}

// MARK: - Preview
#Preview {
    WorkoutView()
}
```

#### Extension Organization
```swift
// MARK: - WorkoutProtocol
extension WorkoutView: WorkoutProtocol {
    // Protocol implementation
}

// MARK: - Private Methods
private extension WorkoutView {
    func startWorkout() {
        // Implementation
    }
}
```

### Modern Swift Patterns

#### Async/Await
```swift
// ✅ Good - Use async/await for asynchronous operations
func fetchWorkouts() async throws -> [Workout] {
    let workouts = try await cloudKitManager.fetch(Workout.self)
    return workouts.sorted { $0.createdAt > $1.createdAt }
}

// ✅ Good - Structured concurrency
func syncAllData() async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await self.syncWorkouts() }
        group.addTask { try await self.syncStreaks() }
        group.addTask { try await self.syncBadges() }
    }
}
```

#### SwiftUI Best Practices
```swift
// ✅ Good - Composition over inheritance
struct WorkoutCard: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WorkoutHeader(workout: workout)
            WorkoutContent(workout: workout)
            WorkoutFooter(workout: workout)
        }
    }
}

// ✅ Good - Environment values for dependency injection
struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.colorScheme) var colorScheme
}
```

#### Error Handling
```swift
// ✅ Good - Typed errors
enum WorkoutError: LocalizedError {
    case noCalendarAccess
    case workoutNotFound(id: UUID)
    case syncFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .noCalendarAccess:
            return "Calendar access is required to find workout gaps"
        case .workoutNotFound(let id):
            return "Workout with ID \(id) not found"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        }
    }
}
```

### Testing Standards

#### Unit Test Structure
```swift
import XCTest
@testable import FitDadNudge

final class WorkoutManagerTests: XCTestCase {
    private var sut: WorkoutManager!
    private var mockCloudKit: MockCloudKitManager!
    
    override func setUp() {
        super.setUp()
        mockCloudKit = MockCloudKitManager()
        sut = WorkoutManager(cloudKit: mockCloudKit)
    }
    
    override func tearDown() {
        sut = nil
        mockCloudKit = nil
        super.tearDown()
    }
    
    func testStartWorkout_WithValidExercise_CompletesSuccessfully() async throws {
        // Given
        let exercise = Exercise.fixture()
        
        // When
        try await sut.startWorkout(with: exercise)
        
        // Then
        XCTAssertEqual(sut.currentWorkout?.exercise, exercise)
        XCTAssertTrue(mockCloudKit.saveWasCalled)
    }
}
```

## 2. Commit Guidelines

### Conventional Commits Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `build`: Build system or dependency changes
- `ci`: CI/CD configuration changes
- `chore`: Other changes that don't modify src or test files

### Examples
```bash
# ✅ Good commits
feat(workout): add calendar gap detection algorithm
fix(widget): resolve memory leak in timeline provider
docs(readme): update setup instructions for Xcode 15
perf(sync): optimize CloudKit batch operations
test(auth): add unit tests for Sign in with Apple flow

# ❌ Bad commits
fixed stuff
WIP
update
workout changes
```

### Commit Rules
1. **Atomic commits**: Each commit should represent one logical change
2. **Build passing**: Every commit should compile and pass tests
3. **Size limit**: Keep changes under 200 lines when possible
4. **No secrets**: Never commit API keys or sensitive data

## 3. Branch Strategy

### Branch Structure
```
main
├── develop
│   ├── feature/calendar-integration
│   ├── feature/workout-player
│   └── feature/subscription-flow
├── release/1.0.0
└── hotfix/critical-crash-fix
```

### Branch Naming
- `feature/*` - New features
- `fix/*` - Bug fixes
- `refactor/*` - Code refactoring
- `test/*` - Test additions/updates
- `docs/*` - Documentation updates

### Branch Rules
1. **Protected branches**: `main` and `develop` require PR reviews
2. **Feature branches**: Branch from `develop`, merge back to `develop`
3. **Release branches**: Branch from `develop`, merge to both `main` and `develop`
4. **Hotfix branches**: Branch from `main`, merge to both `main` and `develop`

### Pull Request Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Manual testing completed

## Screenshots
If applicable, add screenshots

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings
```

## 4. Code Review Checklist

### Functionality
- [ ] Code accomplishes the intended task
- [ ] Edge cases are handled
- [ ] Error handling is appropriate
- [ ] No obvious bugs

### Performance
- [ ] No unnecessary loops or operations
- [ ] Async operations used appropriately
- [ ] Memory leaks avoided
- [ ] No blocking main thread

### Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Secure data storage used
- [ ] Authentication properly implemented

### Code Quality
- [ ] Follows style guide
- [ ] DRY principle applied
- [ ] SOLID principles followed
- [ ] Clear variable/function names

### Testing
- [ ] Unit tests added/updated
- [ ] Integration tests considered
- [ ] Test coverage maintained
- [ ] Edge cases tested

### Documentation
- [ ] Public APIs documented
- [ ] Complex logic explained
- [ ] README updated if needed
- [ ] Inline comments meaningful

## 5. Architecture Guidelines

### MVVM Pattern
```swift
// Model
struct Workout: Identifiable, Codable {
    let id: UUID
    let name: String
    let duration: TimeInterval
    let exercises: [Exercise]
}

// ViewModel
@MainActor
final class WorkoutViewModel: ObservableObject {
    @Published private(set) var workouts: [Workout] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: WorkoutError?
    
    private let repository: WorkoutRepositoryProtocol
    
    init(repository: WorkoutRepositoryProtocol = WorkoutRepository()) {
        self.repository = repository
    }
    
    func loadWorkouts() async {
        isLoading = true
        do {
            workouts = try await repository.fetchWorkouts()
        } catch {
            self.error = .syncFailed(underlying: error)
        }
        isLoading = false
    }
}

// View
struct WorkoutListView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    
    var body: some View {
        List(viewModel.workouts) { workout in
            WorkoutRow(workout: workout)
        }
        .task {
            await viewModel.loadWorkouts()
        }
    }
}
```

### Dependency Injection
```swift
// Protocol for testability
protocol WorkoutRepositoryProtocol {
    func fetchWorkouts() async throws -> [Workout]
    func saveWorkout(_ workout: Workout) async throws
}

// Implementation
final class WorkoutRepository: WorkoutRepositoryProtocol {
    private let cloudKit: CloudKitManagerProtocol
    
    init(cloudKit: CloudKitManagerProtocol = CloudKitManager.shared) {
        self.cloudKit = cloudKit
    }
    
    func fetchWorkouts() async throws -> [Workout] {
        try await cloudKit.fetch(Workout.self)
    }
}
```

## 6. Performance Guidelines

### Memory Management
- Use `weak` references in closures to avoid retain cycles
- Profile with Instruments regularly
- Lazy load heavy resources
- Cancel unnecessary tasks

### SwiftUI Performance
- Use `@StateObject` for view-owned objects
- Minimize view updates with proper state management
- Use `task` modifier for async work
- Profile with SwiftUI Instruments

### Background Processing
- Use appropriate background modes
- Implement proper task completion handlers
- Respect system resources
- Test on low-end devices

## 7. Security Standards

### Data Protection
- Enable Data Protection for sensitive files
- Use Keychain for credentials
- Implement certificate pinning for sensitive APIs
- Regular security audits

### Privacy
- Minimal data collection
- Clear privacy policy
- User consent for all data usage
- Data deletion capabilities

## 8. Accessibility Standards

### VoiceOver Support
- All interactive elements labeled
- Meaningful accessibility hints
- Proper accessibility traits
- Custom actions where appropriate

### Dynamic Type
- Support all text sizes
- Test with largest accessibility sizes
- Maintain layout integrity
- Use scalable spacing

### Color & Contrast
- WCAG AA compliance minimum
- High contrast mode support
- Don't rely on color alone
- Test with color filters

---

These standards ensure consistent, high-quality code that's maintainable, performant, and delightful for users. Regular reviews and updates to these standards are encouraged as the team and technology evolve. 