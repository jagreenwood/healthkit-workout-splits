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
}
