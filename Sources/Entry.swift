import ArgumentParser
import Foundation

/// Entry point for the command line utility. Handles receiving arguments and passing them to the module logic.
@main
struct Entry: AsyncParsableCommand {

  @Option(
    name: [
      .customLong("directory-path"),
      .customShort("d"),
    ],
    help: "Path to the directory containing the .xcodeproj",
    completion: .directory)
  var directoryPath: String?

  @Option(
    name: [.customLong("github-token")],
    help:
      "Add a GitHub token to help prevent rate limiting when fetching license information from GitHub."
  )
  var gitHubToken: String?

  @Option(
    name: [
      .customLong("languages"),
      .customShort("l"),
    ],
    help:
      "Specify the languages to localize the \"Acknowledgements\" text for. If multiple, separate by commas (e.g. \"en,es,ja\")."
  )
  var languages: String = "en"

  @Option(
    name: [
      .customLong("output-path"),
      .customShort("o"),
    ],
    help: "Where the Settings.bundle should end up.",
    completion: .directory)
  var outputPath: String?

  @Option(
    name: [
      .customLong("package-cache-path")
    ],
    help: "Package cache path",
    completion: .directory)
  var packageCachePath: String?

  @Option(
    name: [.customLong("package-resolved-path")],
    help: "Provide a custom path to your Package.resolved file.",
    completion: .file(extensions: [".resolved"])
  )
  var packageResolvedPath: String?

  @Flag(
    name: [.customShort("v"), .customLong("verbose")],
    help: "Print extra details."
  )
  var verbose: Bool = false

  func run() async throws {

    let logger: CustomLogger = .live(verbose: verbose)

    let environment: Environment = .init(
      fileManagerClient: .live,
      gitHubClient: .live(token: gitHubToken),
      logger: logger
    )

    let args: CommandLineArguments = .init(
      directoryPath: directoryPath,
      languages: languages,
      outputPath: outputPath,
      packageCachePath: packageCachePath,
      packageResolvedPath: packageResolvedPath
    )

    try await SPMSettingsAcknowledgements.run(
      args: args,
      environment: environment
    )
  }
}
