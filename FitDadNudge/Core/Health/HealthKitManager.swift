import Foundation
import HealthKit

// MARK: - HealthKit Manager
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    private let healthStore = HKHealthStore()
    
    // Types we want to read
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.workoutType()
    ]
    
    // Types we want to write
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.workoutType()
    ]
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            logError("HealthKit not available on this device", category: .general)
            return false
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await checkAuthorizationStatus()
            return isAuthorized
        } catch {
            logError("HealthKit authorization failed: \(error)", category: .general)
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        Task {
            for type in typesToWrite {
                let status = healthStore.authorizationStatus(for: type)
                if status == .sharingAuthorized {
                    isAuthorized = true
                    authorizationStatus = .sharingAuthorized
                    return
                }
            }
            
            // Check if we can at least read
            if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                let status = healthStore.authorizationStatus(for: energyType)
                authorizationStatus = status
                isAuthorized = (status == .sharingAuthorized)
            }
        }
    }
    
    // MARK: - Workout Recording
    
    func startWorkout(type: HKWorkoutActivityType, startDate: Date) async -> HKWorkout? {
        guard isAuthorized else {
            logError("HealthKit not authorized for workout recording", category: .general)
            return nil
        }
        
        // For now, return nil as we need HKWorkoutSession for proper implementation
        // This would require additional setup with workout configuration
        logInfo("Workout recording not yet implemented", category: .general)
        return nil
    }
    
    func saveWorkout(
        activityType: HKWorkoutActivityType,
        start: Date,
        end: Date,
        calories: Double?,
        heartRateSamples: [HeartRateSample]?
    ) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        // Create workout
        let workout = HKWorkout(
            activityType: activityType,
            start: start,
            end: end,
            duration: end.timeIntervalSince(start),
            totalEnergyBurned: calories.map { HKQuantity(unit: .kilocalorie(), doubleValue: $0) },
            totalDistance: nil,
            metadata: ["App": "QuickFit Nudge"]
        )
        
        try await healthStore.save(workout)
        
        // Save heart rate samples if available
        if let heartRateSamples = heartRateSamples, !heartRateSamples.isEmpty {
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            
            let samples = heartRateSamples.map { sample in
                HKQuantitySample(
                    type: heartRateType,
                    quantity: HKQuantity(unit: heartRateUnit, doubleValue: Double(sample.value)),
                    start: sample.timestamp,
                    end: sample.timestamp
                )
            }
            
            try await healthStore.save(samples)
        }
        
        logInfo("Workout saved to HealthKit", category: .general)
    }
    
    // MARK: - Data Reading
    
    func fetchTodayCalories() async -> Double? {
        guard isAuthorized else { return nil }
        
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: energyType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: nil
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }
            
            let totalCalories = samples.reduce(0) { total, sample in
                total + sample.quantity.doubleValue(for: .kilocalorie())
            }
            
            return totalCalories
        } catch {
            logError("Failed to fetch calories: \(error)", category: .general)
            return nil
        }
    }
}

// MARK: - HealthKit Errors
enum HealthKitError: LocalizedError {
    case notAuthorized
    case notAvailable
    case saveFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Please authorize QuickFit Nudge to access your health data in Settings"
        case .notAvailable:
            return "Health data is not available on this device"
        case .saveFailed(let error):
            return "Failed to save workout: \(error.localizedDescription)"
        }
    }
}

// MARK: - Workout Type Mapping
extension WorkoutType {
    var healthKitActivityType: HKWorkoutActivityType {
        switch self {
        case .hiit:
            return .highIntensityIntervalTraining
        case .stretching:
            return .flexibility
        case .strength:
            return .traditionalStrengthTraining
        case .cardio:
            return .running
        case .dadKid:
            return .play
        case .breathing:
            return .mindAndBody
        }
    }
}