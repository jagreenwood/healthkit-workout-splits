import Foundation
import HealthKit

/// Processes distance samples from HealthKit workouts
///
/// The `DistanceSampleProcessor` handles fetching distance samples for a workout
/// and determining the appropriate distance quantity type based on workout activity.
class DistanceSampleProcessor {

    // MARK: - Distance Type Mapping

    /// Determines the appropriate distance quantity type for a workout activity
    ///
    /// Different workout types record distance using different quantity types:
    /// - Running, Walking, Hiking: `.distanceWalkingRunning`
    /// - Cycling: `.distanceCycling`
    /// - Swimming: `.distanceSwimming`
    /// - All others: `.distanceWalkingRunning` (default)
    ///
    /// - Parameter activityType: The workout activity type
    /// - Returns: The HKQuantityType to use for querying distance samples
    func distanceQuantityType(for activityType: HKWorkoutActivityType) -> HKQuantityType {
        switch activityType {
        case .running, .walking, .hiking:
            return HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

        case .cycling:
            return HKQuantityType.quantityType(forIdentifier: .distanceCycling)!

        case .swimming:
            return HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!

        default:
            // Default to walking/running distance for unsupported types
            return HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        }
    }

    // MARK: - Sample Fetching

    /// Fetches distance samples for a workout
    ///
    /// Queries HealthKit for distance samples that occurred during the workout's
    /// time period, filtered to only include samples from the same source as the workout.
    /// This prevents issues with overlapping samples when multiple devices (e.g., iPhone
    /// and Apple Watch) record distance data simultaneously.
    ///
    /// Samples are sorted by start date in ascending order.
    ///
    /// - Parameters:
    ///   - workout: The workout to fetch distance samples for
    ///   - distanceType: The distance quantity type to query
    ///   - healthStore: The HKHealthStore to query
    /// - Returns: Array of distance samples from the workout's source, sorted by start date
    /// - Throws: Any error from the HealthKit query
    func fetchDistanceSamples(
        for workout: HKWorkout,
        distanceType: HKQuantityType,
        from healthStore: HKHealthStore
    ) async throws -> [HKQuantitySample] {
        // Create time predicate for workout duration
        let timePredicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )

        // Create source predicate to match workout's source device
        // This prevents duplicate/overlapping samples from multiple devices
        let sourcePredicate = HKQuery.predicateForObjects(
            from: workout.sourceRevision.source
        )

        // Combine predicates to filter by both time and source
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            timePredicate,
            sourcePredicate
        ])

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: distanceType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let samples = results as? [HKQuantitySample] ?? []
                continuation.resume(returning: samples)
            }

            healthStore.execute(query)
        }
    }
}
