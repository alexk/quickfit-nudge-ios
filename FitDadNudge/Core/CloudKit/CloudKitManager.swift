import Foundation
import CloudKit

@MainActor
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    // Record Types
    private enum RecordType {
        static let users = "Users"
        static let workouts = "Workouts"
        static let completions = "Completions"
        static let streaks = "Streaks"
    }
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.quickfit.nudge")
        privateDatabase = container.privateCloudDatabase
        sharedDatabase = container.sharedCloudDatabase
    }
    
    // MARK: - User Operations
    
    func saveUser(_ user: User) async throws {
        let record = CKRecord(recordType: RecordType.users, recordID: CKRecord.ID(recordName: user.id))
        
        record["email"] = user.email as CKRecordValue?
        record["displayName"] = user.displayName as CKRecordValue
        record["createdAt"] = user.createdAt as CKRecordValue
        record["subscriptionStatus"] = user.subscriptionStatus.rawValue as CKRecordValue
        
        try await privateDatabase.save(record)
    }
    
    func fetchUser(userID: String) async throws -> User {
        let recordID = CKRecord.ID(recordName: userID)
        let record = try await privateDatabase.record(for: recordID)
        
        guard record.recordType == RecordType.users else {
            throw CloudKitError.invalidRecordType
        }
        
        return try parseUser(from: record)
    }
    
    // MARK: - Generic Operations
    
    func fetch<T: Codable>(_ type: T.Type, predicate: NSPredicate = NSPredicate(value: true), limit: Int = 100) async throws -> [T] {
        let query = CKQuery(recordType: String(describing: type), predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        var results: [T] = []
        
        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query, resultsLimit: limit)
            
            var fetchErrors: [Error] = []
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if type == User.self, let user = try? parseUser(from: record) as? T {
                        results.append(user)
                    }
                case .failure(let error):
                    logError("Failed to fetch record: \(error)", category: .cloudKit)
                    fetchErrors.append(error)
                }
            }
            
            // If all fetches failed, throw an error
            if !fetchErrors.isEmpty && results.isEmpty {
                throw CloudKitError.partialFailure(errors: fetchErrors)
            }
        } catch {
            throw CloudKitError.fetchFailed(underlying: error)
        }
        
        return results
    }
    
    // MARK: - Private Helpers
    
    private func parseUser(from record: CKRecord) throws -> User {
        guard let displayName = record["displayName"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            throw CloudKitError.missingRequiredFields
        }
        
        let email = record["email"] as? String
        let subscriptionStatusRaw = record["subscriptionStatus"] as? String ?? "none"
        let subscriptionStatus = User.SubscriptionStatus(rawValue: subscriptionStatusRaw) ?? .none
        
        return User(
            id: record.recordID.recordName,
            email: email,
            displayName: displayName,
            createdAt: createdAt,
            subscriptionStatus: subscriptionStatus
        )
    }
}

// MARK: - CloudKit Errors
enum CloudKitError: LocalizedError {
    case invalidRecordType
    case missingRequiredFields
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case partialFailure(errors: [Error])
    
    var errorDescription: String? {
        switch self {
        case .invalidRecordType:
            return "Invalid record type"
        case .missingRequiredFields:
            return "Missing required fields in record"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        case .partialFailure(let errors):
            return "Partial failure: \(errors.count) records failed to fetch"
        }
    }
} 