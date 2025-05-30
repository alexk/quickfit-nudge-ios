import Foundation
import StoreKit

// MARK: - Subscription Manager
@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    // Product IDs
    private let monthlyProductID = "com.fitdad.nudge.monthly"
    private let yearlyProductID = "com.fitdad.nudge.yearly"
    private let teamProductID = "com.fitdad.nudge.team"
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .none
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private var updateTask: Task<Void, Never>?
    
    private init() {
        updateTask = Task {
            await loadProducts()
            await updateSubscriptionStatus()
            
            // Listen for transaction updates
            for await update in Transaction.updates {
                await handleTransactionUpdate(update)
            }
        }
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            subscriptions = try await Product.products(for: [monthlyProductID, yearlyProductID, teamProductID])
            logInfo("Loaded \(subscriptions.count) products", category: .subscription)
        } catch {
            logError("Failed to load products: \(error)", category: .subscription)
            self.error = error
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            logError("Failed to restore purchases: \(error)", category: .subscription)
            self.error = error
        }
    }
    
    func updateSubscriptionStatus() async {
        var purchasedSubs: [Product] = []
        
        for product in subscriptions {
            let entitlement = await product.currentEntitlement
            
            if entitlement != nil {
                purchasedSubs.append(product)
            }
        }
        
        self.purchasedSubscriptions = purchasedSubs
        
        // Update subscription status
        if purchasedSubs.isEmpty {
            subscriptionStatus = .none
        } else if let firstSub = purchasedSubs.first {
            if firstSub.id == yearlyProductID {
                subscriptionStatus = .premium(.yearly)
            } else if firstSub.id == teamProductID {
                subscriptionStatus = .team
            } else {
                subscriptionStatus = .premium(.monthly)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func handleTransactionUpdate(_ verification: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
        } catch {
            logError("Transaction failed verification: \(error)", category: .subscription)
        }
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: Equatable {
    case none
    case trial(daysRemaining: Int)
    case premium(PlanType)
    case team
    case expired
    
    enum PlanType: String {
        case monthly = "Monthly"
        case yearly = "Annual"
    }
    
    var isActive: Bool {
        switch self {
        case .premium, .trial, .team:
            return true
        case .none, .expired:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .none:
            return "Free"
        case .trial(let days):
            return "Trial (\(days) days left)"
        case .premium(let plan):
            return "Premium \(plan.rawValue)"
        case .team:
            return "Team Plan"
        case .expired:
            return "Expired"
        }
    }
    
    var allowsTeamFeatures: Bool {
        switch self {
        case .team: return true
        default: return false
        }
    }
}

// MARK: - Subscription Error
enum SubscriptionError: LocalizedError {
    case verificationFailed
    case purchaseFailed
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "We couldn't verify your purchase - let's try that again"
        case .purchaseFailed:
            return "Something went wrong with your purchase - your card wasn't charged"
        case .productNotFound:
            return "We're having trouble loading subscription options right now"
        }
    }
}

// MARK: - Product Extensions
extension Product {
    var currentEntitlement: Product.SubscriptionInfo.Status? {
        get async {
            do {
                let statuses = try await self.subscription?.status ?? []
                return statuses.first { $0.state == .subscribed || $0.state == .inGracePeriod }
            } catch {
                return nil
            }
        }
    }
    
    var formattedPrice: String {
        self.displayPrice
    }
    
    var periodText: String {
        guard let subscription = self.subscription else { return "" }
        
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        
        switch unit {
        case .day:
            return value == 1 ? "daily" : "every \(value) days"
        case .week:
            return value == 1 ? "weekly" : "every \(value) weeks"
        case .month:
            return value == 1 ? "monthly" : "every \(value) months"
        case .year:
            return value == 1 ? "yearly" : "every \(value) years"
        @unknown default:
            return ""
        }
    }
    
    var trialText: String? {
        guard let trial = self.subscription?.introductoryOffer else { return nil }
        
        let period = trial.period
        let unit = period.unit
        let value = period.value
        
        var text = "Start with "
        
        switch unit {
        case .day:
            text += value == 1 ? "1 day" : "\(value) days"
        case .week:
            text += value == 1 ? "1 week" : "\(value) weeks"
        case .month:
            text += value == 1 ? "1 month" : "\(value) months"
        case .year:
            text += value == 1 ? "1 year" : "\(value) years"
        @unknown default:
            return nil
        }
        
        text += " free trial"
        return text
    }
} 