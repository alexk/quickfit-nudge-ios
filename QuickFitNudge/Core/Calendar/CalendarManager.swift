import Foundation
import EventKit

// MARK: - Calendar Manager
@MainActor
final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published private(set) var hasCalendarAccess = false
    @Published private(set) var upcomingGaps: [CalendarGap] = []
    @Published private(set) var isScanning = false
    
    private let eventStore = EKEventStore()
    private let gapDetector = GapDetectionEngine()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func requestCalendarAccess() async -> Bool {
        let startTime = Date()
        logInfo("Requesting calendar access", category: .calendar)
        
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                hasCalendarAccess = granted
                
                let duration = Date().timeIntervalSince(startTime)
                logInfo("Calendar access request completed in \(String(format: "%.2f", duration))s - granted: \(granted)", category: .calendar)
                
                if granted {
                    AnalyticsManager.shared.trackCalendarPermissionGranted()
                    await scanForGaps()
                } else {
                    AnalyticsManager.shared.trackCalendarPermissionDenied()
                }
                
                return granted
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                logError("Error requesting calendar access after \(String(format: "%.2f", duration))s: \(error)", category: .calendar)
                AnalyticsManager.shared.trackError(error, context: "calendar_permission_request")
                hasCalendarAccess = false
                return false
            }
        } else {
            // iOS 16 and earlier
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    let duration = Date().timeIntervalSince(startTime)
                    
                    if let error = error {
                        logError("Error requesting calendar access (iOS 16) after \(String(format: "%.2f", duration))s: \(error)", category: .calendar)
                        AnalyticsManager.shared.trackError(error, context: "calendar_permission_request_ios16")
                    } else {
                        logInfo("Calendar access request (iOS 16) completed in \(String(format: "%.2f", duration))s - granted: \(granted)", category: .calendar)
                    }
                    
                    // Always resume continuation, even if Task creation fails
                    continuation.resume(returning: granted)
                    
                    Task { @MainActor in
                        self.hasCalendarAccess = granted
                        if granted {
                            AnalyticsManager.shared.trackCalendarPermissionGranted()
                            await self.scanForGaps()
                        } else {
                            AnalyticsManager.shared.trackCalendarPermissionDenied()
                        }
                    }
                }
            }
        }
    }
    
    func scanForGaps(hours: Int = 48) async {
        guard hasCalendarAccess else {
            logDebug("Skipping gap scan - no calendar access", category: .calendar)
            return
        }
        
        let scanStartTime = Date()
        logInfo("Starting gap scan for next \(hours) hours", category: .calendar)
        AnalyticsManager.shared.trackGapScanStarted()
        
        isScanning = true
        defer { isScanning = false }
        
        let now = Date()
        let endDate = now.addingTimeInterval(TimeInterval(hours * 3600))
        
        // Get all calendars
        let calendars = eventStore.calendars(for: .event)
        logDebug("Found \(calendars.count) calendars", category: .calendar)
        
        // Get events
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: calendars
        )
        
        let events = eventStore.events(matching: predicate)
        logDebug("Found \(events.count) events in scan period", category: .calendar)
        
        // Detect gaps
        let gaps = gapDetector.findGaps(
            in: events,
            startDate: now,
            endDate: endDate
        )
        
        upcomingGaps = gaps
        
        let scanDuration = Date().timeIntervalSince(scanStartTime)
        logInfo("Gap scan completed in \(String(format: "%.2f", scanDuration))s - found \(gaps.count) gaps", category: .calendar)
        
        AnalyticsManager.shared.trackGapScanCompleted(
            gapCount: gaps.count,
            scanDuration: scanDuration
        )
        
        // Log gap quality distribution
        if !gaps.isEmpty {
            let qualityDistribution = Dictionary(grouping: gaps, by: { $0.quality })
                .mapValues { $0.count }
            logDebug("Gap quality distribution: \(qualityDistribution)", category: .calendar)
        }
    }
    
    func refreshGaps() async {
        logDebug("Refreshing calendar gaps", category: .calendar)
        await scanForGaps()
    }
}

