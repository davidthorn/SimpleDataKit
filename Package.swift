// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleDataKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SimpleStore",
            targets: ["SimpleStore"]
        ),
        .library(
            name: "SimpleStoreUI",
            targets: ["SimpleStoreUI"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SimpleStore"
        ),
        .target(
            name: "SimpleStoreUI",
            dependencies: ["SimpleStore"]
        ),
        .testTarget(
            name: "SimpleStoreTests",
            dependencies: ["SimpleStore"]
        ),
    ]
)
