import Foundation
import HealthKit
@testable import HealthKitWorkoutSplits

/// Helper class for creating mock HealthKit data for testing
class MockWorkoutData {

    // MARK: - Distance Samples

    /// Creates a mock distance sample
    ///
    /// - Parameters:
    ///   - distance: Distance in meters
    ///   - startDate: Start time of the sample
    ///   - endDate: End time of the sample
    ///   - type: The distance quantity type (default: walking/running)
    /// - Returns: A mock HKQuantitySample
    static func createDistanceSample(
        distance: Double,
        startDate: Date,
        endDate: Date,
        type: HKQuantityType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ) -> HKQuantitySample {
        let quantity = HKQuantity(unit: .meter(), doubleValue: distance)

        return HKQuantitySample(
            type: type,
            quantity: quantity,
            start: startDate,
            end: endDate
        )
    }

    /// Creates a series of evenly spaced distance samples
    ///
    /// Useful for simulating a steady-pace workout.
    ///
    /// - Parameters:
    ///   - count: Number of samples to create
    ///   - distancePerSample: Distance in meters for each sample
    ///   - secondsPerSample: Duration of each sample
    ///   - startDate: Start time of the first sample
    /// - Returns: Array of distance samples
    static func createEvenSamples(
        count: Int,
        distancePerSample: Double,
        secondsPerSample: TimeInterval,
        startDate: Date = Date()
    ) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []

        for i in 0..<count {
            let sampleStart = startDate.addingTimeInterval(TimeInterval(i) * secondsPerSample)
            let sampleEnd = sampleStart.addingTimeInterval(secondsPerSample)

            let sample = createDistanceSample(
                distance: distancePerSample,
                startDate: sampleStart,
                endDate: sampleEnd
            )
            samples.append(sample)
        }

        return samples
    }

    /// Creates samples that simulate a 5K run with varying pace
    ///
    /// - Parameter startDate: Start time of the run
    /// - Returns: Array of distance samples covering approximately 5000 meters
    static func create5KRun(startDate: Date = Date()) -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []
        var currentDate = startDate

        // First kilometer - warmup (slower)
        for _ in 0..<10 {
            let sample = createDistanceSample(
                distance: 100,
                startDate: currentDate,
                endDate: currentDate.addingTimeInterval(35)  // ~5:50/km pace
            )
            samples.append(sample)
            currentDate = sample.endDate
        }

        // Middle 3 kilometers - steady pace
        for _ in 0..<30 {
            let sample = createDistanceSample(
                distance: 100,
                startDate: currentDate,
                endDate: currentDate.addingTimeInterval(30)  // 5:00/km pace
            )
            samples.append(sample)
            currentDate = sample.endDate
        }

        // Final kilometer - finishing sprint
        for _ in 0..<10 {
            let sample = createDistanceSample(
                distance: 100,
                startDate: currentDate,
                endDate: currentDate.addingTimeInterval(27)  // ~4:30/km pace
            )
            samples.append(sample)
            currentDate = sample.endDate
        }

        return samples
    }

    // MARK: - Workouts

    /// Creates a mock workout
    ///
    /// - Parameters:
    ///   - activityType: Type of workout
    ///   - startDate: Workout start time
    ///   - endDate: Workout end time
    ///   - totalDistance: Total distance in meters (optional)
    ///   - events: Workout events (pauses, resumes, etc.)
    /// - Returns: A mock HKWorkout
    static func createWorkout(
        activityType: HKWorkoutActivityType = .running,
        startDate: Date,
        endDate: Date,
        totalDistance: Double? = nil,
        events: [HKWorkoutEvent] = []
    ) -> HKWorkout {
        let distanceQuantity: HKQuantity? = totalDistance.map {
            HKQuantity(unit: .meter(), doubleValue: $0)
        }

        return HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            workoutEvents: events,
            totalEnergyBurned: nil,
            totalDistance: distanceQuantity,
            totalFlightsClimbed: nil,
            device: nil,
            metadata: nil
        )
    }

    /// Creates a workout with pause events
    ///
    /// - Parameters:
    ///   - startDate: Workout start time
    ///   - totalDuration: Total workout duration in seconds
    ///   - pauseIntervals: Array of (start offset, duration) for pauses
    /// - Returns: A mock HKWorkout with pause/resume events
    static func createWorkoutWithPauses(
        startDate: Date = Date(),
        totalDuration: TimeInterval = 3600,
        pauseIntervals: [(startOffset: TimeInterval, duration: TimeInterval)]
    ) -> HKWorkout {
        let endDate = startDate.addingTimeInterval(totalDuration)
        var events: [HKWorkoutEvent] = []

        for interval in pauseIntervals {
            let pauseStart = startDate.addingTimeInterval(interval.startOffset)
            let resumeTime = pauseStart.addingTimeInterval(interval.duration)

            let pauseEvent = HKWorkoutEvent(
                type: .pause,
                dateInterval: DateInterval(start: pauseStart, end: pauseStart),
                metadata: nil
            )

            let resumeEvent = HKWorkoutEvent(
                type: .resume,
                dateInterval: DateInterval(start: resumeTime, end: resumeTime),
                metadata: nil
            )

            events.append(pauseEvent)
            events.append(resumeEvent)
        }

        return HKWorkout(
            activityType: .running,
            start: startDate,
            end: endDate,
            workoutEvents: events,
            totalEnergyBurned: nil,
            totalDistance: HKQuantity(unit: .meter(), doubleValue: 5000),
            totalFlightsClimbed: nil,
            device: nil,
            metadata: nil
        )
    }

    // MARK: - Date Helpers

    /// Creates a date from components for easier test setup
    static func date(hour: Int, minute: Int, second: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = second
        return Calendar.current.date(from: components)!
    }
}
