import ArgumentParser
import Foundation

/// Entry point for the command line utility. Handles receiving arguments and passing them to the module logic.
///
/// * Reason for why the availability limited to macOS 12.0: [Link](https://forums.swift.org/t/asyncparsablecommand-doesnt-work/71300/2).
@main @available(macOS 12.0, *)
struct Entry: AsyncParsableCommand {

  @Option(
    name: [
      .customLong("package-cache-path"),
      .customShort("p"),
    ],
    help: "Package cache path")
  var packageCachePath: String

  @Option(
    name: [
      .customLong("output-path"),
      .customShort("o"),
    ],
    help: "Where the Settings.bundle should end up.")
  var outputPath: String? = nil

  func run() async throws {
    try await SPMSettingsAcknowledgements.run(
      fileManagerClient: .live,
      packageCachePath: packageCachePath,
      outputPath: outputPath
    )
  }
}
