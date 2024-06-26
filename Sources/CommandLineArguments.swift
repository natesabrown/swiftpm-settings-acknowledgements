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
