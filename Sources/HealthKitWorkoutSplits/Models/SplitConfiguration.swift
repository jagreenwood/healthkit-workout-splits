import Foundation
import HealthKit

/// Configuration for calculating workout splits
///
/// Defines the target distance for each split and whether to exclude paused time
/// from duration calculations.
///
/// Example:
/// ```swift
/// // Calculate mile splits, excluding paused time
/// let config = SplitConfiguration.miles(1.0, excludePausedTime: true)
///
/// // Calculate 5K splits
/// let config = SplitConfiguration.kilometers(5.0)
///
/// // Custom distance splits
/// let config = SplitConfiguration(
///     splitDistance: Measurement(value: 400, unit: .meters),
///     excludePausedTime: false
/// )
/// ```
public struct SplitConfiguration {
    /// The target distance for each split
    public let splitDistance: Measurement<UnitLength>

    /// Whether to exclude paused time from split duration calculations
    ///
    /// When `true`, the calculator will subtract any time spent paused from split durations.
    /// When `false`, all elapsed time is included in the split duration.
    ///
    /// Note: Requires workout to have pause/resume events. If no pause events exist,
    /// this setting has no effect.
    public let excludePausedTime: Bool

    /// Creates a split configuration with the specified settings
    ///
    /// - Parameters:
    ///   - splitDistance: The target distance for each split
    ///   - excludePausedTime: Whether to exclude paused time from durations (default: false)
    public init(
        splitDistance: Measurement<UnitLength>,
        excludePausedTime: Bool = false
    ) {
        self.splitDistance = splitDistance
        self.excludePausedTime = excludePausedTime
    }

    /// Creates a configuration for mile-based splits
    ///
    /// - Parameters:
    ///   - distance: The distance in miles (e.g., 1.0 for mile splits)
    ///   - excludePausedTime: Whether to exclude paused time (default: false)
    /// - Returns: A configuration with the specified mile distance
    public static func miles(
        _ distance: Double,
        excludePausedTime: Bool = false
    ) -> SplitConfiguration {
        SplitConfiguration(
            splitDistance: Measurement(value: distance, unit: .miles),
            excludePausedTime: excludePausedTime
        )
    }

    /// Creates a configuration for kilometer-based splits
    ///
    /// - Parameters:
    ///   - distance: The distance in kilometers (e.g., 1.0 for kilometer splits)
    ///   - excludePausedTime: Whether to exclude paused time (default: false)
    /// - Returns: A configuration with the specified kilometer distance
    public static func kilometers(
        _ distance: Double,
        excludePausedTime: Bool = false
    ) -> SplitConfiguration {
        SplitConfiguration(
            splitDistance: Measurement(value: distance, unit: .kilometers),
            excludePausedTime: excludePausedTime
        )
    }
}

// MARK: - Validation

extension SplitConfiguration {
    /// Validates the configuration
    ///
    /// - Throws: `SplitCalculatorError.invalidConfiguration` if the split distance is invalid
    func validate() throws {
        let distanceInMeters = splitDistance.converted(to: .meters).value
        guard distanceInMeters > 0 else {
            throw SplitCalculatorError.invalidConfiguration(
                "Split distance must be greater than zero"
            )
        }
    }
}
