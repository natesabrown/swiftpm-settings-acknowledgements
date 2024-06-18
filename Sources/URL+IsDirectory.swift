import Foundation

extension URL {
  /// Returns `true` if this URL has metadata that confirms it represents the path to a directory.
  var isDirectory: Bool {
    (try? self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
  }
}
