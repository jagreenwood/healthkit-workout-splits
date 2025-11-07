import Foundation
import HealthKit

// MARK: - HKWorkout Convenience Extensions

extension HKWorkout {
    /// Returns a human-readable description of the workout activity type
    ///
    /// Example:
    /// ```swift
    /// let workout = ... // HKWorkout
    /// print(workout.activityName)  // "Running", "Cycling", etc.
    /// ```
    public var activityName: String {
        switch workoutActivityType {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .hiking:
            return "Hiking"
        default:
            return "Workout"
        }
    }

    /// Returns the total distance in a specific unit
    ///
    /// - Parameter unit: The unit to convert to (e.g., .miles, .kilometers)
    /// - Returns: Distance in the specified unit, or nil if no distance recorded
    public func distance(in unit: UnitLength) -> Double? {
        guard let totalDistance = self.totalDistance else {
            return nil
        }

        // Convert UnitLength to HKUnit
        let hkUnit: HKUnit
        switch unit {
        case .miles:
            hkUnit = .mile()
        case .kilometers:
            hkUnit = .meterUnit(with: .kilo)
        case .meters:
            hkUnit = .meter()
        case .feet:
            hkUnit = .foot()
        case .yards:
            hkUnit = .yard()
        default:
            // Default to meters for unsupported units
            hkUnit = .meter()
        }

        return totalDistance.doubleValue(for: hkUnit)
    }

    /// Returns a formatted string describing the workout
    ///
    /// Example: "Running: 5.25 mi in 42:30"
    public var formattedSummary: String {
        var summary = activityName

        if let distance = self.distance(in: .miles) {
            summary += String(format: ": %.2f mi", distance)
        }

        let duration = endDate.timeIntervalSince(startDate)
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        summary += String(format: " in %d:%02d", minutes, seconds)

        return summary
    }

    /// Checks if the workout has pause events
    public var hasPauses: Bool {
        guard let events = workoutEvents else { return false }
        return events.contains { $0.type == .pause || $0.type == .resume }
    }

    /// Returns the total paused time in seconds
    ///
    /// Calculates the sum of all pause intervals in the workout.
    /// If there's an unpaired pause at the end, it's counted until the workout end time.
    public var totalPausedTime: TimeInterval {
        guard let events = workoutEvents else { return 0 }

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

        // Handle unpaired pause at end
        if let start = pauseStart {
            let interval = DateInterval(start: start, end: endDate)
            pauseIntervals.append(interval)
        }

        return pauseIntervals.reduce(0) { $0 + $1.duration }
    }

    /// Returns the active (non-paused) duration in seconds
    public var activeDuration: TimeInterval {
        let totalDuration = endDate.timeIntervalSince(startDate)
        return totalDuration - totalPausedTime
    }
}
