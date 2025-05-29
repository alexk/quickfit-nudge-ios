import Foundation
import EventKit

// MARK: - Calendar Integration Manager

@MainActor
final class CalendarIntegrationManager: ObservableObject {
    static let shared = CalendarIntegrationManager()
    
    @Published private(set) var connectedCalendars: [ConnectedCalendar] = []
    @Published private(set) var isConnecting = false
    @Published private(set) var lastError: Error?
    
    private let appleCalendarManager = CalendarManager.shared
    private let googleCalendarService = GoogleCalendarService()
    private let gapDetector = GapDetectionEngine()
    
    private init() {
        loadConnectedCalendars()
    }
    
    // MARK: - Calendar Types
    
    enum CalendarType: String, CaseIterable {
        case apple = "apple"
        case google = "google"
        case both = "both"
        
        var displayName: String {
            switch self {
            case .apple: return "iOS Calendar"
            case .google: return "Google Calendar"
            case .both: return "Both Calendars"
            }
        }
        
        var iconName: String {
            switch self {
            case .apple: return "calendar"
            case .google: return "globe"
            case .both: return "calendar.badge.plus"
            }
        }
    }
    
    // MARK: - Public Methods
    
    func requestAppleCalendarAccess() async -> Bool {
        isConnecting = true
        defer { isConnecting = false }
        
        let granted = await appleCalendarManager.requestCalendarAccess()
        
        if granted {
            await addConnectedCalendar(.apple)
        }
        
        return granted
    }
    
    func requestGoogleCalendarAccess() async -> Bool {
        isConnecting = true
        defer { isConnecting = false }
        
        do {
            let success = try await googleCalendarService.authenticate()
            
            if success {
                await addConnectedCalendar(.google)
            }
            
            return success
            
        } catch {
            lastError = error
            logError("Google Calendar authentication failed: \(error)", category: .calendar)
            return false
        }
    }
    
    func disconnectCalendar(_ type: CalendarType) async {
        switch type {
        case .apple:
            await removeConnectedCalendar(.apple)
        case .google:
            await googleCalendarService.signOut()
            await removeConnectedCalendar(.google)
        case .both:
            await googleCalendarService.signOut()
            await removeConnectedCalendars([.apple, .google])
        }
        
        saveConnectedCalendars()
    }
    
    func fetchMergedCalendarEvents(startDate: Date, endDate: Date) async -> [CalendarEvent] {
        var allEvents: [CalendarEvent] = []
        
        // Fetch Apple Calendar events
        if hasAppleCalendarAccess {
            let appleEvents = await fetchAppleCalendarEvents(startDate: startDate, endDate: endDate)
            allEvents.append(contentsOf: appleEvents)
        }
        
        // Fetch Google Calendar events
        if hasGoogleCalendarAccess {
            do {
                let googleEvents = try await googleCalendarService.fetchEvents(
                    startDate: startDate,
                    endDate: endDate
                )
                allEvents.append(contentsOf: googleEvents)
            } catch {
                logError("Failed to fetch Google Calendar events: \(error)", category: .calendar)
                lastError = error
            }
        }
        
        return mergeCalendarEvents(allEvents)
    }
    
    func detectGapsInMergedCalendars(startDate: Date, endDate: Date) async -> [WorkoutGap] {
        let events = await fetchMergedCalendarEvents(startDate: startDate, endDate: endDate)
        
        // Convert CalendarEvent to EKEvent-like objects for gap detection
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        
        return detectGapsFromEvents(sortedEvents, startDate: startDate, endDate: endDate)
    }
    
    // MARK: - Properties
    
    var hasAppleCalendarAccess: Bool {
        connectedCalendars.contains { $0.type == .apple }
    }
    
    var hasGoogleCalendarAccess: Bool {
        connectedCalendars.contains { $0.type == .google }
    }
    
