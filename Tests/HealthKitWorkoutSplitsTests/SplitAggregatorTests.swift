import XCTest
import HealthKit
@testable import HealthKitWorkoutSplits

final class SplitAggregatorTests: XCTestCase {

    var aggregator: SplitAggregator!

    override func setUp() {
        super.setUp()
        aggregator = SplitAggregator()
    }

    override func tearDown() {
        aggregator = nil
        super.tearDown()
    }

    // MARK: - Basic Split Calculation Tests

    func testCalculateSplitsFromEvenSamples() {
        // Create samples for a 3-mile run at steady pace
        // 10 samples, each 482.8 meters (total ~3 miles), 4 minutes each
        let startDate = MockWorkoutData.date(hour: 10, minute: 0, second: 0)
        let samples = MockWorkoutData.createEvenSamples(
            count: 10,
            distancePerSample: 482.8,
            secondsPerSample: 240,
            startDate: startDate
        )

        let splitDistance = Measurement(value: 1.0, unit: UnitLength.miles)
        let splits = aggregator.calculateSplitsFromSamples(
            samples: samples,
            splitDistance: splitDistance,
            pauseIntervals: []
        )

        // Should get 3 complete mile splits
        XCTAssertEqual(splits.count, 3)

        // Each split should be approximately 1 mile
        for split in splits where !split.isPartial {
            XCTAssertEqual(split.distance.value, 1.0, accuracy: 0.01)
            XCTAssertEqual(split.distance.unit, UnitLength.miles)
        }

        // Split numbers should be sequential
        for (index, split) in splits.enumerated() {
            XCTAssertEqual(split.splitNumber, index + 1)
        }
    }

    func testCalculateSplitsWithPartialFinalSplit() {
        // Create samples for 2.5 miles
        let startDate = MockWorkoutData.date(hour: 10, minute: 0, second: 0)
        let samples = MockWorkoutData.createEvenSamples(
            count: 5,
            distancePerSample: 804.67,  // ~0.5 miles each
            secondsPerSample: 240,
            startDate: startDate
        )

        let splitDistance = Measurement(value: 1.0, unit: UnitLength.miles)
        let splits = aggregator.calculateSplitsFromSamples(
            samples: samples,
            splitDistance: splitDistance,
            pauseIntervals: []
        )

        // Should get 2 complete splits + 1 partial
        XCTAssertEqual(splits.count, 3)

        // First two should be complete
        XCTAssertFalse(splits[0].isPartial)
        XCTAssertFalse(splits[1].isPartial)

        // Last should be partial
        XCTAssertTrue(splits[2].isPartial)

        // Partial split should be approximately 0.5 miles
        let partialDistance = splits[2].distance.converted(to: .miles).value
        XCTAssertEqual(partialDistance, 0.5, accuracy: 0.01)
    }

    func testCalculateSplitsWithSampleCrossingBoundary() {
        // Create a sample that crosses a split boundary
        let startDate = MockWorkoutData.date(hour: 10, minute: 0, second: 0)

        // First sample: 1500m in 8 minutes (doesn't complete 1 mile)
        let sample1 = MockWorkoutData.createDistanceSample(
            distance: 1500,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(480)
        )

        // Second sample: 500m in 2.5 minutes (crosses 1 mile boundary at ~109m)
        let sample2 = MockWorkoutData.createDistanceSample(
            distance: 500,
            startDate: sample1.endDate,
            endDate: sample1.endDate.addingTimeInterval(150)
        )

        let splitDistance = Measurement(value: 1.0, unit: UnitLength.miles)
        let splits = aggregator.calculateSplitsFromSamples(
            samples: [sample1, sample2],
            splitDistance: splitDistance,
            pauseIntervals: []
        )

        // Should get 1 complete split + 1 partial
        XCTAssertEqual(splits.count, 2)
        XCTAssertFalse(splits[0].isPartial)
        XCTAssertTrue(splits[1].isPartial)

        // First split should be 1 mile
        XCTAssertEqual(splits[0].distance.value, 1.0, accuracy: 0.01)
        XCTAssertEqual(splits[0].distance.unit, UnitLength.miles)
    }

    func testCalculateSplitsWithSampleContainingMultipleSplits() {
        // Create a very sparse sample that spans multiple splits
        let startDate = MockWorkoutData.date(hour: 10, minute: 0, second: 0)

        // Single sample: 5000m in 25 minutes (spans 3+ mile splits)
        let sample = MockWorkoutData.createDistanceSample(
            distance: 5000,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(1500)
        )

        let splitDistance = Measurement(value: 1.0, unit: UnitLength.miles)
        let splits = aggregator.calculateSplitsFromSamples(
            samples: [sample],
            splitDistance: splitDistance,
            pauseIntervals: []
        )

        // Should get 3 complete splits + 1 partial
        // (5000m = ~3.1 miles)
        XCTAssertEqual(splits.count, 4)
        XCTAssertFalse(splits[0].isPartial)
        XCTAssertFalse(splits[1].isPartial)
        XCTAssertFalse(splits[2].isPartial)
        XCTAssertTrue(splits[3].isPartial)
    }

