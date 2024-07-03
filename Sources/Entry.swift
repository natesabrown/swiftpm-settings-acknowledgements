import ArgumentParser
import Foundation

/// Entry point for the command line utility. Handles receiving arguments and passing them to the module logic.
@main
struct Entry: AsyncParsableCommand {

  @Option(
    name: Argument.directoryPath.nameSpecification,
    help: Argument.directoryPath.helpText,
    completion: .directory)
  var directoryPath: String?

  @Option(
    name: Argument.gitHubToken.nameSpecification,
    help: Argument.gitHubToken.helpText)
  var gitHubToken: String?

  @Option(
    name: Argument.languages.nameSpecification,
    help: Argument.languages.helpText)
  var languages: String = "en"

  @Option(
    name: Argument.outputPath.nameSpecification,
    help: Argument.outputPath.helpText,
    completion: .directory)
  var outputPath: String?

  @Option(
    name: Argument.packageCachePath.nameSpecification,
    help: Argument.packageCachePath.helpText,
    completion: .directory)
  var packageCachePath: String?

  @Option(
    name: Argument.packageResolvedPath.nameSpecification,
    help: Argument.packageResolvedPath.helpText,
    completion: .file(extensions: [".resolved"]))
  var packageResolvedPath: String?

  @Flag(
    name: Argument.verbose.nameSpecification,
    help: Argument.verbose.helpText)
  var verbose: Bool = false

  func run() async throws {

    print(Argument.fullMarkdownDocumentation)

    //    let logger: CustomLogger = .live(verbose: verbose)
    //
    //    let environment: Environment = .init(
    //      fileManagerClient: .live,
    //      gitHubClient: .live(token: gitHubToken),
    //      logger: logger
    //    )
    //
    //    let args: CommandLineArguments = .init(
    //      directoryPath: directoryPath,
    //      languages: languages,
    //      outputPath: outputPath,
    //      packageCachePath: packageCachePath,
    //      packageResolvedPath: packageResolvedPath
    //    )
    //
    //    try await SPMSettingsAcknowledgements.run(
    //      args: args,
    //      environment: environment
    //    )
  }
}
