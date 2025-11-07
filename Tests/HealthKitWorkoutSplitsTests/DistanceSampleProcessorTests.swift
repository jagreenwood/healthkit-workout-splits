import XCTest
import HealthKit
@testable import HealthKitWorkoutSplits

final class DistanceSampleProcessorTests: XCTestCase {

    var processor: DistanceSampleProcessor!

    override func setUp() {
        super.setUp()
        processor = DistanceSampleProcessor()
    }

    override func tearDown() {
        processor = nil
        super.tearDown()
    }

    // MARK: - Distance Type Tests

    func testDistanceTypeForRunning() {
        let distanceType = processor.distanceQuantityType(for: .running)

        XCTAssertEqual(
            distanceType.identifier,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue
        )
    }

    func testDistanceTypeForWalking() {
        let distanceType = processor.distanceQuantityType(for: .walking)

        XCTAssertEqual(
            distanceType.identifier,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue
        )
    }

    func testDistanceTypeForHiking() {
        let distanceType = processor.distanceQuantityType(for: .hiking)

        XCTAssertEqual(
            distanceType.identifier,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue
        )
    }

    func testDistanceTypeForCycling() {
        let distanceType = processor.distanceQuantityType(for: .cycling)

        XCTAssertEqual(
            distanceType.identifier,
            HKQuantityTypeIdentifier.distanceCycling.rawValue
        )
    }

    func testDistanceTypeForSwimming() {
        let distanceType = processor.distanceQuantityType(for: .swimming)

        XCTAssertEqual(
            distanceType.identifier,
            HKQuantityTypeIdentifier.distanceSwimming.rawValue
        )
    }

    func testDistanceTypeForUnsupportedWorkout() {
        // Test with various unsupported types - should default to walking/running
        let types: [HKWorkoutActivityType] = [
            .yoga,
            .functionalStrengthTraining,
            .crossTraining,
            .rowing
        ]

        for type in types {
            let distanceType = processor.distanceQuantityType(for: type)

            XCTAssertEqual(
                distanceType.identifier,
                HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
                "Workout type \(type.rawValue) should default to walking/running distance"
            )
        }
    }

    // MARK: - Sample Fetching Tests
    // Note: We cannot easily test fetchDistanceSamples without a real HKHealthStore
    // or extensive mocking. These tests would be integration tests that require
    // a test device with HealthKit access.
    //
    // In a real-world scenario, you might:
    // 1. Create integration tests that run on device/simulator
    // 2. Use dependency injection to provide a mock health store
    // 3. Test the query construction logic separately

    func testSampleFetchingIsAsyncAwait() {
        // This test verifies the method signature supports async/await
        // Actual functionality would be tested in integration tests

        let expectation = XCTestExpectation(description: "Method is async")

        Task {
            let workout = MockWorkoutData.createWorkout(
                activityType: .running,
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                totalDistance: 5000
            )

            let healthStore = HKHealthStore()
            let distanceType = processor.distanceQuantityType(for: .running)

            // We can't actually execute this without proper HealthKit setup
            // but we can verify it compiles and has the right signature

            // This would throw or return empty in a test environment
            do {
                _ = try await processor.fetchDistanceSamples(
                    for: workout,
                    distanceType: distanceType,
                    from: healthStore
                )
            } catch {
                // Expected to fail in test environment
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
