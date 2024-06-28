import Foundation

/// Namespace for core program logic.
enum SPMSettingsAcknowledgements {

  /// The core logic for running the executable.
  /// - Parameters:
  ///   - args: Command line arguments provided by the user, represented as a ``CommandLineArguments`` struct.
  ///   - environment: Dependencies that reach into the outside world, encapsulated in an ``Environment`` struct.
  static func run(
    args: CommandLineArguments,
    environment: Environment
  ) async throws {

    // Retrieve the licenses and package names.
    let licenses: [PackageInfo]
    // If user specifies the package cache path, shortcut to looking through it.
    // It will have all the relevant information in its subdirectories, so it's unnecessary to look through a `Package.resolved`.
    if let packageCachePath = args.packageCachePath {

      environment.logger.info(
        """
        User supplied a SPM package cache path of \(packageCachePath).
        Attempting to parse available packages for licenses...
        """
      )

      licenses = try getPackageInfoFromCacheDirectory(
        packageCachePath: packageCachePath,
        environment: environment
      )
    } else {
      let packageResolvedStructure = try readPackageResolvedFile(
        args: args,
        environment: environment
      )
      environment.logger.info(
        "Attempting to retrieve package and license information from GitHub...")
      licenses = try await getPackageInfoFromGitHub(
        packageResolvedStructure: packageResolvedStructure,
        environment: environment
      )
    }

    // Get the path we will create the Settings.bundle at.
    let outputPath: String
    if let argsPath = args.outputPath {
      environment.logger.info(
        "Using supplied directory as output path for settings bundle: \(argsPath)")
      outputPath = argsPath
    } else {
      let currentDirectoryPath = environment.fileManagerClient.currentDirectoryPath()
      environment.logger.info("No output path specified, using current directory path: ")
      outputPath = currentDirectoryPath
    }

    // Create the settings bundle.
    let currentURL = URL(fileURLWithPath: outputPath)
    let settingsBundleURL = currentURL.appendingPathComponent("Settings.bundle")
    try environment.fileManagerClient.createDirectory(settingsBundleURL)

    // Make the necessary `Root.plist`.
    try environment.fileManagerClient.writePListDataToBundle(
      SettingsBundlePList.root,
      startingPoint: settingsBundleURL
    )

    // Make language project directories to help localized the acknowledgements text.
    try createLanguageProjectDirectories(
      languageCodesString: args.languages,
      settingsBundleURL: settingsBundleURL,
      environment: environment
    )

    // Make the `Acknowledgements.plist` page that will link to licenses for all the packages.
    try environment.fileManagerClient.writePListDataToBundle(
      SettingsBundlePList.acknowledgements(packageNames: licenses.map(\.name)),
      startingPoint: settingsBundleURL
    )

    // Make all property list files for the individual licenses.
    try licenses.forEach {
      try environment.fileManagerClient.writePListDataToBundle(
        SettingsBundlePList.package(info: $0),
        startingPoint: settingsBundleURL
      )
    }
  }

  static func createLanguageProjectDirectories(
    languageCodesString: String,
    settingsBundleURL: URL,
    environment: Environment
  ) throws {

    let languageCodes = languageCodesString.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

    environment.logger.info(
      "Got the following language codes: \(String(describing: languageCodes))")

    for languageCode in languageCodes {

      guard let translation = AcknowledgementsTranslation.init(languageCode: languageCode) else {
        environment.logger.error("Could not find translation for language code \(languageCode).")
        continue
      }

      let lProjURL = translation.languageProjectURL(startingPoint: settingsBundleURL)
      try environment.fileManagerClient.createDirectory(lProjURL)
      let stringsFileURL = translation.stringsFileURL(startingPoint: lProjURL)
      guard let data = translation.stringsFileData else { return }
      try environment.fileManagerClient.writeDataToURL(data, stringsFileURL)

      environment.logger.info("Wrote strings file for \(translation)")
    }
  }