    var hasAnyCalendarAccess: Bool {
        !connectedCalendars.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func addConnectedCalendar(_ type: CalendarType) async {
        let calendar = ConnectedCalendar(
            type: type,
            isConnected: true,
            connectedAt: Date(),
            lastSyncAt: Date()
        )
        
        if !connectedCalendars.contains(where: { $0.type == type }) {
            connectedCalendars.append(calendar)
            saveConnectedCalendars()
        }
    }
    
    private func removeConnectedCalendar(_ type: CalendarType) async {
        connectedCalendars.removeAll { $0.type == type }
        saveConnectedCalendars()
    }
    
    private func removeConnectedCalendars(_ types: [CalendarType]) async {
        connectedCalendars.removeAll { calendar in
            types.contains(calendar.type)
        }
        saveConnectedCalendars()
    }
    
    private func fetchAppleCalendarEvents(startDate: Date, endDate: Date) async -> [CalendarEvent] {
        let eventStore = EKEventStore()
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: eventStore.calendars(for: .event)
        )
        
        let events = eventStore.events(matching: predicate)
        
        return events.map { ekEvent in
            CalendarEvent(
                id: ekEvent.eventIdentifier ?? UUID().uuidString,
                title: ekEvent.title ?? "Untitled Event",
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate ?? ekEvent.startDate.addingTimeInterval(3600),
                isAllDay: ekEvent.isAllDay,
                source: .apple,
                calendar: ekEvent.calendar?.title ?? "Unknown Calendar"
            )
        }
    }
    
    private func mergeCalendarEvents(_ events: [CalendarEvent]) -> [CalendarEvent] {
        // Remove duplicates based on title, start time, and date
        var uniqueEvents: [CalendarEvent] = []
        
        for event in events {
            let isDuplicate = uniqueEvents.contains { existingEvent in
                existingEvent.title == event.title &&
                Calendar.current.isDate(existingEvent.startDate, equalTo: event.startDate, toGranularity: .minute)
            }
            
            if !isDuplicate {
                uniqueEvents.append(event)
            }
        }
        
        return uniqueEvents.sorted { $0.startDate < $1.startDate }
    }
    
    private func detectGapsFromEvents(_ events: [CalendarEvent], startDate: Date, endDate: Date) -> [WorkoutGap] {
        var gaps: [WorkoutGap] = []
        
        // Check gap before first event
        if let firstEvent = events.first {
            let gapDuration = firstEvent.startDate.timeIntervalSince(startDate)
            if gapDuration >= 60 && gapDuration <= 300 { // 1-5 minutes
                gaps.append(createWorkoutGap(
                    start: startDate,
                    end: firstEvent.startDate,
                    duration: gapDuration
                ))
            }
        }
        
        // Check gaps between events
        for i in 0..<events.count - 1 {
            let currentEvent = events[i]
            let nextEvent = events[i + 1]
            
            let gapStart = currentEvent.endDate
            let gapEnd = nextEvent.startDate
            let gapDuration = gapEnd.timeIntervalSince(gapStart)
            
            if gapDuration >= 60 && gapDuration <= 300 { // 1-5 minutes
                gaps.append(createWorkoutGap(
                    start: gapStart,
                    end: gapEnd,
                    duration: gapDuration
                ))
            }
        }
        
        // Check gap after last event
        if let lastEvent = events.last {
            let gapDuration = endDate.timeIntervalSince(lastEvent.endDate)
            if gapDuration >= 60 && gapDuration <= 300 {
                gaps.append(createWorkoutGap(
                    start: lastEvent.endDate,
                    end: endDate,
                    duration: gapDuration
                ))
            }
        }
        
        // If no events, the entire period is a gap
        if events.isEmpty {
            let duration = endDate.timeIntervalSince(startDate)
            if duration >= 60 {
                gaps.append(createWorkoutGap(
                    start: startDate,
                    end: endDate,
                    duration: min(duration, 300) // Cap at 5 minutes
                ))
            }
        }
        
        return gaps
    }
    
    private func createWorkoutGap(start: Date, end: Date, duration: TimeInterval) -> WorkoutGap {
        let quality = determineGapQuality(duration: duration, startTime: start)
        let workoutType = suggestWorkoutType(duration: duration)
        
        return WorkoutGap(
            id: UUID(),
            startDate: start,
            endDate: end,
            duration: duration,
            quality: quality,
            suggestedWorkoutType: workoutType,
            sourcedFrom: hasGoogleCalendarAccess && hasAppleCalendarAccess ? .both : (hasGoogleCalendarAccess ? .google : .apple)
        )
    }
    
    private func determineGapQuality(duration: TimeInterval, startTime: Date) -> WorkoutGap.GapQuality {
        let minutes = Int(duration / 60)
        let hour = Calendar.current.component(.hour, from: startTime)
        
        if minutes >= 3 && minutes <= 5 {
            if hour >= 6 && hour <= 20 {
                return .excellent
            } else {
                return .good
            }
        } else if minutes == 2 {
            return .good
        } else if minutes == 1 {
            return .fair
        } else {
            return .poor
        }
    }
    
