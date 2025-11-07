import Foundation

/// Errors that can occur during split calculation
public enum SplitCalculatorError: Error, LocalizedError {
    /// HealthKit is not available on this device
    case healthKitNotAvailable

    /// The app is not authorized to read health data
    ///
    /// Note: HealthKit does not reveal whether read permission was explicitly denied.
    /// This error typically indicates authorization was not requested or the user
    /// has restricted health data access in Settings.
    case notAuthorized

    /// No distance samples found for the workout
    ///
    /// This can occur if:
    /// - The workout type doesn't record distance data
    /// - Distance samples were not captured during the workout
    /// - The user denied read permission (appears as no data)
    case noDistanceData

    /// Insufficient distance data to calculate meaningful splits
    ///
    /// This occurs when distance samples exist but are too sparse or incomplete
    /// to provide reliable split calculations.
    case insufficientDistanceData

    /// Invalid configuration provided
    ///
    /// - Parameter message: Description of what is invalid
    case invalidConfiguration(String)

    /// The workout distance is too short to calculate any splits
    ///
    /// This occurs when the total workout distance is zero or negligible.
    case workoutTooShort

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"

        case .notAuthorized:
            return "Not authorized to access health data. Please enable HealthKit permissions in Settings."

        case .noDistanceData:
            return "No distance data found for this workout. The workout may not have recorded distance samples, or health data permissions may not be granted."

        case .insufficientDistanceData:
            return "Insufficient distance data to calculate splits. The workout may have too few distance samples."

        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"

        case .workoutTooShort:
            return "Workout distance is too short to calculate splits"
        }
    }

    public var failureReason: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not supported on this device type"

        case .notAuthorized:
            return "Health data read permissions are not granted"

        case .noDistanceData:
            return "No distance samples were found within the workout time period"

        case .insufficientDistanceData:
            return "Distance samples are too sparse or incomplete"

        case .invalidConfiguration:
            return "The split configuration contains invalid values"

        case .workoutTooShort:
            return "The workout's total distance is zero or negligible"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .healthKitNotAvailable:
            return "This feature requires a device with HealthKit support"

        case .notAuthorized:
            return "Open the Settings app and grant this app permission to read workout and distance data from Health"

        case .noDistanceData:
            return "Ensure the workout was recorded with a device that tracks distance, and that health permissions are granted. Note that some workout types do not record distance data."

        case .insufficientDistanceData:
            return "Try a different workout with more complete distance tracking, or check that the workout was recorded properly"

        case .invalidConfiguration:
            return "Verify that the split distance is a positive value"

        case .workoutTooShort:
            return "Select a workout with measurable distance, or try a smaller split distance"
        }
    }
}
