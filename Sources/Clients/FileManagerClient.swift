import Foundation

struct FileManagerClient {

  let getSubdirectories: (_ source: URL) throws -> [URL]

  let currentDirectoryPath: () -> String

  let createDirectory: (_ at: URL) throws -> Void
}

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
