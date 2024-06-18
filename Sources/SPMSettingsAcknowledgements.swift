import Foundation

enum SPMSettingsAcknowledgements {

  static func run(
    fileManager: FileManager,
    packageCachePath: String,
    outputPath: String?
  ) throws {

    let url = URL(fileURLWithPath: packageCachePath)

    let subDirectories = try fileManager.contentsOfDirectory(
      at: url,
      includingPropertiesForKeys: nil,
      options: .skipsHiddenFiles
    )
    .filter(\.isDirectory)

    let licenses: [PackageInfo] = try subDirectories.compactMap { subDirectory in

      let files = try fileManager.contentsOfDirectory(
        at: subDirectory,
        includingPropertiesForKeys: nil
      )

      guard let licenseFile = files.first(where: { $0.lastPathComponent.contains("LICENSE") })
      else {
        return nil
      }

      let fileData = try Data(contentsOf: licenseFile)
      guard let licenseContents = String(data: fileData, encoding: .utf8) else {
        return nil
      }

      return PackageInfo(
        name: subDirectory.lastPathComponent,
        license: licenseContents
      )
    }

    let currentDirectory = fileManager.currentDirectoryPath
    let currentURL = URL(fileURLWithPath: currentDirectory)
    let desiredURL = currentURL.appendingBackport(path: "Settings.bundle")

    // Create the settings bundle.
    try FileManager.default.createDirectory(
      at: desiredURL,
      withIntermediateDirectories: true
    )

    // Make the necessary `Root.plist`.
    let rootData = try SettingsBundlePList.root.pListData
    try rootData.write(to: SettingsBundlePList.root.url(startingPoint: desiredURL))

    // Make the `Acknowledgements.plist` page that will link to licenses for all the packages.
    let acknowledgements = SettingsBundlePList.acknowledgements(packageNames: licenses.map(\.name))
    let acknowledgementsData = try acknowledgements.pListData
    try acknowledgementsData.write(to: acknowledgements.url(startingPoint: desiredURL))

    // Make all property list files for the individual licenses.
    try licenses.forEach {
      let package = SettingsBundlePList.package(info: $0)
      let packageData = try package.pListData
      try packageData.write(to: package.url(startingPoint: desiredURL))
    }
  }
}
