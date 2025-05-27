import Foundation
import os.log

// MARK: - Performance Monitor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.fitdad.nudge", category: "Performance")
    private var metrics: [String: PerformanceMetric] = [:]
    private let queue = DispatchQueue(label: "com.fitdad.nudge.performance", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startMeasuring(_ operation: PerformanceOperation) -> PerformanceMeasurement {
        let measurement = PerformanceMeasurement(operation: operation, startTime: CFAbsoluteTimeGetCurrent())
        
        logger.debug("Started measuring: \(operation.rawValue)")
        
        return measurement
    }
    
    func endMeasuring(_ measurement: PerformanceMeasurement) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - measurement.startTime
        
        queue.async(flags: .barrier) {
            if var metric = self.metrics[measurement.operation.rawValue] {
                metric.addMeasurement(duration)
                self.metrics[measurement.operation.rawValue] = metric
            } else {
                var newMetric = PerformanceMetric(operation: measurement.operation)
                newMetric.addMeasurement(duration)
                self.metrics[measurement.operation.rawValue] = newMetric
            }
        }
        
        logger.debug("\(measurement.operation.rawValue) took \(String(format: "%.3f", duration))s")
        
        // Alert if operation took too long
        if duration > measurement.operation.threshold {
            logger.warning("\(measurement.operation.rawValue) exceeded threshold: \(String(format: "%.3f", duration))s > \(measurement.operation.threshold)s")
        }
    }
    
    func measureAsync<T>(_ operation: PerformanceOperation, block: () async throws -> T) async rethrows -> T {
        let measurement = startMeasuring(operation)
        defer { endMeasuring(measurement) }
        return try await block()
    }
    
    func measure<T>(_ operation: PerformanceOperation, block: () throws -> T) rethrows -> T {
        let measurement = startMeasuring(operation)
        defer { endMeasuring(measurement) }
        return try block()
    }
    
    // MARK: - Reporting
    
    func generateReport() -> PerformanceReport {
        queue.sync {
            let sortedMetrics = metrics.values.sorted { $0.averageDuration > $1.averageDuration }
            return PerformanceReport(
                metrics: sortedMetrics,
                generatedAt: Date(),
                totalOperations: sortedMetrics.reduce(0) { $0 + $1.count }
            )
        }
    }
    
    func logReport() {
        let report = generateReport()
        
        logger.info("=== Performance Report ===")
        logger.info("Total operations: \(report.totalOperations)")
        logger.info("Generated at: \(report.generatedAt)")
        
        for metric in report.metrics {
            logger.info("""
                \(metric.operation.rawValue):
                  Count: \(metric.count)
                  Average: \(String(format: "%.3f", metric.averageDuration))s
                  Min: \(String(format: "%.3f", metric.minDuration))s
                  Max: \(String(format: "%.3f", metric.maxDuration))s
                  P95: \(String(format: "%.3f", metric.p95Duration))s
                """)
        }
    }
    
    // MARK: - Memory Monitoring
    
    func reportMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        
        logger.info("""
            Memory Usage:
              Used: \(self.formatBytes(memoryUsage.used))
              Free: \(self.formatBytes(memoryUsage.free))
              Total: \(self.formatBytes(memoryUsage.total))
            """)
    }
    
    private func getMemoryUsage() -> (used: Int64, free: Int64, total: Int64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let used = Int64(info.resident_size)
            let total = Int64(ProcessInfo.processInfo.physicalMemory)
            let free = total - used
            return (used, free, total)
        }
        
        return (0, 0, 0)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Performance Operation
enum PerformanceOperation: String, CaseIterable {
    case appLaunch = "app_launch"
    case calendarScan = "calendar_scan"
    case widgetRefresh = "widget_refresh"
    case workoutLoad = "workout_load"
    case cloudKitFetch = "cloudkit_fetch"
    case cloudKitSave = "cloudkit_save"
    case imageLoad = "image_load"
    case databaseQuery = "database_query"
    case authenticationFlow = "authentication_flow"
    
    var threshold: TimeInterval {
        switch self {
        case .appLaunch: return 2.0
        case .calendarScan: return 1.0
        case .widgetRefresh: return 0.5
        case .workoutLoad: return 0.3
        case .cloudKitFetch: return 3.0
        case .cloudKitSave: return 2.0
        case .imageLoad: return 0.5
        case .databaseQuery: return 0.2
        case .authenticationFlow: return 5.0
        }
    }
}

// MARK: - Performance Measurement
struct PerformanceMeasurement {
    let operation: PerformanceOperation
    let startTime: CFAbsoluteTime
}

// MARK: - Performance Metric
struct PerformanceMetric {
    let operation: PerformanceOperation
    private(set) var measurements: [TimeInterval] = []
    
    var count: Int { measurements.count }
    var totalDuration: TimeInterval { measurements.reduce(0, +) }
    var averageDuration: TimeInterval { count > 0 ? totalDuration / Double(count) : 0 }
    var minDuration: TimeInterval { measurements.min() ?? 0 }
    var maxDuration: TimeInterval { measurements.max() ?? 0 }
    
    var p95Duration: TimeInterval {
        guard !measurements.isEmpty else { return 0 }
        let sorted = measurements.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }
    
    mutating func addMeasurement(_ duration: TimeInterval) {
        measurements.append(duration)
        
        // Keep only last 100 measurements to avoid memory growth
        if measurements.count > 100 {
            measurements.removeFirst()
        }
    }
}

// MARK: - Performance Report
struct PerformanceReport {
    let metrics: [PerformanceMetric]
    let generatedAt: Date
    let totalOperations: Int
} 