// MARK: - Calendar Gap Model
struct CalendarGap: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let quality: GapQuality
    let suggestedWorkoutType: WorkoutType
    
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

// WorkoutType is defined in Models/Workout.swift

// MARK: - Gap Detection Engine
final class GapDetectionEngine {
    
    func findGaps(in events: [EKEvent], startDate: Date, endDate: Date) -> [CalendarGap] {
        let detectionStartTime = Date()
        var gaps: [CalendarGap] = []
        
        logDebug("Finding gaps between \(events.count) events", category: .calendar)
        
        // Sort events by start date
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        
        // Check gap before first event
        if let firstEvent = sortedEvents.first {
            let gapDuration = firstEvent.startDate.timeIntervalSince(startDate)
            if gapDuration >= 60 { // At least 1 minute
                logDebug("Found gap before first event: \(Int(gapDuration/60)) minutes", category: .calendar)
                gaps.append(createGap(
                    start: startDate,
                    end: firstEvent.startDate,
                    duration: gapDuration
                ))
            }
        }
        
        // Check gaps between events
        for i in 0..<sortedEvents.count - 1 {
            let currentEvent = sortedEvents[i]
            let nextEvent = sortedEvents[i + 1]
            
            guard let gapStart = currentEvent.endDate,
                  let gapEnd = nextEvent.startDate else { 
                logDebug("Skipping event without proper dates - current: \(currentEvent.title ?? "No title"), next: \(nextEvent.title ?? "No title")", category: .calendar)
                continue 
            }
            let gapDuration = gapEnd.timeIntervalSince(gapStart)
            
            if gapDuration >= 60 && gapDuration <= 300 { // 1-5 minutes
                gaps.append(createGap(
                    start: gapStart,
                    end: gapEnd,
                    duration: gapDuration
                ))
            }
        }
        
        // Check gap after last event
        if let lastEvent = sortedEvents.last,
           let lastEventEndDate = lastEvent.endDate {
            let gapDuration = endDate.timeIntervalSince(lastEventEndDate)
            if gapDuration >= 60 && gapDuration <= 300 {
                gaps.append(createGap(
                    start: lastEventEndDate,
                    end: endDate,
                    duration: gapDuration
                ))
            }
        }
        
        // If no events, the entire period is a gap
        if sortedEvents.isEmpty {
            let duration = endDate.timeIntervalSince(startDate)
            if duration >= 60 {
                logDebug("No events found - entire period is a gap", category: .calendar)
                gaps.append(createGap(
                    start: startDate,
                    end: endDate,
                    duration: min(duration, 300) // Cap at 5 minutes
                ))
            }
        }
        
        let detectionDuration = Date().timeIntervalSince(detectionStartTime)
        logDebug("Gap detection completed in \(String(format: "%.3f", detectionDuration * 1000))ms - found \(gaps.count) gaps", category: .calendar)
        
        return gaps
    }
    
    private func createGap(start: Date, end: Date, duration: TimeInterval) -> CalendarGap {
        let quality = determineGapQuality(duration: duration, startTime: start)
        let workoutType = suggestWorkoutType(duration: duration, quality: quality)
        
        return CalendarGap(
            startDate: start,
            endDate: end,
            duration: duration,
            quality: quality,
            suggestedWorkoutType: workoutType
        )
    }
    
    private func determineGapQuality(duration: TimeInterval, startTime: Date) -> CalendarGap.GapQuality {
        let minutes = Int(duration / 60)
        let hour = Calendar.current.component(.hour, from: startTime)
        
        // Consider both duration and time of day
        if minutes >= 3 && minutes <= 5 {
            // Ideal workout window
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
    
    private func suggestWorkoutType(duration: TimeInterval, quality: CalendarGap.GapQuality) -> WorkoutType {
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
} 