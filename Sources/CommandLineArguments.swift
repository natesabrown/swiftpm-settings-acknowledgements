import ArgumentParser
import Foundation

/// A convenience struct for the command line arguments we will gather from the user to run the executable.
struct CommandLineArguments {
  /// A path to the directory containing the user's .xcodeproj they want to use this command line tool for.
  /// We will use this to find the `Package.resolved` to gather the packages used.
  let directoryPath: String?
  /// A comma-separated list of language codes to provide the translations for.
  let languages: String
  /// The location the settings bundle should be created at.
  let outputPath: String?
  /// A path to the user's SPM cache. This will allow us to extract license information without making network requests to GitHub,
  /// and is more versatile for working with SPM packages not hosted on GitHub.
  let packageCachePath: String?
  /// A path to the `Package.resolved` that enumerates the packages used for a project. We can use this to bypass the need to find
  /// the `Package.resolved` based on the `directoryPath`.
  let packageResolvedPath: String?
}

enum Argument: CaseIterable {

  case directoryPath
  case gitHubToken
  case languages
  case outputPath
  case packageCachePath
  case packageResolvedPath
  case verbose

  var argNames: NameSpecification {
    switch self {
    case .directoryPath:
      [.customLong("directory-path"), .customShort("d")]
    case .gitHubToken:
      .customLong("github-token")
    case .languages:
      [.customLong("languages"), .customShort("l")]
    case .outputPath:
      [.customLong("output-path"), .customShort("o")]
    case .packageCachePath:
      .customLong("package-cache-path")
    case .packageResolvedPath:
      .customLong("package-resolved-path")
    case .verbose:
      [.customShort("v"), .customLong("verbose")]
    }
  }

  var helpText: ArgumentHelp {
    switch self {
    case .directoryPath:
      "Path to the directory containing the .xcodeproj"
    case .gitHubToken:
      "Add a GitHub token to help prevent rate limiting when fetching license information from GitHub."
    case .languages:
      "Specify the languages to localize the \"Acknowledgements\" text for. If multiple, separate by commas (e.g. \"en,es,ja\")."
    case .outputPath:
      "Where the Settings.bundle should end up."
    case .packageCachePath:
      "Provide a custom path to your Package.resolved file."
    case .packageResolvedPath:
      "Provide a custom path to your Package.resolved file."
    case .verbose:
      "Print extra details."
    }
  }

  /// Need a better way to connect this to `Entry.swift`.
  var defaultValue: Any? {
    switch self {
    case .directoryPath: nil
    case .gitHubToken: nil
    case .languages: "en"
    case .outputPath: nil
    case .packageCachePath: nil
    case .packageResolvedPath: nil
    case .verbose: false
    }
  }
}
