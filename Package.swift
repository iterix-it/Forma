// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NativeViewer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "NativeViewer",
            targets: ["NativeViewer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "NativeViewer"
        )
    ]
)
