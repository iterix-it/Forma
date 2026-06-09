// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Forma",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Forma",
            targets: ["Forma"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Forma",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
