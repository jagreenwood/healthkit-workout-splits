import HealthKit
import HealthKitWorkoutSplits

/// Error types for HealthKit operations
enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationFailed
    case queryFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationFailed:
            return "Failed to request HealthKit authorization"
        case .queryFailed:
            return "Failed to query workout data"
        }
    }
}

/// Actor-based manager for thread-safe HealthKit operations
actor HealthKitManager {
    private let healthStore = HKHealthStore()
    private let splitCalculator = SplitCalculator()

    /// Request authorization for reading workout and distance data
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!
        ]

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    /// Fetch workouts from the specified start date to now
    /// - Parameter startDate: The earliest date to fetch workouts from
    /// - Returns: Array of HKWorkout objects sorted by start date (newest first)
    func fetchWorkouts(from startDate: Date) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Date(),
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    /// Calculate 1-mile splits for a workout with pause exclusion
    /// - Parameter workout: The workout to calculate splits for
    /// - Returns: Array of WorkoutSplit objects
    func calculateSplits(for workout: HKWorkout) async throws -> [WorkoutSplit] {
        let configuration = SplitConfiguration.miles(1.0, excludePausedTime: true)
        return try await splitCalculator.calculateSplits(
            for: workout,
            configuration: configuration,
            healthStore: healthStore
        )
    }
}
