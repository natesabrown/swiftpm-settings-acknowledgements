// swift-tools-version: 5.9

import PackageDescription

/// Defines the `Package` struct for this package.
///
/// This executable requires macOS 12.0 or over to run correctly due to a problem with `AsyncParsableCommand` in earlier versions.
/// See this article for why: [StackOverflow](https://forums.swift.org/t/asyncparsablecommand-doesnt-work/71300/2).
let package = Package(
  name: "swiftpm-settings-acknowledgements",
  platforms: [
    .macOS(.v12)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
  ],
  targets: [
    .executableTarget(
      name: "swiftpm-settings-acknowledgements",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      path: "Sources"),
    .testTarget(
      name: "Tests",
      dependencies: ["swiftpm-settings-acknowledgements"]),
  ]
)
