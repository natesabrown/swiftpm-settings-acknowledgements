import Foundation

/// A convenience struct for the environment we will pass around during program execution.
///
/// This helps us clearly demarcate points in the executable in which we will reach into an outside system.
struct Environment {
  /// Provides an interface for file system operations.
  let fileManagerClient: FileManagerClient
  /// Provides a way of contacting GitHub to get license information.
  let gitHubClient: GitHubClient
  /// A logger to display critical and informational messages to the user.
  let logger: CustomLogger
}
