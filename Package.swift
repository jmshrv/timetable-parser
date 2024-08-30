// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TimetableParser",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "TimetableParser", targets: ["TimetableParser"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "TimetableParser",
            dependencies: [
                "SwiftSoup"
            ],
            path: "Sources"),
    ]
)
