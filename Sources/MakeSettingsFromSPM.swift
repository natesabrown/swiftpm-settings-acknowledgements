import ArgumentParser
import Foundation

let fileManager = FileManager.default

@available(macOS 13.0, *)
@main
struct MakeSettingsFromSPM: ParsableCommand {

  @Option(
    name: [
      .customLong("package-cache-path"),
      .customShort("p"),
    ],
    help: "Package cache path")
  public var packageCachePath: String

  @Option(
    name: [
      .customLong("output-path"),
      .customShort("o"),
    ],
    help: "Where the Settings.bundle should end up.")
  public var outputPath: String? = nil

  public func run() throws {

    let url = URL(fileURLWithPath: packageCachePath)

    let subDirectories = try fileManager.contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: nil,
      options: .skipsHiddenFiles
    )
    .filter(\.isDirectory)

    var licenses: [String: String] = [:]

    for subDirectory in subDirectories {

      let files = try fileManager.contentsOfDirectory(
        at: subDirectory,
        includingPropertiesForKeys: nil
      )

      for file in files {
        let fileName = file.lastPathComponent
        if fileName.contains("LICENSE") {

          let data = try Data(contentsOf: file)
          let stringContents = String(data: data, encoding: .utf8)

          if let stringContents {

            licenses.updateValue(stringContents, forKey: subDirectory.lastPathComponent)
          }
        }
      }
    }

    let currentDirectory = fileManager.currentDirectoryPath
    let currentURL = URL(fileURLWithPath: currentDirectory)
    let desiredURL = currentURL.appending(path: "Settings.bundle")

    // Create settings bundle
    try FileManager.default.createDirectory(
      at: desiredURL,
      withIntermediateDirectories: true
    )

    let encoder = PropertyListEncoder()

    let rootData = try encoder.encode(rootPropertyList)
    let rootLocation = desiredURL.appending(path: "Root.plist")
    try rootData.write(to: rootLocation)

    let names = licenses.keys.sorted()
    let acknowledgementsPropertyList = [
      "PreferenceSpecifiers":
        names.map {
          [
            "Type": "PSChildPaneSpecifier",
            "Title": "\($0)",
            "File": "\($0)",
          ]
        }
    ]

    let acknowldgementsData = try encoder.encode(acknowledgementsPropertyList)
    let acknowledgementsLocation = desiredURL.appending(path: "Acknowledgements.plist")
    try acknowldgementsData.write(to: acknowledgementsLocation)

    for (licenseName, content) in licenses {

      let licensePropertyList = [
        "PreferenceSpecifiers": [
          [
            "Type": "PSGroupSpecifier",
            "FooterText": content,
          ]
        ]
      ]

      let licenseData = try encoder.encode(licensePropertyList)
      let licenseLocation = desiredURL.appending(path: "\(licenseName).plist")
      try licenseData.write(to: licenseLocation)
    }
  }
}

struct PackageInfo {
  let name: String
  let license: String
}

typealias SettingsPListDict = [String: [[String: String]]]

enum SettingsBundlePropertyList {

  typealias SettingsPListDict = [String: [[String: String]]]

  case root
  case acknowledgements(packageNames: [String])
  case package(license: String)

  /// A dictionary representing the content that should be embedded in a plist for the settings bundle.
  var pListDict: SettingsPListDict {
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
          packageNames.map {
            [
              "Type": "PSChildPaneSpecifier",
              "Title": "\($0)",
              "File": "\($0)",
            ]
          }
      ]
    case .package(let license):
      [
        "PreferenceSpecifiers": [
          [
            "Type": "PSGroupSpecifier",
            "FooterText": license,
          ]
        ]
      ]
    }
  }
}

var rootPropertyList: SettingsPListDict {
  [
    "PreferenceSpecifiers": [
      [
        "Type": "PSChildPaneSpecifier",
        "Title": "Acknowledgements",
        "File": "Acknowledgements",
      ]
    ]
  ]
}

extension URL {
  /// Returns `true` if this URL has metadata that confirms it represents the path to a directory.
  var isDirectory: Bool {
    (try? self.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
  }
}
