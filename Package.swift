// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FitDadNudge",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "FitDadNudge",
            targets: ["FitDadNudge"]),
    ],
    dependencies: [
        // Dependencies will be added as needed
    ],
    targets: [
        .target(
            name: "FitDadNudge",
            dependencies: []),
        .testTarget(
            name: "FitDadNudgeTests",
            dependencies: ["FitDadNudge"]),
    ]
) 