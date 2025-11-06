// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "healthkit-workout-splits",
    products: [
        .library(
            name: "HealthKitWorkoutSplits",
            targets: ["HealthKitWorkoutSplits"]
        ),
    ],
    targets: [
        .target(
            name: "HealthKitWorkoutSplits"
        ),
        .testTarget(
            name: "HealthKitWorkoutSplitsTests",
            dependencies: ["HealthKitWorkoutSplits"]
        ),
    ],
    swiftLanguageVersions: [.version("6"), .v5]
)
