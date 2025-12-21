// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "X04Checker",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "X04Checker",
            targets: ["X04Checker"]
        ),
    ],
    targets: [
        .target(
            name: "X04Checker",
            path: "Sources/X04Checker"
        ),
        .testTarget(
            name: "X04CheckerTests",
            dependencies: ["X04Checker"],
            path: "Tests/X04CheckerTests"
        ),
    ]
)
