import ArgumentParser
import Foundation

/// Entry point for the command line utility. Handles receiving arguments and passing them to the module logic.
@main
struct Entry: ParsableCommand {

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

  func run() throws {
    try SPMSettingsAcknowledgements.run(
      fileManager: .default,
      packageCachePath: packageCachePath,
      outputPath: outputPath
    )
  }
}
