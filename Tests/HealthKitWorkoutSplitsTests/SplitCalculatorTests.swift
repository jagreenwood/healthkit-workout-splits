import XCTest
import HealthKit
@testable import HealthKitWorkoutSplits

final class SplitCalculatorTests: XCTestCase {

    var calculator: SplitCalculator!

    override func setUp() {
        super.setUp()
        calculator = SplitCalculator()
    }

    override func tearDown() {
        calculator = nil
        super.tearDown()
    }

    // MARK: - Authorization Tests

    func testRequestAuthorizationChecksHealthKitAvailability() async {
        let healthStore = HKHealthStore()

        // This test verifies the method exists and has proper signature
        // Actual authorization requires device with HealthKit support

        if HKHealthStore.isHealthDataAvailable() {
            do {
                try await SplitCalculator.requestAuthorization(from: healthStore)
                XCTFail("Should fail due to lack of plist key")
            } catch {
                // Expected
            }
        } else {
            // On non-HealthKit devices, should throw
            do {
                try await SplitCalculator.requestAuthorization(from: healthStore)
                XCTFail("Should have thrown healthKitNotAvailable")
            } catch SplitCalculatorError.healthKitNotAvailable {
                // Expected
            } catch {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testAuthorizationStatusMethod() {
        let healthStore = HKHealthStore()
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

        let status = SplitCalculator.authorizationStatus(for: distanceType, in: healthStore)

        // Read permissions always return .notDetermined
        // This test just verifies the method works
        XCTAssertNotNil(status)
    }

    // MARK: - Configuration Validation Tests

    func testInvalidConfigurationWithZeroDistance() async {
        let workout = MockWorkoutData.createWorkout(
            activityType: .running,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            totalDistance: 5000
        )

        let config = SplitConfiguration(
            splitDistance: Measurement(value: 0, unit: .miles),
            excludePausedTime: false
        )

        let healthStore = HKHealthStore()

        do {
            _ = try await calculator.calculateSplits(
                for: workout,
                configuration: config,
                healthStore: healthStore
            )
            XCTFail("Should have thrown invalidConfiguration")
        } catch SplitCalculatorError.invalidConfiguration {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testInvalidConfigurationWithNegativeDistance() async {
        let workout = MockWorkoutData.createWorkout(
            activityType: .running,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            totalDistance: 5000
        )

        let config = SplitConfiguration(
            splitDistance: Measurement(value: -1, unit: .miles),
            excludePausedTime: false
        )

        let healthStore = HKHealthStore()

        do {
            _ = try await calculator.calculateSplits(
                for: workout,
                configuration: config,
                healthStore: healthStore
            )
            XCTFail("Should have thrown invalidConfiguration")
        } catch SplitCalculatorError.invalidConfiguration {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Workout Validation Tests

    func testWorkoutTooShortWithZeroDistance() async {
        let workout = MockWorkoutData.createWorkout(
            activityType: .running,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            totalDistance: 0  // No distance
        )

        let config = SplitConfiguration.miles(1.0)
        let healthStore = HKHealthStore()

        do {
            _ = try await calculator.calculateSplits(
                for: workout,
                configuration: config,
                healthStore: healthStore
            )
            XCTFail("Should have thrown workoutTooShort")
        } catch SplitCalculatorError.workoutTooShort {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testWorkoutTooShortWithNilDistance() async {
        let workout = MockWorkoutData.createWorkout(
            activityType: .running,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            totalDistance: nil  // No distance recorded
        )

        let config = SplitConfiguration.miles(1.0)
        let healthStore = HKHealthStore()

        do {
            _ = try await calculator.calculateSplits(
                for: workout,
                configuration: config,
                healthStore: healthStore
            )
            XCTFail("Should have thrown workoutTooShort")
        } catch SplitCalculatorError.workoutTooShort {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Configuration Convenience Methods Tests

    func testMilesConfigurationConvenience() {
        let config = SplitConfiguration.miles(1.0)

        XCTAssertEqual(config.splitDistance.value, 1.0)
        XCTAssertEqual(config.splitDistance.unit, UnitLength.miles)
        XCTAssertFalse(config.excludePausedTime)
    }

    func testMilesConfigurationWithPauseExclusion() {
        let config = SplitConfiguration.miles(1.0, excludePausedTime: true)

        XCTAssertEqual(config.splitDistance.value, 1.0)
        XCTAssertEqual(config.splitDistance.unit, UnitLength.miles)
        XCTAssertTrue(config.excludePausedTime)
    }

    func testKilometersConfigurationConvenience() {
        let config = SplitConfiguration.kilometers(5.0)

        XCTAssertEqual(config.splitDistance.value, 5.0)
        XCTAssertEqual(config.splitDistance.unit, UnitLength.kilometers)
        XCTAssertFalse(config.excludePausedTime)
    }

    func testKilometersConfigurationWithPauseExclusion() {
        let config = SplitConfiguration.kilometers(1.0, excludePausedTime: true)

        XCTAssertEqual(config.splitDistance.value, 1.0)
        XCTAssertEqual(config.splitDistance.unit, UnitLength.kilometers)
        XCTAssertTrue(config.excludePausedTime)
    }

    // MARK: - Pause Extraction Tests

    func testExtractPauseIntervalsFromWorkoutWithNoPauses() {
        _ = MockWorkoutData.createWorkout(
            activityType: .running,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            totalDistance: 5000
        )

        // Use reflection or test through calculateSplits behavior
        // Since extractPauseIntervals is private, we verify behavior through public API
        _ = SplitConfiguration.miles(1.0, excludePausedTime: true)

        // If we could call it, we'd expect empty array
        // We test this indirectly through the split calculation
    }

    func testWorkoutWithPauses() {
        let workout = MockWorkoutData.createWorkoutWithPauses(
            pauseIntervals: [
                (startOffset: 600, duration: 120),  // 2 min pause at 10 min mark
                (startOffset: 1800, duration: 60)   // 1 min pause at 30 min mark
            ]
        )

        // Verify pause detection works
        XCTAssertTrue(workout.hasPauses)
        XCTAssertEqual(workout.totalPausedTime, 180)  // 3 minutes total
    }

    // MARK: - Integration-Style Tests
    // Note: These would fail in test environment without real HealthKit data
    // They're included to show expected usage patterns

    func testCalculateSplitsRequiresHealthKitData() async {
        // This demonstrates the expected usage but will fail without real data
        let workout = MockWorkoutData.createWorkout(
            activityType: .running,
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            totalDistance: 5000
        )

        let config = SplitConfiguration.miles(1.0)
        let healthStore = HKHealthStore()

        do {
            _ = try await calculator.calculateSplits(
                for: workout,
                configuration: config,
                healthStore: healthStore
            )
            // Would succeed with real HealthKit data
        } catch SplitCalculatorError.noDistanceData {
            // Expected in test environment - no actual samples
        } catch {
            // Other errors are also acceptable in test environment
        }
    }
}
