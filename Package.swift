// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "spm-settings-acknowledgements",
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  ],
    targets: [
        .executableTarget(
            name: "make-settings-from-spm",
            dependencies: [
              .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources"),
    ]
)
