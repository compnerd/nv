// swift-tools-version: 6.2

import PackageDescription

let _ =
    Package(name: "nv",
            platforms: [
              .macOS(.v26),
            ],
            products: [
              .executable(name: "nv", targets: ["nv"]),
            ],
            traits: [
              .trait(name: "GNU", description: "GNU C Library")
            ],
            dependencies: [
              .package(url: "https://github.com/apple/swift-argument-parser",
                       from: "1.6.0"),
              .package(url: "https://github.com/compnerd/swift-platform-core", branch: "main",
                       traits: [.trait(name: "GNU", condition: .when(traits: ["GNU"]))]),
              .package(url: "https://github.com/AlwaysRightInstitute/Mustache",
                       from: "1.0.4"),
              .package(url: "https://github.com/apple/swift-collections",
                       from: "1.3.0"),
            ],
            targets: [
              .executableTarget(name: "nv", dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "WindowsCore", package: "swift-platform-core",
                         condition: .when(platforms: [.windows])),
                .product(name: "POSIXCore", package: "swift-platform-core",
                         condition: .when(platforms: [.linux, .macOS])),
                .product(name: "Mustache", package: "Mustache"),
                .product(name: "HeapModule", package: "swift-collections"),
              ], resources: [
                .process("Resources"),
              ]),
            ])
