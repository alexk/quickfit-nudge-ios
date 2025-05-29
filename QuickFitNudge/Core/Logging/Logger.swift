import Foundation
import os.log

// MARK: - App Logger
final class AppLogger {
    static let shared = AppLogger()
    
    private let subsystem = "com.quickfit.nudge"
    
    // Log categories for different app areas
    private let analyticsLog = OSLog(subsystem: "com.quickfit.nudge", category: "Analytics")
    private let cloudKitLog = OSLog(subsystem: "com.quickfit.nudge", category: "CloudKit")
    private let calendarLog = OSLog(subsystem: "com.quickfit.nudge", category: "Calendar")
    private let notificationLog = OSLog(subsystem: "com.quickfit.nudge", category: "Notifications")
    private let watchLog = OSLog(subsystem: "com.quickfit.nudge", category: "WatchConnectivity")
    private let subscriptionLog = OSLog(subsystem: "com.quickfit.nudge", category: "Subscription")
    private let authLog = OSLog(subsystem: "com.quickfit.nudge", category: "Authentication")
    private let generalLog = OSLog(subsystem: "com.quickfit.nudge", category: "General")
    
    private init() {}
    
    // MARK: - Logging Methods
    
    func analytics(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: analyticsLog, type: type, message)
    }
    
    func cloudKit(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: cloudKitLog, type: type, message)
    }
    
    func calendar(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: calendarLog, type: type, message)
    }
    
    func notification(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: notificationLog, type: type, message)
    }
    
    func watch(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: watchLog, type: type, message)
    }
    
    func subscription(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: subscriptionLog, type: type, message)
    }
    
    func auth(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: authLog, type: type, message)
    }
    
    func general(_ message: String, type: OSLogType = .info) {
        os_log("%{public}@", log: generalLog, type: type, message)
    }
    
    // MARK: - Convenience Methods
    
    func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        log(message, type: .debug, category: category)
        #endif
    }
    
    func info(_ message: String, category: LogCategory = .general) {
        log(message, type: .info, category: category)
    }
    
    func error(_ message: String, category: LogCategory = .general) {
        log(message, type: .error, category: category)
    }
    
    func fault(_ message: String, category: LogCategory = .general) {
        log(message, type: .fault, category: category)
    }
    
    private func log(_ message: String, type: OSLogType, category: LogCategory) {
        switch category {
        case .analytics: analytics(message, type: type)
        case .cloudKit: cloudKit(message, type: type)
        case .calendar: calendar(message, type: type)
        case .notification: notification(message, type: type)
        case .watch: watch(message, type: type)
        case .subscription: subscription(message, type: type)
        case .auth: auth(message, type: type)
        case .general: general(message, type: type)
        }
    }
}

// MARK: - Log Categories
enum LogCategory {
    case analytics
    case cloudKit
    case calendar
    case notification
    case watch
    case subscription
    case auth
    case general
}

// MARK: - Global Logging Functions
func logDebug(_ message: String, category: LogCategory = .general) {
    AppLogger.shared.debug(message, category: category)
}

func logInfo(_ message: String, category: LogCategory = .general) {
    AppLogger.shared.info(message, category: category)
}

func logError(_ message: String, category: LogCategory = .general) {
    AppLogger.shared.error(message, category: category)
}

func logFault(_ message: String, category: LogCategory = .general) {
    AppLogger.shared.fault(message, category: category)
}