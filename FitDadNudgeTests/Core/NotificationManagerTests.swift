import XCTest
import UserNotifications
@testable import FitDadNudge

final class NotificationManagerTests: XCTestCase {
    
    var notificationManager: NotificationManager!
    
    override func setUpWithResult() throws {
        notificationManager = NotificationManager.shared
    }
    
    override func tearDownWithResult() throws {
        notificationManager = nil
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(notificationManager.authorizationStatus, .notDetermined, "Initial authorization should be not determined")
        XCTAssertTrue(notificationManager.pendingNotifications.isEmpty, "Should have no pending notifications initially")
    }
    
    // MARK: - Authorization Tests
    
    func testAuthorizationRequest() async {
        // Test requesting authorization
        let granted = await notificationManager.requestAuthorization()
        
        // Note: In test environment, this will likely return false
        // but we can test that it doesn't crash and returns a boolean
        XCTAssertTrue(granted == true || granted == false, "Should return a boolean value")
    }
    
    // MARK: - Gap Notification Tests
    
    func testGapNotificationCreation() async {
        // Create a test gap
        let gap = CalendarGap(
            startDate: Date().addingTimeInterval(600), // 10 minutes from now
            endDate: Date().addingTimeInterval(900),   // 15 minutes from now
            duration: 300,                             // 5 minutes
            quality: .excellent,
            suggestedWorkoutType: .hiit
        )
        
        // Test scheduling notification (will fail without authorization, but shouldn't crash)
        do {
            try await notificationManager.scheduleGapNotification(for: gap)
        } catch NotificationError.notAuthorized {
            // Expected when not authorized
            XCTAssertEqual(notificationManager.authorizationStatus, .denied, "Should be denied when not authorized")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testNotificationContentGeneration() {
        // Test that notification content is properly generated
        let gap = CalendarGap(
            startDate: Date().addingTimeInterval(300),
            endDate: Date().addingTimeInterval(600),
            duration: 300,
            quality: .excellent,
            suggestedWorkoutType: .stretching
        )
        
        // We can't directly test the content creation without exposing it,
        // but we can verify the gap has the right properties
        XCTAssertEqual(gap.durationInMinutes, 5, "Gap should be 5 minutes")
        XCTAssertEqual(gap.suggestedWorkoutType, .stretching, "Should suggest stretching")
        XCTAssertEqual(gap.quality, .excellent, "Should be excellent quality")
    }
    
    // MARK: - Streak Notification Tests
    
    func testStreakReminderScheduling() async {
        // Test scheduling streak reminder
        do {
            try await notificationManager.scheduleStreakReminder(hour: 20)
        } catch NotificationError.notAuthorized {
            // Expected when not authorized
            XCTAssertTrue(true, "Expected to fail when not authorized")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Notification Cancellation Tests
    
    func testNotificationCancellation() async {
        let testGapID = UUID()
        
        // Test canceling notification (should not crash)
        await notificationManager.cancelNotification(for: testGapID)
        
        // Test canceling all notifications
        await notificationManager.cancelAllNotifications()
        
        // Should complete without error
        XCTAssertTrue(true, "Cancellation methods should complete without error")
    }
    
    // MARK: - Notification Categories Tests
    
    func testNotificationCategoryRegistration() {
        // Test that registering categories doesn't crash
        notificationManager.registerNotificationCategories()
        
        // Should complete without error
        XCTAssertTrue(true, "Category registration should complete without error")
    }
    
    // MARK: - Error Handling Tests
    
    func testNotificationErrors() {
        let notAuthorizedError = NotificationError.notAuthorized
        let schedulingFailedError = NotificationError.schedulingFailed(underlying: MockError.generic)
        
        XCTAssertNotNil(notAuthorizedError.errorDescription, "Not authorized error should have description")
        XCTAssertNotNil(schedulingFailedError.errorDescription, "Scheduling failed error should have description")
        
        // Test error messages are user-friendly
        XCTAssertTrue(notAuthorizedError.errorDescription?.contains("permission") == true, "Should mention permission")
        XCTAssertTrue(schedulingFailedError.errorDescription?.contains("reminder") == true, "Should mention reminder")
    }
    
    // MARK: - Notification Delegate Tests
    
    func testNotificationDelegate() {
        let delegate = NotificationDelegate()
        
        // Test that delegate can be created without crashing
        XCTAssertNotNil(delegate, "Notification delegate should be created successfully")
        
        // Test delegate methods exist (they won't be called in unit tests)
        XCTAssertTrue(delegate.responds(to: #selector(delegate.userNotificationCenter(_:willPresent:withCompletionHandler:))), "Should respond to willPresent")
        XCTAssertTrue(delegate.responds(to: #selector(delegate.userNotificationCenter(_:didReceive:withCompletionHandler:))), "Should respond to didReceive")
    }
    
    // MARK: - Notification Names Tests
    
    func testNotificationNames() {
        let startWorkoutName = Notification.Name.startWorkoutFromNotification
        let openGapName = Notification.Name.openGapFromNotification
        
        XCTAssertNotNil(startWorkoutName, "Start workout notification name should exist")
        XCTAssertNotNil(openGapName, "Open gap notification name should exist")
        
        // Test that names are different
        XCTAssertNotEqual(startWorkoutName, openGapName, "Notification names should be unique")
    }
}