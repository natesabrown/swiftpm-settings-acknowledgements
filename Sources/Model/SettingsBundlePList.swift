import Foundation

/// Represents the different types of files that are necessary for making the Settings property list, and encapsulates logic related to making the files.
enum SettingsBundlePList {

  /// For `Root.plist`. This is the entry point for custom settings.
  case root
  /// For `Acknowledgements.plist`. This page lists the different packages and allows folks to see which license is used.
  case acknowledgements(packageNames: [String])
  /// For a custom license page that can be drilled down to from the acknowledgements page.
  case package(info: PackageInfo)

  /// A dictionary type that translates well into the property list structure.
  typealias SettingsPListDict = [String: [[String: String]]]

  /// The URL for where the property list data should be written.
  func url(startingPoint: URL) -> URL {

    let appendString =
      switch self {
      case .root:
        "Root.plist"
      case .acknowledgements:
        "Acknowledgements.plist"
      case .package(let packageInfo):
        "\(packageInfo.name).plist"
      }

    return startingPoint.appendingBackport(path: appendString)
  }

  /// Data for the property list for this part of the settings bundle, encoded from the corresponding dictionary.
  var pListData: Data {
    get throws {
      let encoder = PropertyListEncoder()
      return try encoder.encode(pListDict)
    }
  }

  /// A dictionary representing the content that should be embedded in a plist for the settings bundle.
  private var pListDict: SettingsPListDict {
    switch self {
    case .root:
      [
        "PreferenceSpecifiers": [
          [
            "Type": "PSChildPaneSpecifier",
            "Title": "Acknowledgements",
            "File": "Acknowledgements",
          ]
        ]
      ]
    case .acknowledgements(let packageNames):
      [
        "PreferenceSpecifiers":
          packageNames.sorted().map {
            [
              "Type": "PSChildPaneSpecifier",
              "Title": "\($0)",
              "File": "\($0)",
            ]
          }
      ]
    case .package(let packageInfo):
      [
        "PreferenceSpecifiers": [
          [
            "Type": "PSGroupSpecifier",
            "FooterText": packageInfo.license,
          ]
        ]
      ]
    }
  }
}
