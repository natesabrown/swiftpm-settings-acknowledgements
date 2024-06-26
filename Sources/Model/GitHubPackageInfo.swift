import Foundation

/// Information needed for a GitHub repository so that we can call the GitHub API.
struct GitHubPackageInfo: Equatable {
  let owner: String
  let name: String

  var fullPackageName: String {
    "\(owner)/\(name)"
  }
}
