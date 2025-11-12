import Foundation
import HealthKit

/// Main calculator for determining distance splits from HealthKit workouts
///
/// The `SplitCalculator` analyzes completed workouts and calculates distance-based splits
/// using HKQuantitySample distance data. This approach works for both indoor and outdoor
/// workouts as long as distance samples were recorded.
///
/// Example usage:
/// ```swift
/// import HealthKit
/// import HealthKitWorkoutSplits
///
/// let healthStore = HKHealthStore()
/// let calculator = SplitCalculator()
///
/// // Request authorization
/// try await SplitCalculator.requestAuthorization(from: healthStore)
///
/// // Calculate mile splits for a workout
/// let config = SplitConfiguration.miles(1.0, excludePausedTime: true)
/// let splits = try await calculator.calculateSplits(
///     for: workout,
///     configuration: config,
///     healthStore: healthStore
/// )
///
/// for split in splits {
///     print("Split \(split.splitNumber): \(split.duration)s")
/// }
/// ```
public class SplitCalculator {

    // MARK: - Properties

    private let sampleProcessor = DistanceSampleProcessor()
    private let splitAggregator = SplitAggregator()

    // MARK: - Initialization

    /// Creates a new split calculator
    public init() {}

    // MARK: - Authorization

    /// Requests HealthKit authorization to read workout and distance data
    ///
    /// This method requests permission to read:
    /// - Workout data (HKWorkoutType)
    /// - Walking/Running distance
    /// - Cycling distance
    /// - Swimming distance
    ///
    /// Note: HealthKit does not reveal whether the user denied read permissions.
    /// If permission is denied, queries will return empty results.
    ///
    /// - Parameter healthStore: The HKHealthStore instance to request authorization from
    /// - Throws: `SplitCalculatorError.healthKitNotAvailable` if HealthKit is not supported
    public static func requestAuthorization(from healthStore: HKHealthStore) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw SplitCalculatorError.healthKitNotAvailable
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    /// Checks the authorization status for a specific quantity type
    ///
    /// Note: HealthKit only allows checking the status of write permissions.
    /// Read permission status cannot be determined and will always return `.notDetermined`.
    ///
    /// - Parameters:
    ///   - type: The quantity type to check
    ///   - healthStore: The HKHealthStore instance
    /// - Returns: The authorization status (note: always `.notDetermined` for read permissions)
    public static func authorizationStatus(
        for type: HKQuantityType,
        in healthStore: HKHealthStore
    ) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }

    // MARK: - Split Calculation

    /// Calculates distance splits for a workout
    ///
    /// This method analyzes a completed workout and calculates splits based on the
    /// provided configuration. It fetches distance samples from HealthKit, processes
    /// them to determine split boundaries, and returns detailed split information.
    ///
    /// Example:
    /// ```swift
    /// let config = SplitConfiguration.miles(1.0, excludePausedTime: true)
    /// let splits = try await calculator.calculateSplits(
    ///     for: workout,
    ///     configuration: config,
    ///     healthStore: healthStore
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - workout: The HKWorkout to calculate splits for
    ///   - configuration: Configuration specifying split distance and pause handling
    ///   - healthStore: The HKHealthStore to query for distance samples
    /// - Returns: Array of WorkoutSplit objects representing each calculated split
    /// - Throws:
    ///   - `SplitCalculatorError.invalidConfiguration`: If configuration is invalid
    ///   - `SplitCalculatorError.workoutTooShort`: If workout has no distance
    ///   - `SplitCalculatorError.noDistanceData`: If no distance samples found
    ///   - `SplitCalculatorError.insufficientDistanceData`: If samples are too sparse
    public func calculateSplits(
        for workout: HKWorkout,
        configuration: SplitConfiguration,
        healthStore: HKHealthStore
    ) async throws -> [WorkoutSplit] {
        // 1. Validate configuration
        try configuration.validate()

        // 2. Validate workout has distance
        guard let totalDistance = workout.totalDistance,
              totalDistance.doubleValue(for: .meter()) > 0 else {
            throw SplitCalculatorError.workoutTooShort
        }

        // 3. Determine distance type based on workout activity
        let distanceType = sampleProcessor.distanceQuantityType(for: workout.workoutActivityType)

        // 4. Fetch distance samples (filtered to workout's source device)
        let samples = try await sampleProcessor.fetchDistanceSamples(
            for: workout,
            distanceType: distanceType,
            from: healthStore
        )

        guard !samples.isEmpty else {
            throw SplitCalculatorError.noDistanceData
        }

        // Debug: Log sample information
        #if DEBUG
        let sampleDistance = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .meter()) }
        let sourceName = workout.sourceRevision.source.name
        print("[SplitCalculator] Fetched \(samples.count) samples from '\(sourceName)'")
        print("[SplitCalculator] Total distance from samples: \(String(format: "%.2f", sampleDistance))m")
        if let workoutDistance = workout.totalDistance?.doubleValue(for: .meter()) {
            let diff = abs(sampleDistance - workoutDistance)
            let percentDiff = (diff / workoutDistance) * 100
            print("[SplitCalculator] Workout distance: \(String(format: "%.2f", workoutDistance))m (diff: \(String(format: "%.1f%%", percentDiff)))")
        }
        #endif

        // 5. Get pause intervals if needed
        let pauseIntervals = configuration.excludePausedTime
            ? extractPauseIntervals(from: workout)
            : []

        // 6. Calculate splits
        let splits = splitAggregator.calculateSplitsFromSamples(
            samples: samples,
            splitDistance: configuration.splitDistance,
            pauseIntervals: pauseIntervals,
            workoutStartDate: workout.startDate
        )

        guard !splits.isEmpty else {
            throw SplitCalculatorError.insufficientDistanceData
        }

        return splits
    }

    // MARK: - Helper Methods

    /// Extracts pause intervals from workout events
    ///
    /// Processes workout events to find pause/resume pairs and creates DateInterval
    /// objects for each pause period.
    ///
    /// - Parameter workout: The workout to extract pause intervals from
    /// - Returns: Array of pause intervals (empty if no pause events)
    private func extractPauseIntervals(from workout: HKWorkout) -> [DateInterval] {
        guard let events = workout.workoutEvents else { return [] }

        var pauseIntervals: [DateInterval] = []
        var pauseStart: Date?

        for event in events.sorted(by: { $0.dateInterval.start < $1.dateInterval.start }) {
            switch event.type {
            case .pause:
                pauseStart = event.dateInterval.start

            case .resume:
                if let start = pauseStart {
                    let interval = DateInterval(start: start, end: event.dateInterval.start)
                    pauseIntervals.append(interval)
                    pauseStart = nil
                }

            default:
                break
            }
        }

        // Handle unpaired pause at end of workout (edge case)
        if let start = pauseStart {
            let interval = DateInterval(start: start, end: workout.endDate)
            pauseIntervals.append(interval)
        }

        return pauseIntervals
    }
}
