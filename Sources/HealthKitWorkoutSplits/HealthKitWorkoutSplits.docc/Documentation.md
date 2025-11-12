# ``HealthKitWorkoutSplits``

A Swift Package for calculating distance-based splits from completed HealthKit workouts using distance sample aggregation.

## Overview

HealthKitWorkoutSplits analyzes completed workouts and calculates approximate distance splits using `HKQuantitySample` distance data. This approach works for both indoor and outdoor workouts, making it compatible with treadmill runs, outdoor runs, cycling, swimming, and other distance-based activities.

### Key Features

- **Flexible Distance Units**: Calculate splits for miles, kilometers, or any custom distance
- **Pause Time Handling**: Optionally exclude paused time from split calculations
- **Multiple Activity Types**: Supports running, cycling, swimming, hiking, and more
- **Modern API**: Built with Swift async/await for clean, concurrent code
- **Indoor Compatible**: Works with treadmill and indoor workouts that don't have GPS data
- **Comprehensive Error Handling**: Clear error messages with recovery suggestions

### How It Works

Instead of relying on GPS or location data, this package aggregates distance samples recorded by HealthKit during workouts. This provides several advantages:

- Works with indoor workouts (treadmill, indoor cycling)
- Compatible with any device that records distance samples
- Simpler implementation with fewer privacy concerns
- No need for location permissions

Note that accuracy depends on the frequency of distance samples recorded during the workout. This package provides approximate splits rather than GPS-accurate timing.

### Quick Start

```swift
import HealthKit
import HealthKitWorkoutSplits

// 1. Request authorization
let healthStore = HKHealthStore()
try await SplitCalculator.requestAuthorization(from: healthStore)

// 2. Create a calculator
let calculator = SplitCalculator()

// 3. Configure split calculation
let config = SplitConfiguration.miles(1.0, excludePausedTime: true)

// 4. Calculate splits
let splits = try await calculator.calculateSplits(
    for: workout,
    configuration: config,
    healthStore: healthStore
)

// 5. Use the results
for split in splits {
    print("Split \(split.splitNumber): \(split.duration)s at \(split.minutesPerMile) min/mi")
}
```

## Topics

### Essentials

- ``SplitCalculator``
- ``WorkoutSplit``
- ``SplitConfiguration``

### Configuration

- ``SplitConfiguration/init(splitDistance:excludePausedTime:)``
- ``SplitConfiguration/miles(_:excludePausedTime:)``
- ``SplitConfiguration/kilometers(_:excludePausedTime:)``
- ``SplitConfiguration/splitDistance``
- ``SplitConfiguration/excludePausedTime``

### Split Calculation

- ``SplitCalculator/calculateSplits(for:configuration:healthStore:)``
- ``SplitCalculator/requestAuthorization(from:)``
- ``SplitCalculator/authorizationStatus(for:in:)``

### Split Information

- ``WorkoutSplit/splitNumber``
- ``WorkoutSplit/distance``
- ``WorkoutSplit/duration``
- ``WorkoutSplit/pace``
- ``WorkoutSplit/timestamp``
- ``WorkoutSplit/isPartial``
- ``WorkoutSplit/minutesPerMile``
- ``WorkoutSplit/minutesPerKilometer``

### Error Handling

- ``SplitCalculatorError``
- ``SplitCalculatorError/healthKitNotAvailable``
- ``SplitCalculatorError/notAuthorized``
- ``SplitCalculatorError/noDistanceData``
- ``SplitCalculatorError/insufficientDistanceData``
- ``SplitCalculatorError/invalidConfiguration(_:)``
- ``SplitCalculatorError/workoutTooShort``
