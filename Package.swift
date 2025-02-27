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
    dependencies: [
        .package(
            url: "https://github.com/KOMA-Inc/SwiftUI-LazyPager",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "SwiftUIPlus",
            dependencies: [
                .product(name: "LazyPager", package: "SwiftUI-LazyPager")
            ]
        ),
        .testTarget(
            name: "SwiftUIPlusTests",
            dependencies: ["SwiftUIPlus"]
        )
    ]
)
