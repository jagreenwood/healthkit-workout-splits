// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HealthKitWorkoutSplits",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HealthKitWorkoutSplits",
            targets: ["HealthKitWorkoutSplits"])
    ],
    targets: [
        .target(
            name: "HealthKitWorkoutSplits",
            dependencies: []),
        .testTarget(
            name: "HealthKitWorkoutSplitsTests",
            dependencies: ["HealthKitWorkoutSplits"])
    ]
)
