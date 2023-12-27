// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUIPlus",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftUIPlus",
            targets: ["SwiftUIPlus"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIPlus"
        ),
        .testTarget(
            name: "SwiftUIPlusTests",
            dependencies: ["SwiftUIPlus"]
        )
    ]
)
