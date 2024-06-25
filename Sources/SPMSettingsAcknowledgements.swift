import Foundation

@available(macOS 10.15, *)
enum SPMSettingsAcknowledgements {

  enum RunError: LocalizedError {
    case couldNotParsePackageResolved

    var errorDescription: String? {
      switch self {
      case .couldNotParsePackageResolved:
        "Could not parse Package.resolved."
      }
    }
  }

  static func run(
    fileManagerClient: FileManagerClient,
    gitHubClient: GitHubClient,
    logger: CustomLogger,
    directoryPath: String?,
    packageCachePath: String?,
    outputPath: String?,
    packageResolvedPath: String?
  ) async throws {

    let directoryPath = directoryPath ?? fileManagerClient.currentDirectoryPath()

    // If the user hasn't provided a path to the `Package.resolved` file, we will need to find it.
    let packageResolvedPath =
      if let packageResolvedPath {
        URL(fileURLWithPath: packageResolvedPath)
      } else {
        try fileManagerClient
          .getSubdirectories(URL(fileURLWithPath: directoryPath))
          .first { $0.pathExtension == "xcodeproj" }?
          .appendingBackport(path: "project.xcworkspace")
          .appendingBackport(path: "xcshareddata")
          .appendingBackport(path: "swiftpm")
          .appendingBackport(path: "Package.resolved")
      }

    guard let packageResolvedPath,
      let packageResolvedContents = try? String(contentsOf: packageResolvedPath),
      let packageResolvedData = packageResolvedContents.data(using: .utf8),
      let packageResolvedStructure = try? JSONDecoder().decode(
        PackageResolvedStructure.self,
        from: packageResolvedData
      )
    else {
      throw RunError.couldNotParsePackageResolved
    }

    logger.info("Parsed Package.resolved.")

    let licenses =
      if let packageCachePath {
        try await getPackageInfoFromCacheDirectory(
          fileManagerClient: fileManagerClient,
          packageCachePath: packageCachePath
        )
      } else {
        try await getPackageInfoFromGitHub(
          gitHubClient: gitHubClient,
          packageResolvedStructure: packageResolvedStructure,
          logger: logger
        )
      }

    // If no output path is specified, we will use the current directory.
    let outputPath = outputPath ?? fileManagerClient.currentDirectoryPath()

    // Create the settings bundle.
    let currentURL = URL(fileURLWithPath: outputPath)
    let desiredURL = currentURL.appendingBackport(path: "Settings.bundle")
    try fileManagerClient.createDirectory(desiredURL)

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

  static func getPackageInfoFromGitHub(
    gitHubClient: GitHubClient,
    packageResolvedStructure: PackageResolvedStructure,
    logger: CustomLogger
  ) async throws -> [PackageInfo] {

    try await withThrowingTaskGroup(of: PackageInfo.self, returning: [PackageInfo].self) {
      taskGroup in

      for pin in packageResolvedStructure.pins {

        let location = pin.location
        let adjustedLocation =
          location
          .replacingOccurrences(of: "https://github.com/", with: "")
          .replacingOccurrences(of: ".git", with: "")

        taskGroup.addTask {
          logger.info("Downloading license for \(pin.identity) at \(pin.location)...")
          let licenseContent = try await gitHubClient.getLicenseContent(adjustedLocation)
          return .init(
            name: pin.identity,
            license: licenseContent
          )
        }
      }

      return try await taskGroup.reduce(into: [PackageInfo]()) {
        $0.append($1)
      }
    }
  }

  static func getPackageInfoFromCacheDirectory(
    fileManagerClient: FileManagerClient,
    packageCachePath: String
  ) async throws -> [PackageInfo] {

    let url = URL(fileURLWithPath: packageCachePath)

    let subDirectories =
      try fileManagerClient
      .getSubdirectories(url)
      .filter(\.isDirectory)

    let licenses: [PackageInfo] = try subDirectories.compactMap { subDirectory in

      let files = try fileManagerClient.getSubdirectories(subDirectory)

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

    return licenses
  }
}
