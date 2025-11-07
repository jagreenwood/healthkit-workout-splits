# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**HealthKitWorkoutSplits** is a Swift Package that calculates distance-based splits for completed HealthKit workouts using distance sample aggregation (not GPS/location data). This approach works for both indoor and outdoor workouts.

### Key Design Principle

The package uses `HKQuantitySample` distance data instead of GPS routes. This means:
- Works with treadmill/indoor workouts where GPS isn't available
- Simpler implementation with fewer privacy concerns
- Trade-off: Split times are approximate and depend on sample frequency

## Build and Test Commands

### Building
```bash
swift build
```

### Running Tests
```bash
# Run all tests
swift test

# Run specific test
swift test --filter SplitAggregatorTests

# Run with verbose output
swift test --verbose
```

### Linting
This project uses SwiftLint. A `.swiftlint.yml` file exists at the root.

```bash
# Install SwiftLint (if not already installed)
brew install swiftlint

# Run linting
swiftlint

# Auto-fix issues where possible
swiftlint --fix
```

## Architecture

### Core Algorithm Flow

The split calculation process follows this pipeline:

```
HKWorkout → DistanceSampleProcessor → SplitAggregator → [WorkoutSplit]
```

1. **SplitCalculator** (orchestrator)
   - Validates configuration and workout
   - Requests distance samples via `DistanceSampleProcessor`
   - Extracts pause intervals from workout events
   - Delegates to `SplitAggregator` for calculation
   - Located: `Sources/HealthKitWorkoutSplits/SplitCalculator.swift`

2. **DistanceSampleProcessor** (data fetcher)
   - Maps workout type → distance type (running/cycling/swimming)
   - Queries HKHealthStore for distance samples during workout period
   - Uses async/await with `withCheckedThrowingContinuation`
   - Located: `Sources/HealthKitWorkoutSplits/Processing/DistanceSampleProcessor.swift`

3. **SplitAggregator** (core algorithm)
   - Processes samples sequentially, accumulating distance
   - Handles samples crossing split boundaries (proportional time distribution)
   - Creates partial split for remaining distance
   - Excludes paused time when configured
   - Located: `Sources/HealthKitWorkoutSplits/Processing/SplitAggregator.swift`

### Critical Algorithm Details

**Split Boundary Crossing Logic** (`SplitAggregator.calculateSplitsFromSamples`):

When a distance sample crosses a split boundary:
1. Calculate fraction of sample distance needed: `distanceToNextSplit / sampleDistanceMeters`
2. Distribute time proportionally: `sampleDuration * timeFraction`
3. Handle samples crossing multiple boundaries (loop until `remainingDistance = 0`)
4. Track cumulative distance and split start times for accurate calculations

**Pause Handling** (`SplitAggregator.calculateActiveTime`):

- Extracts pause/resume events from `HKWorkout.workoutEvents`
- Builds `DateInterval` array of pause periods
- For each split, calculates intersection of split time with pause intervals
- Subtracts paused time from split duration

**Workout Type Mapping** (`DistanceSampleProcessor.distanceQuantityType`):

- Running/Walking/Hiking → `.distanceWalkingRunning`
- Cycling → `.distanceCycling`
- Swimming → `.distanceSwimming`
- Default → `.distanceWalkingRunning`

### Module Organization

```
Sources/HealthKitWorkoutSplits/
├── SplitCalculator.swift          # Public API entry point
├── Models/                         # Value types
│   ├── WorkoutSplit.swift         # Split result (1-indexed, includes partial flag)
│   ├── SplitConfiguration.swift   # User config (distance, pause handling)
│   └── SplitCalculatorError.swift # Error types with LocalizedError
├── Processing/                     # Core logic
│   ├── DistanceSampleProcessor.swift  # HK queries + workout type mapping
│   └── SplitAggregator.swift          # Split calculation algorithm
└── Extensions/                     # Convenience utilities
    ├── HKWorkout+Extensions.swift     # activityName, hasPauses, activeDuration
    └── Measurement+Extensions.swift   # Pace formatting (min/mile, min/km)
```

## Important Constraints and Edge Cases

### UnitLength → HKUnit Conversion

Foundation's `UnitLength` and HealthKit's `HKUnit` are separate type systems. When converting between them:

```swift
// INCORRECT: unit.symbol doesn't map to HKUnit
let hkUnit = HKUnit(from: measurement.unit.symbol)

// CORRECT: Explicit mapping via switch statement
switch measurement.unit {
case .meters: return HKUnit.meter()
case .kilometers: return HKUnit.meterUnit(with: .kilo)
case .miles: return HKUnit.mile()
// etc...
}
```

See `Measurement+Extensions.swift` for the complete mapping.

### HealthKit Authorization Behavior

- **Read permission status cannot be determined** - HealthKit privacy prevents checking if user denied read access
- If denied, queries return empty results (appears as "no distance data")
- `authorizationStatus()` only works for write permissions
- Always handle `noDistanceData` error gracefully

### Minimum Distance Threshold

The algorithm uses a 0.1 meter threshold to avoid creating meaningless partial splits:

```swift
if remainingDistance > 0.1 { // Only create split if meaningful
    // Create partial split...
}
```

## Testing Strategy

### Test Data Approach

Tests use `MockWorkoutData.swift` to create synthetic `HKQuantitySample` arrays:

```swift
// Create 5km workout with samples every 100m
let samples = MockWorkoutData.createDistanceSamples(
    totalDistance: 5000,  // meters
    sampleCount: 50,
    startDate: Date()
)
```

### Key Test Scenarios

1. **Boundary crossing** - Sample spans multiple split boundaries
2. **Pause handling** - Verify paused time excluded correctly
3. **Partial splits** - Final split with distance < target
4. **Edge cases** - Empty samples, zero distance, single sample

### Running Specific Test Cases

```bash
# Test split aggregation logic
swift test --filter SplitAggregatorTests

# Test workout type mapping
swift test --filter DistanceSampleProcessorTests

# Test error handling
swift test --filter SplitCalculatorTests.testWorkoutTooShort
```

## Platform Requirements

- **iOS 16.0+** / **watchOS 9.0+** / **macOS 13.0+** (for modern async/await with HealthKit)
- **Swift 5.9+** (declared in Package.swift swift-tools-version)
- **HealthKit framework** (Apple system framework, no external dependencies)

## Documentation

The package uses DocC-style comments throughout. Key documentation locations:

- **README.md** - User-facing documentation with quick start and examples
- **Inline comments** - API documentation for all public types
- `.claude-tracking/` - Implementation planning and review documents (not shipped with package)

## Common Gotchas

1. **Force unwraps in distance type mapping** - Safe because HealthKit quantity types are guaranteed to exist, but code review flagged for improvement
2. **Empty test file** - `HealthKitWorkoutSplitsTests.swift` exists but is empty; should be removed
3. **README placeholder** - GitHub URL contains "yourusername" - update before publishing
4. **Real HealthKit testing** - Cannot unit test actual HealthKit queries; requires manual testing with real workouts
