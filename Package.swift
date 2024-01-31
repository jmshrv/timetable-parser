// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TimetableParser",
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