    private func suggestWorkoutType(duration: TimeInterval) -> WorkoutType {
        let minutes = Int(duration / 60)
        
        switch minutes {
        case 1:
            return .breathing
        case 2:
            return .stretching
        case 3:
            return [.hiit, .cardio].randomElement() ?? .hiit
        case 4...5:
            return [.strength, .familyFriendly, .stretching].randomElement() ?? .strength
        default:
            return .stretching
        }
    }
    
    // MARK: - Persistence
    
    private func loadConnectedCalendars() {
        let key = "connected_calendars"
        if let data = UserDefaults.standard.data(forKey: key),
           let calendars = try? JSONDecoder().decode([ConnectedCalendar].self, from: data) {
            connectedCalendars = calendars
        }
    }
    
    private func saveConnectedCalendars() {
        let key = "connected_calendars"
        if let data = try? JSONEncoder().encode(connectedCalendars) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func logError(_ message: String, category: LogCategory) {
        Logger.shared.error(message, category: category)
    }
}

// MARK: - Supporting Models

struct ConnectedCalendar: Codable, Identifiable {
    let id = UUID()
    let type: CalendarIntegrationManager.CalendarType
    let isConnected: Bool
    let connectedAt: Date
    let lastSyncAt: Date
}

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let source: CalendarSource
    let calendar: String
    
    enum CalendarSource: String, Codable {
        case apple = "apple"
        case google = "google"
    }
}

struct WorkoutGap: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let quality: GapQuality
    let suggestedWorkoutType: WorkoutType
    let sourcedFrom: CalendarIntegrationManager.CalendarType
    
    var durationInMinutes: Int {
        Int(duration / 60)
    }
    
    enum GapQuality: String, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"
        
        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "orange"
            case .poor: return "red"
            }
        }
    }
}

// MARK: - Google Calendar Service

final class GoogleCalendarService {
    private var isAuthenticated = false
    private var authToken: String?
    
    func authenticate() async throws -> Bool {
        // In a real implementation, this would use GoogleSignIn SDK
        // For now, we'll simulate the authentication process
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // Simulate successful authentication
        isAuthenticated = true
        authToken = "mock_google_auth_token_\(UUID().uuidString)"
        
        logInfo("Google Calendar authenticated successfully", category: .calendar)
        return true
    }
    
    func signOut() async {
        isAuthenticated = false
        authToken = nil
        logInfo("Google Calendar signed out", category: .calendar)
    }
    
    func fetchEvents(startDate: Date, endDate: Date) async throws -> [CalendarEvent] {
        guard isAuthenticated else {
            throw GoogleCalendarError.notAuthenticated
        }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // Generate mock Google Calendar events
        return generateMockGoogleEvents(startDate: startDate, endDate: endDate)
    }
    
    private func generateMockGoogleEvents(startDate: Date, endDate: Date) -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        let mockEvents = [
            ("Team Meeting", 60), // 1 hour
            ("Project Review", 30), // 30 minutes
            ("One-on-One", 45), // 45 minutes
            ("Standup", 15), // 15 minutes
            ("Client Call", 30), // 30 minutes
            ("Design Review", 60), // 1 hour
            ("Planning Session", 90) // 1.5 hours
        ]
        
        while currentDate < endDate {
            // Add 1-3 events per day randomly
            let eventsToday = Int.random(in: 0...2)
            
            for _ in 0..<eventsToday {
                let (title, durationMinutes) = mockEvents.randomElement() ?? ("Meeting", 30)
                let hour = Int.random(in: 9...17) // Business hours
                let minute = [0, 15, 30, 45].randomElement() ?? 0
                
                if let eventStart = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: currentDate) {
                    let eventEnd = eventStart.addingTimeInterval(TimeInterval(durationMinutes * 60))
                    
                    let event = CalendarEvent(
                        id: "google_\(UUID().uuidString)",
                        title: title,
                        startDate: eventStart,
                        endDate: eventEnd,
                        isAllDay: false,
                        source: .google,
                        calendar: "Google Calendar"
                    )
                    
                    events.append(event)
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return events.sorted { $0.startDate < $1.startDate }
    }
    
    private func logInfo(_ message: String, category: LogCategory) {
        Logger.shared.info(message, category: category)
    }
}

// MARK: - Google Calendar Errors

enum GoogleCalendarError: LocalizedError {
    case notAuthenticated
    case apiError(String)
    case networkError
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Google Calendar is not authenticated"
        case .apiError(let message):
            return "Google Calendar API error: \(message)"
        case .networkError:
            return "Network error connecting to Google Calendar"
        case .authenticationFailed:
            return "Failed to authenticate with Google Calendar"
        }
    }
}