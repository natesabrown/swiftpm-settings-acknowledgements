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
    help: "Package cache path"
  )
  var packageCachePath: String

  @Option(
    name: [
      .customLong("output-path"),
      .customShort("o"),
    ],
    help: "Where the Settings.bundle should end up.",
    transform: { (input: String?) -> OutputPath in
      if let input { .specified(input) } else { .unspecified }
    }
  )
  var outputPath: OutputPath

  func run() async throws {
    try await SPMSettingsAcknowledgements.run(
      fileManagerClient: .live,
      packageCachePath: packageCachePath,
      outputPath: outputPath
    )
  }
}

/// Where the user wants to get the information for swift packages.
enum PackageInfoSource {
  /// Use the SPM cache, specified by a path to the cache.
  case cache(path: String)
  /// Try to pull information from GitHub.
  case github
}

/// Where the user wants the new `Settings.bundle` to be created.
enum OutputPath {
  case specified(String)
  case unspecified
}
