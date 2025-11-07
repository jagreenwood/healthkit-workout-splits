# HealthKit Workout Splits

A Swift Package for calculating distance-based splits from completed HealthKit workouts using distance sample aggregation.

## Overview

HealthKitWorkoutSplits analyzes completed workouts and calculates approximate distance splits using `HKQuantitySample` distance data. This approach works for both indoor and outdoor workouts, making it compatible with treadmill runs, outdoor runs, cycling, swimming, and other distance-based activities.

### Key Features

- Calculate splits for any distance unit (miles, kilometers, custom distances)
- Optional pause time exclusion from split calculations
- Support for multiple workout types (running, cycling, swimming, hiking)
- Modern Swift async/await API
- Comprehensive error handling
- Works with both indoor and outdoor workouts

### How It Works

Instead of using GPS/location data, this package aggregates distance samples recorded by HealthKit. This means:

✅ Works with indoor workouts (treadmill, indoor cycling)
✅ Compatible with any device that records distance
✅ Simpler implementation and fewer privacy concerns

⚠️ Accuracy depends on sample frequency
⚠️ Provides approximate splits, not GPS-accurate timing

## Requirements

- iOS 16.0+ / watchOS 9.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager

Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/healthkit-workout-splits.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version and add to your target

## Quick Start

### 1. Request HealthKit Authorization

Add HealthKit entitlement and privacy description to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your workout data to calculate splits</string>
```

Request authorization in your app:

```swift
import HealthKit
import HealthKitWorkoutSplits

let healthStore = HKHealthStore()

// Request authorization
try await SplitCalculator.requestAuthorization(from: healthStore)
```

### 2. Calculate Splits for a Workout

```swift
import HealthKitWorkoutSplits

let calculator = SplitCalculator()

// Configure split distance (1 mile splits, excluding paused time)
let config = SplitConfiguration.miles(1.0, excludePausedTime: true)

// Calculate splits
do {
    let splits = try await calculator.calculateSplits(
        for: workout,
        configuration: config,
        healthStore: healthStore
    )

    // Display splits
    for split in splits {
        let minutes = Int(split.duration / 60)
        let seconds = Int(split.duration.truncatingRemainder(dividingBy: 60))
        let paceStr = split.pace.formattedPace(per: .miles)

        print("Split \(split.splitNumber): \(minutes):\(String(format: "%02d", seconds)) (\(paceStr))")
    }
} catch {
    print("Error calculating splits: \(error.localizedDescription)")
}
```

### 3. Handle Different Distance Units

```swift
// Kilometer splits
let kmConfig = SplitConfiguration.kilometers(1.0)

// Custom distance (e.g., 400 meters)
let customConfig = SplitConfiguration(
    splitDistance: Measurement(value: 400, unit: .meters),
    excludePausedTime: false
)
```

## Usage Examples

### Displaying Split Results

```swift
let splits = try await calculator.calculateSplits(
    for: workout,
    configuration: .miles(1.0, excludePausedTime: true),
    healthStore: healthStore
)

for split in splits {
    print(split.description)
    // Split 1: 1609.34m in 480.0s

    // Access detailed properties
    print("Distance: \(split.distance.formattedDistance())")
    print("Duration: \(split.duration)s")
    print("Pace: \(split.pace.formattedPace(per: .miles))")
    print("Is Partial: \(split.isPartial)")
}
```

### Handling Errors

```swift
do {
    let splits = try await calculator.calculateSplits(
        for: workout,
        configuration: config,
        healthStore: healthStore
    )
    // Process splits...
} catch SplitCalculatorError.healthKitNotAvailable {
    // HealthKit not supported on device
    print("HealthKit is not available")
} catch SplitCalculatorError.noDistanceData {
    // Workout has no distance samples
    print("No distance data available for this workout")
} catch SplitCalculatorError.workoutTooShort {
    // Workout has zero distance
    print("Workout distance is too short")
} catch {
    print("Unexpected error: \(error)")
}
```

### Working with Different Workout Types

The package automatically selects the correct distance type:

```swift
// Running/Walking/Hiking → distanceWalkingRunning
let runSplits = try await calculator.calculateSplits(
    for: runningWorkout,
    configuration: .miles(1.0),
    healthStore: healthStore
)

// Cycling → distanceCycling
let cyclingSplits = try await calculator.calculateSplits(
    for: cyclingWorkout,
    configuration: .kilometers(5.0),
    healthStore: healthStore
)

