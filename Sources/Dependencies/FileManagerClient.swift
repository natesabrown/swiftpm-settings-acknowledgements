import Foundation

struct FileManagerClient {
  /// Returns a list of the subdirectories for a given source URL.
  let getSubdirectories: (_ source: URL) throws -> [URL]
  /// Returns the path of the executing process.
  let currentDirectoryPath: () -> String
  /// Attempt to create a directory at a given path.
  let createDirectory: (_ at: URL) throws -> Void
}

// MARK: - Live Implementation
extension FileManagerClient {

  static var live: Self {
    .init(
      getSubdirectories: {
        try FileManager.default.contentsOfDirectory(
          at: $0,
          includingPropertiesForKeys: nil,
          options: .skipsHiddenFiles
        )
      },
      currentDirectoryPath: {
        FileManager.default.currentDirectoryPath
      },
      createDirectory: {
        try FileManager.default.createDirectory(
          at: $0,
          withIntermediateDirectories: true
        )
      }
    )
  }
}
