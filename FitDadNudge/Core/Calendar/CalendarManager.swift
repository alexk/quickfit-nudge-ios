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
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                hasCalendarAccess = granted
                
                if granted {
                    await scanForGaps()
                }
                
                return granted
            } catch {
                logError("Error requesting calendar access: \(error)", category: .calendar)
                hasCalendarAccess = false
                return false
            }
        } else {
            // iOS 16 and earlier
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        logError("Error requesting calendar access: \(error)", category: .calendar)
                    }
                    Task { @MainActor in
                        self.hasCalendarAccess = granted
                        if granted {
                            await self.scanForGaps()
                        }
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }
    
    func scanForGaps(hours: Int = 48) async {
        guard hasCalendarAccess else { return }
        
        isScanning = true
        defer { isScanning = false }
        
        let now = Date()
        let endDate = now.addingTimeInterval(TimeInterval(hours * 3600))
        
        // Get all calendars
        let calendars = eventStore.calendars(for: .event)
        
        // Get events
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: calendars
        )
        
        let events = eventStore.events(matching: predicate)
        
        // Detect gaps
        let gaps = gapDetector.findGaps(
            in: events,
            startDate: now,
            endDate: endDate
        )
        
        upcomingGaps = gaps
    }
    
    func refreshGaps() async {
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
        var gaps: [CalendarGap] = []
        
        // Sort events by start date
        let sortedEvents = events.sorted { $0.startDate < $1.startDate }
        
        // Check gap before first event
        if let firstEvent = sortedEvents.first {
            let gapDuration = firstEvent.startDate.timeIntervalSince(startDate)
            if gapDuration >= 60 { // At least 1 minute
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
                  let gapEnd = nextEvent.startDate else { continue }
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
                gaps.append(createGap(
                    start: startDate,
                    end: endDate,
                    duration: min(duration, 300) // Cap at 5 minutes
                ))
            }
        }
        
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
            return [.strength, .dadKid, .stretching].randomElement() ?? .strength
        default:
            return .stretching
        }
    }
} 