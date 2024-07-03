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

  enum ArgName {
    case long(String)
    case short(Character)

    var text: String {
      switch self {
      case .long(let name): "--\(name)"
      case .short(let name): "-\(name)"
      }
    }
  }

  var argNames: [ArgName] {
    switch self {
    case .directoryPath:
      [.long("directory-path"), .short("d")]
    case .gitHubToken:
      [.long("github-token")]
    case .languages:
      [.long("languages"), .short("l")]
    case .outputPath:
      [.long("output-path"), .short("o")]
    case .packageCachePath:
      [.long("package-cache-path")]
    case .packageResolvedPath:
      [.long("package-resolved-path")]
    case .verbose:
      [.long("verbose"), .short("v")]
    }
  }

  var nameSpecification: NameSpecification {
    .init(
      self.argNames.map {
        switch $0 {
        case .long(let name): .customLong(name)
        case .short(let name): .customShort(name)
        }
      }
    )
  }

  var helpText: ArgumentHelp {
    switch self {
    case .directoryPath:
      .init(
        "Path to the directory containing the `.xcodeproj`.",
        discussion:
          "If not provided, this program will look for the first `.xcodeproj` in the directory. "
      )
    case .gitHubToken:
      .init(
        "Add a GitHub token to help prevent rate limiting when fetching license information from GitHub.",
        discussion:
          "If no `--package-cache-path` is specified, this package will look to GitHub to get license information. To guard against rate limits from their API, you can provide an access token. For guidance, see [generating a personal access token (GitHub)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)."
      )
    case .languages:
      .init(
        "Specify the languages to localize the \"Acknowledgements\" text for. If multiple, separate by commas (e.g. \"en,es,ja\").",
        discussion:
          "Available languages:\n\(AcknowledgementsTranslation.availableLanguagesDescription)"
      )
    case .outputPath:
      .init(
        "Where the `Settings.bundle` should end up.",
        discussion: "If not provided, the bundle will be created in the current directory."
      )
    case .packageCachePath:
      .init(
        "Provide a custom path to your `Package.resolved` file.",
        discussion:
          "If provided, this program will look through the package directory for licenses instead of contacting the GitHub API.\n\nTo find the package cache for your project, option-click on a package listed in \"Package Dependencies\" in Xcode and select \"Show in Finder\"."
      )
    case .packageResolvedPath:
      .init(
        "Provide a custom path to your `Package.resolved` file.",
        discussion:
          "If not provided, this program will look for the file within your directory's `.xcworkspace`."
      )
    case .verbose:
      "Print extra details during program execution."
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

  /// Need a better way to connect this to `Entry.swift`.
  enum ArgType {
    case option
    case flag

    var description: String {
      switch self {
      case .option: "Option"
      case .flag: "Flag"
      }
    }
  }

  var argType: ArgType {
    self == .verbose ? .flag : .option
  }

  var defaultValueDescription: String {
    switch argType {
    case .flag: defaultValue as? Bool == true ? "enabled" : "disabled"
    case .option: "`\(defaultValue.simpleTextDescription)`"
    }
  }

  var detailedHelpText: String {
    var text = helpText.abstract
    if !helpText.discussion.isEmpty {
      text += "\n\n\(helpText.discussion)"
    }
    return text
  }
}

extension Optional where Wrapped == Any {

  fileprivate var simpleTextDescription: String {
    guard let unwrapped = self else { return .init(describing: self) }
    return .init(describing: unwrapped)
  }
}

extension Argument {

  var markdownDocumentation: String {
    """
    #### \(self.argNames.map({ "`\($0.text)`" }).joined(separator: ", "))
    **(\(argType.description))** \(detailedHelpText)

    **Default**: \(self.defaultValueDescription).
    """
  }

  static var fullMarkdownDocumentation: String {
    Argument.allCases.map {
      $0.markdownDocumentation
    }
    .joined(separator: "\n")
  }
}
