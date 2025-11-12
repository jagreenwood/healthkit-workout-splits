import Foundation
import HealthKit

/// Aggregates distance samples into split calculations
///
/// The `SplitAggregator` processes distance samples and calculates splits based on
/// the target split distance. It handles edge cases like samples crossing split boundaries,
/// pause time exclusion, and partial final splits.
class SplitAggregator {

    // MARK: - Split Calculation

    /// Calculates splits from distance samples
    ///
    /// This algorithm processes samples sequentially, accumulating distance until
    /// split boundaries are crossed. When a sample crosses a boundary, time is
    /// distributed proportionally based on the distance covered.
    ///
    /// Algorithm overview:
    /// 1. Process samples in chronological order
    /// 2. For each sample, add distance to cumulative total
    /// 3. If cumulative distance crosses split boundary:
    ///    - Calculate time needed to reach boundary (proportional)
    ///    - Create WorkoutSplit for completed split
    ///    - Continue with remaining distance from sample
    /// 4. Handle samples that cross multiple split boundaries
    /// 5. Create partial split for any remaining distance
    ///
    /// - Parameters:
    ///   - samples: Distance samples sorted by start date
    ///   - splitDistance: Target distance for each split
    ///   - pauseIntervals: Time intervals when workout was paused (empty if not excluding)
    /// - Returns: Array of calculated workout splits
    func calculateSplitsFromSamples(
        samples: [HKQuantitySample],
        splitDistance: Measurement<UnitLength>,
        pauseIntervals: [DateInterval],
        workoutStartDate: Date
    ) -> [WorkoutSplit] {
        guard !samples.isEmpty else { return [] }

        let targetDistanceMeters = splitDistance.converted(to: .meters).value
        var splits: [WorkoutSplit] = []

        var cumulativeDistance: Double = 0  // in meters
        var currentSplitStartDistance: Double = 0
        var currentSplitStartTime: Date = workoutStartDate
        var splitNumber = 1

        for sample in samples {
            let sampleDistanceMeters = sample.quantity.doubleValue(for: .meter())
            let sampleStartTime = sample.startDate
            let sampleEndTime = sample.endDate
            let sampleDuration = sampleEndTime.timeIntervalSince(sampleStartTime)

            var remainingDistance = sampleDistanceMeters
            var sampleTimeOffset: TimeInterval = 0

            // Process this sample, which may create one or more splits
            while remainingDistance > 0 {
                let distanceToNextSplit = targetDistanceMeters - (cumulativeDistance - currentSplitStartDistance)

                if remainingDistance >= distanceToNextSplit {
                    // Sample crosses (or completes) a split boundary

                    // Calculate time portion for this split
                    let timeFraction = distanceToNextSplit / sampleDistanceMeters
                    let timeForSplit = sampleDuration * timeFraction

                    // Calculate end time for this split portion
                    let splitEndTime = sampleStartTime.addingTimeInterval(sampleTimeOffset + timeForSplit)

                    // Calculate active time (excluding pauses)
                    let activeTime = calculateActiveTime(
                        from: currentSplitStartTime,
                        to: splitEndTime,
                        excluding: pauseIntervals
                    )

                    // Calculate pace
                    let pace = calculatePace(
                        distance: targetDistanceMeters,
                        time: activeTime
                    )

                    // Create split
                    let split = WorkoutSplit(
                        splitNumber: splitNumber,
                        distance: splitDistance,
                        duration: activeTime,
                        pace: pace,
                        timestamp: splitEndTime,
                        isPartial: false
                    )
                    splits.append(split)

                    // Update tracking variables
                    cumulativeDistance += distanceToNextSplit
                    currentSplitStartDistance = cumulativeDistance
                    currentSplitStartTime = splitEndTime
                    remainingDistance -= distanceToNextSplit
                    sampleTimeOffset += timeForSplit
                    splitNumber += 1

                } else {
                    // Sample doesn't complete the current split
                    cumulativeDistance += remainingDistance
                    remainingDistance = 0
                }
            }
        }

        // Create partial split for remaining distance if any
        if cumulativeDistance > currentSplitStartDistance {
            let remainingDistance = cumulativeDistance - currentSplitStartDistance

            if remainingDistance > 0.1 { // Only create split if meaningful distance (>0.1m)
                let lastSampleEndTime = samples.last!.endDate

                let activeTime = calculateActiveTime(
                    from: currentSplitStartTime,
                    to: lastSampleEndTime,
                    excluding: pauseIntervals
                )

                let pace = calculatePace(
                    distance: remainingDistance,
                    time: activeTime
                )

                let split = WorkoutSplit(
                    splitNumber: splitNumber,
                    distance: Measurement(value: remainingDistance, unit: .meters),
                    duration: activeTime,
                    pace: pace,
                    timestamp: lastSampleEndTime,
                    isPartial: true
                )
                splits.append(split)
            }
        }

        return splits
    }

    // MARK: - Helper Methods

    /// Calculates active time between two dates, excluding paused intervals
    ///
    /// Determines how much time elapsed between start and end times, subtracting
    /// any overlapping pause intervals.
    ///
    /// - Parameters:
    ///   - startTime: Start of the time period
    ///   - endTime: End of the time period
    ///   - pauseIntervals: Intervals when workout was paused
    /// - Returns: Active time in seconds (total time - paused time)
    func calculateActiveTime(
        from startTime: Date,
        to endTime: Date,
        excluding pauseIntervals: [DateInterval]
    ) -> TimeInterval {
        let totalTime = endTime.timeIntervalSince(startTime)
        guard !pauseIntervals.isEmpty else { return totalTime }

        let segmentInterval = DateInterval(start: startTime, end: endTime)
        var pausedTime: TimeInterval = 0

        for pauseInterval in pauseIntervals {
            if let overlap = segmentInterval.intersection(with: pauseInterval) {
                pausedTime += overlap.duration
            }
        }

        return max(0, totalTime - pausedTime)
    }

    /// Calculates pace from distance and time
    ///
    /// - Parameters:
    ///   - distance: Distance in meters
    ///   - time: Time in seconds
    /// - Returns: Pace as a Measurement in meters per second
    func calculatePace(distance: Double, time: TimeInterval) -> Measurement<UnitSpeed> {
        guard time > 0 else {
            return Measurement(value: 0, unit: UnitSpeed.metersPerSecond)
        }

        let metersPerSecond = distance / time
        return Measurement(value: metersPerSecond, unit: UnitSpeed.metersPerSecond)
    }
}
