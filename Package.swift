// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RuntimePilot",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "RuntimePilot", targets: ["RuntimePilot"]),
        .library(name: "RuntimePilotCore", targets: ["RuntimePilotCore"]),
    ],
    targets: [
        .target(
            name: "RuntimePilotCore",
            path: "Sources/RuntimePilotCore"
        ),
        .executableTarget(
            name: "RuntimePilot",
            dependencies: ["RuntimePilotCore"],
            path: "Sources/RuntimePilot",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "RuntimePilotChecks",
            dependencies: ["RuntimePilotCore"],
            path: "Tests/RuntimePilotChecks"
        ),
    ]
)
