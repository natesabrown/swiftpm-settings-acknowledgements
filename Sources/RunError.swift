import Foundation

/// General errors that can occur during a run of the executable.
enum RunError: LocalizedError, Equatable {

  case couldNotFindXcodeProjInCurrentDirectory
  case couldNotParsePackageResolved(fileLocation: String)

  var errorDescription: String? {
    switch self {
    case .couldNotParsePackageResolved(let fileLocation):
      "Could not parse Package.resolved at \(fileLocation)"
    case .couldNotFindXcodeProjInCurrentDirectory:
      "Could not find .xcodeproj in the current directory."
    }
  }
}
