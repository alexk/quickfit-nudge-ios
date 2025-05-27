import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String?
    let displayName: String
    let createdAt: Date
    var subscriptionStatus: SubscriptionStatus = .none
    
    enum SubscriptionStatus: String, Codable {
        case none = "none"
        case trial = "trial"
        case active = "active"
        case expired = "expired"
        case cancelled = "cancelled"
    }
} 