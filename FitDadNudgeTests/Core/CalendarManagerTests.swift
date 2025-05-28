import XCTest
import EventKit
@testable import FitDadNudge

final class CalendarManagerTests: XCTestCase {
    
    var calendarManager: CalendarManager!
    var mockEventStore: EKEventStore!
    
    override func setUpWithResult() throws {
        calendarManager = CalendarManager.shared
        mockEventStore = EKEventStore()
    }
    
    override func tearDownWithResult() throws {
        calendarManager = nil
        mockEventStore = nil
    }
    
    // MARK: - Gap Detection Tests
    
    func testGapDetection_WithNoEvents_ReturnsFullPeriodAsGap() async throws {
        let gapDetector = GapDetectionEngine()
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(300) // 5 minutes
        
        let gaps = gapDetector.findGaps(in: [], startDate: startDate, endDate: endDate)
        
        XCTAssertEqual(gaps.count, 1, "Should find one gap when no events exist")
        XCTAssertEqual(gaps.first?.duration, 300, "Gap duration should be 5 minutes")
        XCTAssertEqual(gaps.first?.quality, .excellent, "5-minute gap should be excellent quality")
    }
    
    func testGapDetection_WithEvents_FindsGapsBetween() {
        let gapDetector = GapDetectionEngine()
        let startDate = Date()
        
        // Create mock events
        let event1 = EKEvent(eventStore: mockEventStore)
        event1.startDate = startDate.addingTimeInterval(60) // 1 minute after start
        event1.endDate = startDate.addingTimeInterval(120) // 2 minutes after start
        
        let event2 = EKEvent(eventStore: mockEventStore)
        event2.startDate = startDate.addingTimeInterval(300) // 5 minutes after start
        event2.endDate = startDate.addingTimeInterval(360) // 6 minutes after start
        
        let gaps = gapDetector.findGaps(
            in: [event1, event2],
            startDate: startDate,
            endDate: startDate.addingTimeInterval(600)
        )
        
        XCTAssertGreaterThan(gaps.count, 0, "Should find gaps between events")
        
        // Check for gap before first event
        let gapBeforeFirst = gaps.first(where: { $0.startDate == startDate })
        XCTAssertNotNil(gapBeforeFirst, "Should find gap before first event")
        
        // Check for gap between events
        let gapBetween = gaps.first(where: { 
            abs($0.startDate.timeIntervalSince(event1.endDate!)) < 1.0 
        })
        XCTAssertNotNil(gapBetween, "Should find gap between events")
    }
    
    func testGapQuality_BasedOnDuration() {
        let gapDetector = GapDetectionEngine()
        
        // Test different gap durations and their quality
        let testCases: [(TimeInterval, CalendarGap.GapQuality)] = [
            (60, .fair),        // 1 minute - fair
            (120, .good),       // 2 minutes - good  
            (180, .excellent),  // 3 minutes - excellent
            (300, .excellent),  // 5 minutes - excellent
        ]
        
        for (duration, expectedQuality) in testCases {
            let startDate = Date()
            let endDate = startDate.addingTimeInterval(duration)
            
            let gaps = gapDetector.findGaps(in: [], startDate: startDate, endDate: endDate)
            
            XCTAssertEqual(
                gaps.first?.quality, 
                expectedQuality,
                "Gap of \(duration/60) minutes should have quality \(expectedQuality)"
            )
        }
    }
    
    func testWorkoutTypeSuggestion_BasedOnDuration() {
        let gapDetector = GapDetectionEngine()
        
        let testCases: [(TimeInterval, WorkoutType)] = [
            (60, .breathing),   // 1 minute - breathing
            (120, .stretching), // 2 minutes - stretching
            (180, .hiit),       // 3 minutes - HIIT or cardio
            (300, .strength),   // 5 minutes - strength, family, or stretching
        ]
        
        for (duration, _) in testCases {
            let startDate = Date()
            let endDate = startDate.addingTimeInterval(duration)
            
            let gaps = gapDetector.findGaps(in: [], startDate: startDate, endDate: endDate)
            
            XCTAssertNotNil(gaps.first?.suggestedWorkoutType, "Should suggest a workout type")
            
            // For 1 minute gaps, it should always be breathing
            if duration == 60 {
                XCTAssertEqual(gaps.first?.suggestedWorkoutType, .breathing)
            }
            
            // For 2 minute gaps, it should always be stretching
            if duration == 120 {
                XCTAssertEqual(gaps.first?.suggestedWorkoutType, .stretching)
            }
        }
    }
    
    // MARK: - Calendar Access Tests
    
    func testCalendarAccess_InitiallyFalse() {
        XCTAssertFalse(calendarManager.hasCalendarAccess, "Calendar access should initially be false")
    }
    
    func testGapScan_RequiresCalendarAccess() async {
        // Ensure calendar access is false
        XCTAssertFalse(calendarManager.hasCalendarAccess)
        
        // Attempt to scan for gaps without access
        await calendarManager.scanForGaps()
        
        // Should not crash and should not find any gaps
        XCTAssertTrue(calendarManager.upcomingGaps.isEmpty, "Should not find gaps without calendar access")
    }
    
    // MARK: - State Management Tests
    
    func testScanningState() async {
        // Initially not scanning
        XCTAssertFalse(calendarManager.isScanning, "Should not be scanning initially")
        
        // Note: We can't easily test the scanning state during an actual scan
        // without mocking the calendar access, which would require dependency injection
    }
}

// MARK: - Mock Classes for Testing

class MockEKEventStore: EKEventStore {
    var mockEvents: [EKEvent] = []
    var shouldGrantAccess = true
    
    override func events(matching predicate: NSPredicate) -> [EKEvent] {
        return mockEvents
    }
    
    override func requestAccess(to entityType: EKEntityType, completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        DispatchQueue.main.async {
            completion(self.shouldGrantAccess, nil)
        }
    }
    
    @available(iOS 17.0, *)
    override func requestFullAccessToEvents() async throws -> Bool {
        return shouldGrantAccess
    }
}

// MARK: - Helper Extensions

extension CalendarGap.GapQuality: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}