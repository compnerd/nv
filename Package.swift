// swift-tools-version: 6.2

import PackageDescription

let _ =
    Package(name: "nv",
            platforms: [
              .macOS(.v15),
            ],
            products: [
              .executable(name: "nv", targets: ["nv"]),
            ],
            traits: [
              .trait(name: "GNU", description: "GNU C Library")
            ],
            dependencies: [
              .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.0"),
              .package(url: "https://github.com/compnerd/swift-platform-core.git", branch: "main",
                       traits: [.trait(name: "GNU", condition: .when(traits: ["GNU"]))]),
            ],
            targets: [
              .executableTarget(name: "nv", dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "WindowsCore", package: "swift-platform-core",
                         condition: .when(platforms: [.windows])),
                .product(name: "POSIXCore", package: "swift-platform-core",
                         condition: .when(platforms: [.linux, .macOS])),
              ]),
            ])
