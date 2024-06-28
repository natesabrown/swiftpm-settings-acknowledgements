import ArgumentParser
import Foundation

/// Entry point for the command line utility. Handles receiving arguments and passing them to the module logic.
@main
struct Entry: AsyncParsableCommand {

  @Option(
    name: Argument.directoryPath.argNames,
    help: Argument.directoryPath.helpText,
    completion: .directory)
  var directoryPath: String?

  @Option(
    name: Argument.gitHubToken.argNames,
    help: Argument.gitHubToken.helpText)
  var gitHubToken: String?

  @Option(
    name: Argument.languages.argNames,
    help: Argument.languages.helpText)
  var languages: String = "en"

  @Option(
    name: Argument.outputPath.argNames,
    help: Argument.outputPath.helpText,
    completion: .directory)
  var outputPath: String?

  @Option(
    name: Argument.packageCachePath.argNames,
    help: Argument.packageCachePath.helpText,
    completion: .directory)
  var packageCachePath: String?

  @Option(
    name: Argument.packageResolvedPath.argNames,
    help: Argument.packageResolvedPath.helpText,
    completion: .file(extensions: [".resolved"]))
  var packageResolvedPath: String?

  @Flag(
    name: Argument.verbose.argNames,
    help: Argument.verbose.helpText)
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
