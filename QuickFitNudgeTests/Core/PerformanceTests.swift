import XCTest
@testable import FitDadNudge

final class PerformanceTests: XCTestCase {
    
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        performanceMonitor = PerformanceMonitor.shared
    }
    
    // MARK: - Performance Measurement Tests
    
    func testStartMeasuring() {
        // When
        let measurement = performanceMonitor.startMeasuring(.workoutLoad)
        
        // Then
        XCTAssertEqual(measurement.operation, .workoutLoad)
        XCTAssertGreaterThan(measurement.startTime, 0)
    }
    
    func testEndMeasuring() {
        // Given
        let measurement = performanceMonitor.startMeasuring(.calendarScan)
        
        // Simulate some work
        Thread.sleep(forTimeInterval: 0.1)
        
        // When
        performanceMonitor.endMeasuring(measurement)
        
        // Then
        let report = performanceMonitor.generateReport()
        let metric = report.metrics.first { $0.operation == .calendarScan }
        
        XCTAssertNotNil(metric)
        XCTAssertEqual(metric?.count, 1)
        XCTAssertGreaterThanOrEqual(metric?.averageDuration ?? 0, 0.1)
    }
    
    func testMeasureSync() {
        // When
        let result = performanceMonitor.measure(.databaseQuery) {
            Thread.sleep(forTimeInterval: 0.05)
            return "test result"
        }
        
        // Then
        XCTAssertEqual(result, "test result")
        
        let report = performanceMonitor.generateReport()
        let metric = report.metrics.first { $0.operation == .databaseQuery }
        
        XCTAssertNotNil(metric)
        XCTAssertGreaterThanOrEqual(metric?.averageDuration ?? 0, 0.05)
    }
    
    func testMeasureAsync() async {
        // When
        let result = await performanceMonitor.measureAsync(.cloudKitFetch) {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            return 42
        }
        
        // Then
        XCTAssertEqual(result, 42)
        
        let report = performanceMonitor.generateReport()
        let metric = report.metrics.first { $0.operation == .cloudKitFetch }
        
        XCTAssertNotNil(metric)
        XCTAssertGreaterThanOrEqual(metric?.averageDuration ?? 0, 0.05)
    }
    
    // MARK: - Performance Operation Tests
    
    func testOperationThresholds() {
        XCTAssertEqual(PerformanceOperation.appLaunch.threshold, 2.0)
        XCTAssertEqual(PerformanceOperation.calendarScan.threshold, 1.0)
        XCTAssertEqual(PerformanceOperation.widgetRefresh.threshold, 0.5)
        XCTAssertEqual(PerformanceOperation.workoutLoad.threshold, 0.3)
        XCTAssertEqual(PerformanceOperation.cloudKitFetch.threshold, 3.0)
        XCTAssertEqual(PerformanceOperation.cloudKitSave.threshold, 2.0)
        XCTAssertEqual(PerformanceOperation.imageLoad.threshold, 0.5)
        XCTAssertEqual(PerformanceOperation.databaseQuery.threshold, 0.2)
        XCTAssertEqual(PerformanceOperation.authenticationFlow.threshold, 5.0)
    }
    
    // MARK: - Performance Metric Tests
    
    func testPerformanceMetric() {
        // Given
        var metric = PerformanceMetric(operation: .workoutLoad)
        
        // When
        metric.addMeasurement(0.1)
        metric.addMeasurement(0.2)
        metric.addMeasurement(0.3)
        metric.addMeasurement(0.4)
        metric.addMeasurement(0.5)
        
        // Then
        XCTAssertEqual(metric.count, 5)
        XCTAssertEqual(metric.totalDuration, 1.5, accuracy: 0.01)
        XCTAssertEqual(metric.averageDuration, 0.3, accuracy: 0.01)
        XCTAssertEqual(metric.minDuration, 0.1, accuracy: 0.01)
        XCTAssertEqual(metric.maxDuration, 0.5, accuracy: 0.01)
        XCTAssertEqual(metric.p95Duration, 0.5, accuracy: 0.01)
    }
    
    func testPerformanceMetricMaxMeasurements() {
        // Given
        var metric = PerformanceMetric(operation: .imageLoad)
        
        // When - Add more than 100 measurements
        for i in 1...110 {
            metric.addMeasurement(Double(i) * 0.01)
        }
        
        // Then - Should only keep last 100
        XCTAssertEqual(metric.count, 100)
        XCTAssertEqual(metric.minDuration, 0.11, accuracy: 0.01) // 11th measurement
        XCTAssertEqual(metric.maxDuration, 1.10, accuracy: 0.01) // 110th measurement
    }
    
    // MARK: - Performance Report Tests
    
    func testGenerateReport() {
        // Given - Multiple measurements
        _ = performanceMonitor.measure(.workoutLoad) {
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        _ = performanceMonitor.measure(.calendarScan) {
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        _ = performanceMonitor.measure(.workoutLoad) {
            Thread.sleep(forTimeInterval: 0.15)
        }
        
        // When
        let report = performanceMonitor.generateReport()
        
        // Then
        XCTAssertGreaterThanOrEqual(report.metrics.count, 2)
        XCTAssertGreaterThanOrEqual(report.totalOperations, 3)
        XCTAssertNotNil(report.generatedAt)
        
        // Verify sorting by average duration (slowest first)
        if report.metrics.count >= 2 {
            XCTAssertGreaterThanOrEqual(
                report.metrics[0].averageDuration,
                report.metrics[1].averageDuration
            )
        }
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageReporting() {
        // This test verifies the memory reporting doesn't crash
        // Actual memory values will vary by system
        
        // When/Then - Should not throw
        XCTAssertNoThrow(performanceMonitor.reportMemoryUsage())
    }
} 