// Swimming → distanceSwimming
let swimSplits = try await calculator.calculateSplits(
    for: swimmingWorkout,
    configuration: .meters(100),
    healthStore: healthStore
)
```

### Excluding Paused Time

```swift
// Include all time (default)
let config1 = SplitConfiguration.miles(1.0, excludePausedTime: false)

// Exclude paused time from split durations
let config2 = SplitConfiguration.miles(1.0, excludePausedTime: true)

let splits = try await calculator.calculateSplits(
    for: workout,
    configuration: config2,
    healthStore: healthStore
)
// Split durations now reflect only active time
```

### Using Convenience Extensions

```swift
// HKWorkout extensions
print(workout.activityName)              // "Running"
print(workout.hasPauses)                 // true/false
print(workout.totalPausedTime)           // 120.0 (seconds)
print(workout.activeDuration)            // Active time only
print(workout.formattedSummary)          // "Running: 5.25 mi in 42:30"

// Measurement extensions
let pace = split.pace
print(pace.minutesPerMile)               // 8.0
print(pace.minutesPerKilometer)          // 5.0
print(pace.formattedPace(per: .miles))   // "8:00 /mi"
```

## API Reference

### SplitCalculator

Main calculator class for determining splits.

```swift
public class SplitCalculator {
    public init()

    public static func requestAuthorization(from: HKHealthStore) async throws

    public func calculateSplits(
        for workout: HKWorkout,
        configuration: SplitConfiguration,
        healthStore: HKHealthStore
    ) async throws -> [WorkoutSplit]
}
```

### SplitConfiguration

Configuration for split calculations.

```swift
public struct SplitConfiguration {
    public let splitDistance: Measurement<UnitLength>
    public let excludePausedTime: Bool

    public static func miles(_ distance: Double, excludePausedTime: Bool = false) -> SplitConfiguration
    public static func kilometers(_ distance: Double, excludePausedTime: Bool = false) -> SplitConfiguration
}
```

### WorkoutSplit

Represents a single calculated split.

```swift
public struct WorkoutSplit {
    public let splitNumber: Int           // 1-indexed
    public let distance: Measurement<UnitLength>
    public let duration: TimeInterval     // seconds
    public let pace: Measurement<UnitSpeed>
    public let timestamp: Date            // approximate end time
    public let isPartial: Bool            // true if < target distance
}
```

### SplitCalculatorError

Errors that can occur during split calculation.

```swift
public enum SplitCalculatorError: Error {
    case healthKitNotAvailable
    case notAuthorized
    case noDistanceData
    case insufficientDistanceData
    case invalidConfiguration(String)
    case workoutTooShort
}
```

## Limitations and Considerations

### Approximation, Not GPS Accuracy

This package uses distance sample aggregation, not GPS routes. Split times are approximate and depend on:

- **Sample frequency**: More frequent samples = more accurate splits
- **Device capabilities**: Different devices record samples at different rates
- **Workout type**: Indoor workouts may have different sample patterns than outdoor

### Cannot Detect Permission Denial

HealthKit doesn't reveal whether the user denied read permissions. If permission is denied, queries return empty results, which appears as "no distance data." Always request authorization and handle the `noDistanceData` error gracefully.

### Post-Workout Only

This package is designed for analyzing completed workouts. It's not suitable for real-time split calculations during an active workout.

### Indoor vs Outdoor

The package works for both indoor and outdoor workouts **as long as distance samples exist**. However:

- Indoor treadmill workouts depend on the treadmill reporting accurate distance to the watch/phone
- Outdoor workouts generally have more frequent and accurate distance samples

## Troubleshooting

### "No distance data" error

**Possible causes:**
- The workout type doesn't record distance (e.g., strength training)
- Distance wasn't tracked during the workout
- HealthKit permissions not granted
- The device doesn't support distance tracking for this workout type

**Solutions:**
- Verify the workout has a `totalDistance` value
- Check that authorization was requested and granted
- Try a different workout with known distance data

### Splits seem inaccurate

**Possible causes:**
- Low sample frequency during workout
- Sparse distance data
- Indoor workout with estimated distance

**Solutions:**
- Use workouts with GPS enabled (outdoor workouts)
- Accept that splits are approximations
- Compare with other split calculators to understand typical variance

### Package won't compile

**Possible causes:**
- Missing HealthKit framework
- Incorrect platform version

**Solutions:**
- Ensure your deployment target is iOS 16+, watchOS 9+, or macOS 13+
- Add HealthKit capability to your app target
- Verify Swift tools version is 5.9+

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
