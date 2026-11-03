// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "SlopMonsterMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SlopMonster",
            targets: ["SlopMonsterMac"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "SlopMonsterMac",
            path: "Sources/SlopMonsterMac",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "SlopMonsterMacTests",
            dependencies: ["SlopMonsterMac"],
            path: "Tests/SlopMonsterMacTests"
        ),
    ]
)
