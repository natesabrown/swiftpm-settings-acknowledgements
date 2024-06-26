import Foundation

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
    args: CommandLineArguments,
    environment: Environment
  ) async throws {

    let directoryPath = args.directoryPath ?? environment.fileManagerClient.currentDirectoryPath()

    // If the user hasn't provided a path to the `Package.resolved` file, we will need to find it.
    let packageResolvedPath =
      if let packageResolvedPath = args.packageResolvedPath {
        URL(fileURLWithPath: packageResolvedPath)
      } else {
        try environment.fileManagerClient
          .getSubdirectories(URL(fileURLWithPath: directoryPath))
          .first { $0.pathExtension == "xcodeproj" }?
          .appendingPathComponent("project.xcworkspace")
          .appendingPathComponent("xcshareddata")
          .appendingPathComponent("swiftpm")
          .appendingPathComponent("Package.resolved")
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

    environment.logger.info("Parsed Package.resolved.")

    let licenses =
      if let packageCachePath = args.packageCachePath {
        try await getPackageInfoFromCacheDirectory(
          fileManagerClient: environment.fileManagerClient,
          packageCachePath: packageCachePath
        )
      } else {
        try await getPackageInfoFromGitHub(
          gitHubClient: environment.gitHubClient,
          packageResolvedStructure: packageResolvedStructure,
          logger: environment.logger
        )
      }

    // If no output path is specified, we will use the current directory.
    let outputPath = args.outputPath ?? environment.fileManagerClient.currentDirectoryPath()

    // Create the settings bundle.
    let currentURL = URL(fileURLWithPath: outputPath)
    let desiredURL = currentURL.appendingPathComponent("Settings.bundle")
    try environment.fileManagerClient.createDirectory(desiredURL)

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

    try await withThrowingTaskGroup(of: PackageInfo?.self, returning: [PackageInfo].self) {
      taskGroup in

      for pin in packageResolvedStructure.pins {
        // Make sure the location is a GitHub URL. If not, print a warning message and skip the API request.
        guard let gitHubPackageInfo = pin.location.gitHubPackageInfo else {
          logger.warning("\(pin.location) is not a valid GitHub URL. Skipping...")
          continue
        }
        taskGroup.addTask {
          logger.info("Downloading license for \(pin.identity) at \(pin.location)...")
          do {
            let licenseContent = try await gitHubClient.getLicenseContent(gitHubPackageInfo)
            return .init(
              name: pin.identity,
              license: licenseContent
            )
          } catch {
            logger.error(
              "Got error when trying to fetch license for \(pin.identity) from GitHub:\n\(error.localizedDescription)."
            )
            return nil
          }
        }
      }

      return try await taskGroup.reduce(into: [PackageInfo?]()) {
        $0.append($1)
      }
      .compactMap { $0 }
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
