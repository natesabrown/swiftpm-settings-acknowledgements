import Foundation

/// > Note:
/// These translations were produced with the help of LLMs and internet dictionaries, so I cannot guarantee their accuracy.
/// Folks are welcome to extend this in a fork or open PRs to add to the translations.
enum AcknowledgementsTranslation: String, CaseIterable {

  case en = "Acknowledgements"
  case es = "Agradecimientos"
  case fr = "Remerciements"
  case ka = "ಕೃತಜ್ಞತಾ ಸೂಚನೆ"
  case ja = "謝辞"
  case zh_Hans = "致谢"

  init?(languageCode: String) {
    guard let correspondingCase = Self.allCases.first(where: { "\($0)" == languageCode }) else {
      return nil
    }
    self = correspondingCase
  }

  var languageProjectName: String {
    "\(self).lproj"
  }

  /// The URL for where the language project should be created.
  func languageProjectURL(startingPoint: URL) -> URL {
    startingPoint.appendingPathComponent(languageProjectName)
  }

  /// The URL for where the Strings file should be created.
  func stringsFileURL(startingPoint: URL) -> URL {
    startingPoint.appendingPathComponent("Root.strings")
  }

  /// The data (translation) that should be written to the strings file.
  var stringsFileData: Data? {
    let fileContents = "\"Acknowledgements\" = \"\(self.rawValue)\";"
    return fileContents.data(using: .utf8)
  }
}
