// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BlackPoint",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BlackPoint", targets: ["BlackPoint"])
    ],
    targets: [
        .target(
            name: "BlackPointCore",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "BlackPoint",
            dependencies: ["BlackPointCore"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
