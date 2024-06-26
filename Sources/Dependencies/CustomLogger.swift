import Foundation

struct CustomLogger {
  /// Log critical errors that should be reported to the user.
  /// Depending on severity, these may come at the end of program execution.
  let error: (String) -> Void
  /// Log important messages that should be reported to the user.
  let warning: (String) -> Void
  /// Log informational messages that can be reported to the user if they opt in.
  let info: (String) -> Void
}

// MARK: - Live Implementation
extension CustomLogger {

  static func live(
    verbose: Bool
  ) -> Self {
    .init(
      error: {
        print($0)
      },
      warning: {
        print($0)
      },
      info: {
        if verbose {
          print($0)
        }
      }
    )
  }
}
