import Foundation

struct CustomLogger {

  let error: (String) -> Void

  let warning: (String) -> Void

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
