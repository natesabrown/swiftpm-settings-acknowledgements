import Foundation

extension URL {

  func appendingBackport(
    path: String
  ) -> Self {
    if #available(macOS 13.0, *) {
      self.appending(path: path)
    } else {
      self.appendingPathComponent(path)
    }
  }
}
