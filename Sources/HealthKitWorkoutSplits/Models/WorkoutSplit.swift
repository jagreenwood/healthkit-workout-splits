import Foundation
import HealthKit

/// Represents a single distance split from a workout
///
/// A workout split contains the distance covered, time elapsed, calculated pace,
/// and metadata about the split's position in the workout.
///
/// Example:
/// ```swift
/// let split = WorkoutSplit(
///     splitNumber: 1,
///     distance: Measurement(value: 1.0, unit: UnitLength.miles),
///     duration: 480.0, // 8 minutes
///     pace: Measurement(value: 3.35, unit: UnitSpeed.metersPerSecond),
///     timestamp: Date(),
///     isPartial: false
/// )
/// print("Split \(split.splitNumber): \(split.duration)s at \(split.pace)")
/// ```
public struct WorkoutSplit {
    /// The 1-indexed split number (first split is 1, not 0)
    public let splitNumber: Int

    /// The distance covered in this split
    public let distance: Measurement<UnitLength>

    /// The duration of this split in seconds (excluding pauses if configured)
    public let duration: TimeInterval

    /// The pace for this split (distance / time)
    public let pace: Measurement<UnitSpeed>

    /// Approximate timestamp when this split ended
    public let timestamp: Date

    /// Whether this is a partial split (final split with distance < target split distance)
    public let isPartial: Bool

    /// Creates a new workout split
    ///
    /// - Parameters:
    ///   - splitNumber: The 1-indexed split number
    ///   - distance: The distance covered in this split
    ///   - duration: The time elapsed in seconds
    ///   - pace: The calculated pace
    ///   - timestamp: Approximate end time of the split
    ///   - isPartial: Whether this is a partial split
    public init(
        splitNumber: Int,
        distance: Measurement<UnitLength>,
        duration: TimeInterval,
        pace: Measurement<UnitSpeed>,
        timestamp: Date,
        isPartial: Bool
    ) {
        self.splitNumber = splitNumber
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.timestamp = timestamp
        self.isPartial = isPartial
    }
}

// MARK: - Convenience Properties

extension WorkoutSplit {
    /// Returns the pace formatted as minutes per mile
    public var minutesPerMile: Double {
        let milesPerHour = pace.converted(to: .milesPerHour).value
        guard milesPerHour > 0 else { return 0 }
        return 60.0 / milesPerHour
    }

    /// Returns the pace formatted as minutes per kilometer
    public var minutesPerKilometer: Double {
        let kilometersPerHour = pace.converted(to: .kilometersPerHour).value
        guard kilometersPerHour > 0 else { return 0 }
        return 60.0 / kilometersPerHour
    }
}

// MARK: - CustomStringConvertible

extension WorkoutSplit: CustomStringConvertible {
    public var description: String {
        let distanceStr = String(format: "%.2f", distance.converted(to: .meters).value)
        let durationStr = String(format: "%.1f", duration)
        let partial = isPartial ? " (partial)" : ""
        return "Split \(splitNumber): \(distanceStr)m in \(durationStr)s\(partial)"
    }
}
