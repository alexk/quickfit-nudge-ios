import XCTest
import StoreKit
@testable import FitDadNudge

final class SubscriptionManagerTests: XCTestCase {
    
    var subscriptionManager: SubscriptionManager!
    
    override func setUpWithResult() throws {
        subscriptionManager = SubscriptionManager.shared
    }
    
    override func tearDownWithResult() throws {
        subscriptionManager = nil
    }
    
    // MARK: - Subscription Status Tests
    
    func testInitialSubscriptionStatus() {
        XCTAssertEqual(subscriptionManager.subscriptionStatus, .none, "Initial subscription status should be none")
        XCTAssertFalse(subscriptionManager.isLoading, "Should not be loading initially")
        XCTAssertNil(subscriptionManager.error, "Should have no error initially")
    }
    
    func testSubscriptionStatusTypes() {
        // Test all subscription status cases
        let testCases: [SubscriptionStatus] = [
            .none,
            .trial(daysRemaining: 7),
            .premium(.monthly),
            .premium(.yearly),
            .expired
        ]
        
        for status in testCases {
            switch status {
            case .none, .expired:
                XCTAssertFalse(status.isActive, "\(status) should not be active")
            case .trial, .premium:
                XCTAssertTrue(status.isActive, "\(status) should be active")
            }
        }
    }
    
    func testPlanTypeDescription() {
        let monthly = SubscriptionStatus.PlanType.monthly
        let yearly = SubscriptionStatus.PlanType.yearly
        
        XCTAssertEqual(monthly.rawValue, "Monthly", "Monthly plan should have correct raw value")
        XCTAssertEqual(yearly.rawValue, "Annual", "Yearly plan should have correct raw value")
    }
    
    // MARK: - Product Loading Tests
    
    func testProductLoading() async {
        // Test that products are loaded
        await subscriptionManager.loadProducts()
        
        // Note: In a real test environment, this might not load actual products
        // but we can test that the loading state is managed correctly
        XCTAssertFalse(subscriptionManager.isLoading, "Should not be loading after loadProducts completes")
    }
    
    // MARK: - Subscription Management Tests
    
    func testSubscriptionEquality() {
        let status1 = SubscriptionStatus.premium(.monthly)
        let status2 = SubscriptionStatus.premium(.monthly)
        let status3 = SubscriptionStatus.premium(.yearly)
        
        XCTAssertEqual(status1, status2, "Same subscription statuses should be equal")
        XCTAssertNotEqual(status1, status3, "Different subscription statuses should not be equal")
    }
    
    func testTrialDaysRemaining() {
        let trial7 = SubscriptionStatus.trial(daysRemaining: 7)
        let trial0 = SubscriptionStatus.trial(daysRemaining: 0)
        
        XCTAssertTrue(trial7.isActive, "Trial with days remaining should be active")
        XCTAssertTrue(trial0.isActive, "Trial with 0 days should still be active")
    }
    
    // MARK: - Error Handling Tests
    
    func testSubscriptionErrorHandling() {
        // Test various subscription errors
        let errors: [SubscriptionError] = [
            .verificationFailed,
            .purchaseFailed(underlying: MockError.generic),
            .restoreFailed(underlying: MockError.generic),
            .productNotFound
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "All errors should have descriptions")
            XCTAssertNotNil(error.recoverySuggestion, "All errors should have recovery suggestions")
        }
    }
    
    func testSubscriptionErrorMessages() {
        let verificationError = SubscriptionError.verificationFailed
        let purchaseError = SubscriptionError.purchaseFailed(underlying: MockError.generic)
        let restoreError = SubscriptionError.restoreFailed(underlying: MockError.generic)
        let notFoundError = SubscriptionError.productNotFound
        
        XCTAssertTrue(verificationError.errorDescription?.contains("verification") == true)
        XCTAssertTrue(purchaseError.errorDescription?.contains("purchase") == true)
        XCTAssertTrue(restoreError.errorDescription?.contains("restore") == true)
        XCTAssertTrue(notFoundError.errorDescription?.contains("available") == true)
    }
    
    // MARK: - State Management Tests
    
    func testLoadingState() async {
        // Test that loading state is properly managed
        let expectation = XCTestExpectation(description: "Loading state changes")
        
        var loadingStates: [Bool] = []
        let cancellable = subscriptionManager.$isLoading.sink { isLoading in
            loadingStates.append(isLoading)
            if loadingStates.count >= 2 {
                expectation.fulfill()
            }
        }
        
        await subscriptionManager.loadProducts()
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Should have changed from initial state to loading and back
        XCTAssertTrue(loadingStates.count >= 2, "Loading state should change during operation")
        
        cancellable.cancel()
    }
}

// MARK: - Mock Error

enum MockError: Error {
    case generic
    case networkFailure
    case invalidResponse
    
    var localizedDescription: String {
        switch self {
        case .generic:
            return "A generic error occurred"
        case .networkFailure:
            return "Network request failed"
        case .invalidResponse:
            return "Invalid response received"
        }
    }
}