    func testVeryShortWorkout() {
        // Workout shorter than split distance
        let startDate = MockWorkoutData.date(hour: 10, minute: 0, second: 0)
        let samples = MockWorkoutData.createEvenSamples(
            count: 2,
            distancePerSample: 200,  // Only 400m total
            secondsPerSample: 60,
            startDate: startDate
        )

        let splitDistance = Measurement(value: 1.0, unit: UnitLength.miles)
        let splits = aggregator.calculateSplitsFromSamples(
            samples: samples,
            splitDistance: splitDistance,
            pauseIntervals: []
        )

        // Should get 1 partial split
        XCTAssertEqual(splits.count, 1)
        XCTAssertTrue(splits[0].isPartial)

        let distance = splits[0].distance.converted(to: .meters).value
        XCTAssertEqual(distance, 400, accuracy: 0.1)
    }

    // MARK: - Pause Handling Tests

    func testExcludePausedTime() {
        let startDate = MockWorkoutData.date(hour: 10, minute: 0, second: 0)

        // Create samples for 1 mile
        let samples = MockWorkoutData.createEvenSamples(
            count: 4,
            distancePerSample: 402.34,  // ~0.25 miles each
            secondsPerSample: 120,
            startDate: startDate
        )

        // Pause from 3:00 to 5:00 (2 minutes in middle of workout)
        let pauseStart = startDate.addingTimeInterval(180)
        let pauseEnd = startDate.addingTimeInterval(300)
        let pauseInterval = DateInterval(start: pauseStart, end: pauseEnd)

        let splitDistance = Measurement(value: 1.0, unit: UnitLength.miles)
        let splits = aggregator.calculateSplitsFromSamples(
            samples: samples,
            splitDistance: splitDistance,
            pauseIntervals: [pauseInterval]
        )

        // Should have 1 complete split
        XCTAssertEqual(splits.count, 1)

        // Duration should be less than total elapsed time
        let totalElapsed = samples.last!.endDate.timeIntervalSince(samples.first!.startDate)
        XCTAssertLessThan(splits[0].duration, totalElapsed)
    }

    func testMultiplePauses() {
        let startDate = MockWorkoutData.date(hour: 10, minute: 0, second: 0)

        let samples = MockWorkoutData.createEvenSamples(
            count: 8,
            distancePerSample: 201.17,  // ~0.125 miles
            secondsPerSample: 60,
            startDate: startDate
        )

        // Two pauses
        let pause1 = DateInterval(
            start: startDate.addingTimeInterval(90),
            end: startDate.addingTimeInterval(120)
        )
        let pause2 = DateInterval(
            start: startDate.addingTimeInterval(270),
            end: startDate.addingTimeInterval(300)
        )

        let splitDistance = Measurement(value: 1.0, unit: UnitLength.miles)
        let splits = aggregator.calculateSplitsFromSamples(
            samples: samples,
            splitDistance: splitDistance,
            pauseIntervals: [pause1, pause2]
        )

        XCTAssertEqual(splits.count, 1)
    }

    // MARK: - Pace Calculation Tests

    func testCalculatePace() {
        // 1000 meters in 300 seconds = 3.33 m/s
        let pace = aggregator.calculatePace(distance: 1000, time: 300)

        XCTAssertEqual(pace.value, 3.33, accuracy: 0.01)
        XCTAssertEqual(pace.unit, UnitSpeed.metersPerSecond)
    }

    func testCalculatePaceWithZeroTime() {
        let pace = aggregator.calculatePace(distance: 1000, time: 0)

        XCTAssertEqual(pace.value, 0)
    }

    // MARK: - Active Time Calculation Tests

    func testCalculateActiveTimeWithoutPauses() {
        let start = MockWorkoutData.date(hour: 10, minute: 0, second: 0)
        let end = start.addingTimeInterval(600)  // 10 minutes

        let activeTime = aggregator.calculateActiveTime(
            from: start,
            to: end,
            excluding: []
        )

        XCTAssertEqual(activeTime, 600)
    }

    func testCalculateActiveTimeWithPause() {
        let start = MockWorkoutData.date(hour: 10, minute: 0, second: 0)
        let end = start.addingTimeInterval(600)  // 10 minutes total

        // 2 minute pause in the middle
        let pauseInterval = DateInterval(
            start: start.addingTimeInterval(240),
            end: start.addingTimeInterval(360)
        )

        let activeTime = aggregator.calculateActiveTime(
            from: start,
            to: end,
            excluding: [pauseInterval]
        )

        XCTAssertEqual(activeTime, 480)  // 10 minutes - 2 minutes = 8 minutes
    }

    func testCalculateActiveTimeWithOverlappingPause() {
        let start = MockWorkoutData.date(hour: 10, minute: 0, second: 0)
        let end = start.addingTimeInterval(300)  // 5 minutes

        // Pause that extends beyond the segment end
        let pauseInterval = DateInterval(
            start: start.addingTimeInterval(240),
            end: start.addingTimeInterval(420)  // Extends beyond end
        )

        let activeTime = aggregator.calculateActiveTime(
            from: start,
            to: end,
            excluding: [pauseInterval]
        )

        // Should only subtract the 1 minute overlap (240-300)
        XCTAssertEqual(activeTime, 240)
    }

    func testCalculateActiveTimeWithPauseBeforeSegment() {
        let start = MockWorkoutData.date(hour: 10, minute: 0, second: 0)
        let end = start.addingTimeInterval(300)

        // Pause that ends before segment starts
        let pauseInterval = DateInterval(
            start: start.addingTimeInterval(-120),
            end: start.addingTimeInterval(-60)
        )

        let activeTime = aggregator.calculateActiveTime(
            from: start,
            to: end,
            excluding: [pauseInterval]
        )

        // No overlap, should be full duration
        XCTAssertEqual(activeTime, 300)
    }
}