  /// Attempts to read the contents of the `Package.resolved` file.
  ///
  /// The `Package.resolved` location is determined in the following manner:
  /// 1. It will use the direct path if supplied.
  /// 2. If not, it will attempt to find it in the root directory, if supplied.
  /// 3. If not, it will attempt to find it in the current directory.
  static func readPackageResolvedFile(
    args: CommandLineArguments,
    environment: Environment
  ) throws -> PackageResolvedStructure {

    /// The potential location of the `Package.resolved` file.
    let packageResolvedPath: URL

    if let argsPath = args.packageResolvedPath {

      environment.logger.info("Using user-specified Package.resolved at \(argsPath).")
      packageResolvedPath = URL(fileURLWithPath: argsPath)
    } else {

      environment.logger.info("User did not specify Package.resolved location.")

      let directoryPath: String
      if let specifiedDirectoryPath = args.directoryPath {
        environment.logger.info(
          "Looking in user-specified root directory \(specifiedDirectoryPath)")
        directoryPath = specifiedDirectoryPath
      } else {
        let currentDirectoryPath = environment.fileManagerClient.currentDirectoryPath()
        environment.logger.info("Looking in the current directory \(currentDirectoryPath)")
        directoryPath = currentDirectoryPath
      }

      let potentialPath = try environment.fileManagerClient
        .getSubdirectories(URL(fileURLWithPath: directoryPath))
        .first { $0.pathExtension == "xcodeproj" }?
        .appendingPathComponent("project.xcworkspace")
        .appendingPathComponent("xcshareddata")
        .appendingPathComponent("swiftpm")
        .appendingPathComponent("Package.resolved")

      guard let potentialPath else {
        throw RunError.couldNotFindXcodeProjInCurrentDirectory
      }

      packageResolvedPath = potentialPath
    }

    guard
      let packageResolvedContents = try? environment.fileManagerClient.stringContents(
        packageResolvedPath),
      let packageResolvedData = packageResolvedContents.data(using: .utf8),
      let packageResolvedStructure = try? JSONDecoder().decode(
        PackageResolvedStructure.self,
        from: packageResolvedData
      )
    else {
      throw RunError.couldNotParsePackageResolved(fileLocation: packageResolvedPath.absoluteString)
    }

    return packageResolvedStructure
  }

  static func getPackageInfoFromGitHub(
    packageResolvedStructure: PackageResolvedStructure,
    environment: Environment
  ) async throws -> [PackageInfo] {
    // Using a task group will let us make multiple network requests at the same time, improving speed.
    try await withThrowingTaskGroup(of: PackageInfo?.self, returning: [PackageInfo].self) {
      taskGroup in

      for pin in packageResolvedStructure.pins {
        // Make sure the location is a GitHub URL. If not, print a warning message and skip the API request.
        guard let gitHubPackageInfo = pin.location.gitHubPackageInfo else {
          environment.logger.warning("\(pin.location) is not a valid GitHub URL. Skipping...")
          continue
        }

        taskGroup.addTask {
          environment.logger.info("Downloading license for \(pin.identity) at \(pin.location)...")
          do {
            let licenseContent = try await environment.gitHubClient.getLicenseContent(
              gitHubPackageInfo)
            return .init(
              name: pin.identity,
              license: licenseContent
            )
          } catch {
            environment.logger.error(
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
    packageCachePath: String,
    environment: Environment
  ) throws -> [PackageInfo] {

    let cacheDirectoryURL = URL(fileURLWithPath: packageCachePath)
    let subDirectories = try environment.fileManagerClient
      .getSubdirectories(cacheDirectoryURL)

    let licenses: [PackageInfo] = try subDirectories.compactMap { subDirectory in
      // Get available files in cache directory.
      let files = try environment.fileManagerClient.getSubdirectories(subDirectory)
      // For now, we will assume a license is the first file that shouts "LICENSE", case insensitive.
      // This may need to be revisited.
      guard
        let licenseFile = files.first(where: {
          $0.lastPathComponent.localizedCaseInsensitiveContains("LICENSE")
        })
      else {
        environment.logger.warning("Could not find license for \(subDirectory.lastPathComponent)")
        return nil
      }
      // Decode license information from the URL.
      let fileData = try environment.fileManagerClient.dataContents(licenseFile)
      guard let licenseContents = String(data: fileData, encoding: .utf8) else {
        environment.logger.warning(
          "Could not decode license for \(subDirectory.lastPathComponent) at \(licenseFile.absoluteString)"
        )
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
