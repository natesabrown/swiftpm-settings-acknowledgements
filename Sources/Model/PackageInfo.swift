import Foundation

/// Information needed from each package to create its corresponding entries in the Settings bundle.
struct PackageInfo: Equatable {
  /// The package's name.
  let name: String
  /// The package's license content, including whitespace.
  let license: String
}
