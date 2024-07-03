import XCTest

@testable import swiftpm_settings_acknowledgements

class SPMSettingsAcknowledgementsTests: XCTestCase {

  // MARK: - Read Package.resolved
  func testReadPackageResolvedFileFromPackageResolvedPath() throws {

    let structure = try SPMSettingsAcknowledgements.readPackageResolvedFile(
      args: .test(
        directoryPath: "ignored",
        packageResolvedPath: "file://directory/Package.resolved"
      ),
      environment: .test(
        fileManagerClient: .test(
          stringContents: { url in
            XCTAssertEqual(url, URL(fileURLWithPath: "file://directory/Package.resolved"))
            return Self.examplePackageResolved
          }
        )
      )
    )

    XCTAssertEqual(
      structure,
      .init(
        pins: [
          .init(
            identity: "swift-argument-parser",
            location: "https://github.com/apple/swift-argument-parser"),
          .init(
            identity: "swift-docc-plugin", location: "https://github.com/apple/swift-docc-plugin"),
          .init(
            identity: "swift-docc-symbolkit",
            location: "https://github.com/apple/swift-docc-symbolkit"),
        ],
        version: 2
      )
    )
  }

  func testReadPackageResolvedFileFromSpecifiedDirectoryPath() throws {

    let structure = try SPMSettingsAcknowledgements.readPackageResolvedFile(
      args: .test(
        directoryPath: "/Users/bao/Developer/path"
      ),
      environment: .test(
        fileManagerClient: .test(
          getSubdirectories: { _ in
            [
              URL(fileURLWithPath: "/Users/bao/Developer/path/example.xcodeproj")
            ]
          },
          stringContents: { url in
            XCTAssertEqual(
              url,
              URL(
                fileURLWithPath:
                  "/Users/bao/Developer/path/example.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
              ))
            return Self.examplePackageResolved
          }
        )
      )
    )

    XCTAssertEqual(
      structure,
      .init(
        pins: [
          .init(
            identity: "swift-argument-parser",
            location: "https://github.com/apple/swift-argument-parser"),
          .init(
            identity: "swift-docc-plugin", location: "https://github.com/apple/swift-docc-plugin"),
          .init(
            identity: "swift-docc-symbolkit",
            location: "https://github.com/apple/swift-docc-symbolkit"),
        ],
        version: 2
      )
    )
  }

  func testReadPackageResolvedFileNoPathsSpecified() throws {

    let structure = try SPMSettingsAcknowledgements.readPackageResolvedFile(
      args: .test(),
      environment: .test(
        fileManagerClient: .test(
          getSubdirectories: { _ in
            [
              URL(fileURLWithPath: "/Users/bao/Developer/path/example.xcodeproj")
            ]
          },
          currentDirectoryPath: { "/Users/bao/Developer/path" },
          stringContents: { url in
            XCTAssertEqual(
              url,
              URL(
                fileURLWithPath:
                  "/Users/bao/Developer/path/example.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
              ))
            return Self.examplePackageResolved
          }
        )
      )
    )

    XCTAssertEqual(
      structure,
      .init(
        pins: [
          .init(
            identity: "swift-argument-parser",
            location: "https://github.com/apple/swift-argument-parser"),
          .init(
            identity: "swift-docc-plugin", location: "https://github.com/apple/swift-docc-plugin"),
          .init(
            identity: "swift-docc-symbolkit",
            location: "https://github.com/apple/swift-docc-symbolkit"),
        ],
        version: 2
      )
    )
  }

  func testReadPackageResolvedFileNoXcodeProjInDirectory() throws {

    var triggeredError: (any Error)? = nil

    do {
      let _ = try SPMSettingsAcknowledgements.readPackageResolvedFile(
        args: .test(),
        environment: .test(
          fileManagerClient: .test(
            getSubdirectories: { _ in
              // Empty array - no files in current directory.
              []
            },
            currentDirectoryPath: { "" }
          )
        )
      )
    } catch {
      triggeredError = error
    }

    XCTAssertEqual(
      triggeredError as? RunError,
      RunError.couldNotFindXcodeProjInCurrentDirectory
    )
  }

  func testReadPackageResolvedFileCouldNotParsePackageResolved() throws {

    var triggeredError: (any Error)? = nil

    do {
      let _ = try SPMSettingsAcknowledgements.readPackageResolvedFile(
        args: .test(),
        environment: .test(
          fileManagerClient: .test(
            getSubdirectories: { _ in
              [
                try XCTUnwrap(URL(string: "example/example.xcodeproj"))
              ]
            },
            currentDirectoryPath: { "" },
            stringContents: { _ in
              ""
            }
          )
        )
      )
    } catch {
      triggeredError = error
    }

    XCTAssertEqual(
      triggeredError as? RunError,
      RunError.couldNotParsePackageResolved(
        fileLocation:
          "example/example.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
    )
  }

  // MARK: - Get package info from GitHub
  func testGetPackageInfoFromGitHub() async throws {

    let licenses = try await SPMSettingsAcknowledgements.getPackageInfoFromGitHub(
      packageResolvedStructure: .init(
        pins: [
          .init(
            identity: "swift-argument-parser",
            location: "https://github.com/apple/swift-argument-parser.git"),
          .init(identity: "swift", location: "https://github.com/swiftlang/swift"),
          .init(identity: "custom-package", location: "https://someurl.com/myname/mypackage"),
        ],
        version: 1
      ),
      environment: .test(
        gitHubClient: .init(
          getLicenseContent: { _ in "" }
        )
      )
    )

    // 2 packages have legitimate GitHub URLs, so expect 2 licenses to be returned.
    XCTAssertEqual(licenses.count, 2)
  }

  // MARK: - Create language project directories
  func testCreateLanguageProjectDirectories() throws {

    var createdDirectories: [URL] = []
    var createdStringsFiles: [URL] = []
    var createdData: [Data] = []

    try SPMSettingsAcknowledgements.createLanguageProjectDirectories(
      languageCodesString: "en, fr, zh_Hans, chicken",
      settingsBundleURL: try XCTUnwrap(.init(string: "example/example")),
      environment: .test(
        fileManagerClient: .init(
          getSubdirectories: { _ in [] },
          currentDirectoryPath: { "" },
          createDirectory: { createdDirectories.append($0) },
          stringContents: { _ in "" },
          dataContents: { _ in Data() },
          writeDataToURL: { data, url in
            createdData.append(data)
            createdStringsFiles.append(url)
          }
        )
      )
    )

    // Test that the .lproj subdirectories get made.
    XCTAssertEqual(
      createdDirectories.map { $0.absoluteString },
      [
        "example/example/en.lproj",
        "example/example/fr.lproj",
        "example/example/zh_Hans.lproj",
      ]
    )

    // Test that the strings files get made.
    XCTAssertEqual(
      createdStringsFiles.map { $0.absoluteString },
      [
        "example/example/en.lproj/Root.strings",
        "example/example/fr.lproj/Root.strings",
        "example/example/zh_Hans.lproj/Root.strings",
      ]
    )

    // Test that the contents of the strings files is what we expect.
    XCTAssertEqual(
      createdData.map { String(data: $0, encoding: .utf8) },
      [
        "\"Acknowledgements\" = \"Acknowledgements\";",
        "\"Acknowledgements\" = \"Remerciements\";",
        "\"Acknowledgements\" = \"致谢\";",
      ]
    )
  }

  // MARK: - Get package info from cache directory
  func testGetPackageInfoFromCacheDirectory() throws {

    let packageInfo = try SPMSettingsAcknowledgements.getPackageInfoFromCacheDirectory(
      packageCachePath: "/Users/bao/cache",
      environment: .test(
        fileManagerClient: .test(
          getSubdirectories: { url in
            if url.lastPathComponent == "cache" {
              return [
                "package-one", "package-two", "package-three",
              ].map { url.appendingPathComponent($0) }
            } else {
              return [
                url.appendingPathComponent("LICENSE")
              ]
            }
          },
          dataContents: { _ in
            try XCTUnwrap(String("License").data(using: .utf8))
          }
        )
      )
    )

    XCTAssertEqual(
      packageInfo,
      [
        .init(name: "package-one", license: "License"),
        .init(name: "package-two", license: "License"),
        .init(name: "package-three", license: "License"),
      ]
    )
  }

  func testGetPackageInfoFromCacheDirectoryShouldIgnoreNoLicense() throws {

    let packageInfo = try SPMSettingsAcknowledgements.getPackageInfoFromCacheDirectory(
      packageCachePath: "/Users/bao/cache",
      environment: .test(
        fileManagerClient: .test(
          getSubdirectories: { url in
            if url.lastPathComponent == "cache" {
              return [
                "package-one", "package-two", "package-three",
              ].map { url.appendingPathComponent($0) }
            } else {
              return if url.lastPathComponent == "package-one" {
                [url.appendingPathComponent("LICENSE")]
              } else {
                []
              }
            }
          },
          dataContents: { _ in
            try XCTUnwrap(String("License").data(using: .utf8))
          }
        )
      )
    )

    XCTAssertEqual(
      packageInfo,
      [
        .init(name: "package-one", license: "License")
      ]
    )
  }

}

// MARK: - Testing Helpers
extension CommandLineArguments {

  static func test(
    directoryPath: String? = nil,
    languages: String = "en",
    outputPath: String? = nil,
    packageCachePath: String? = nil,
    packageResolvedPath: String? = nil
  ) -> Self {
    .init(
      directoryPath: directoryPath,
      languages: languages,
      outputPath: outputPath,
      packageCachePath: packageCachePath,
      packageResolvedPath: packageResolvedPath
    )
  }
}

extension Environment {

  static func test(
    fileManagerClient: FileManagerClient = .noop,
    gitHubClient: GitHubClient = .noop,
    logger: CustomLogger = .noop
  ) -> Self {
    .init(
      fileManagerClient: fileManagerClient,
      gitHubClient: gitHubClient,
      logger: logger
    )
  }
}

extension CustomLogger {

  static var noop: Self {
    .init(
      error: { _ in },
      warning: { _ in },
      info: { _ in }
    )
  }
}

extension FileManagerClient {

  static func test(
    getSubdirectories: @escaping (_ source: URL) throws -> [URL] = { _ in
      XCTFail("Unimplemented")
      return []
    },
    currentDirectoryPath: @escaping () -> String = {
      XCTFail("Unimplemented")
      return ""
    },
    createDirectory: @escaping (_ at: URL) throws -> Void = { _ in
      XCTFail("Unimplemented")
    },
    stringContents: @escaping (_ from: URL) throws -> String = { _ in
      XCTFail("Unimplemented")
      return ""
    },
    dataContents: @escaping (_ from: URL) throws -> Data = { _ in
      XCTFail("Unimplemented")
      return Data()
    },
    writeDataToURL: @escaping (Data, URL) throws -> Void = { _, _ in
      XCTFail("Unimplemented")
    }
  ) -> Self {
    .init(
      getSubdirectories: getSubdirectories,
      currentDirectoryPath: currentDirectoryPath,
      createDirectory: createDirectory,
      stringContents: stringContents,
      dataContents: dataContents,
      writeDataToURL: writeDataToURL
    )
  }

  static var noop: Self {
    .init(
      getSubdirectories: { _ in [] },
      currentDirectoryPath: { "" },
      createDirectory: { _ in },
      stringContents: { _ in "" },
      dataContents: { _ in Data() },
      writeDataToURL: { _, _ in }
    )
  }
}

extension GitHubClient {

  static var noop: Self {
    .init(
      getLicenseContent: { _ in "" }
    )
  }
}

extension SPMSettingsAcknowledgementsTests {

  static var examplePackageResolved: String {
    """
    {
      "pins" : [
        {
          "identity" : "swift-argument-parser",
          "kind" : "remoteSourceControl",
          "location" : "https://github.com/apple/swift-argument-parser",
          "state" : {
            "revision" : "0fbc8848e389af3bb55c182bc19ca9d5dc2f255b",
            "version" : "1.4.0"
          }
        },
        {
          "identity" : "swift-docc-plugin",
          "kind" : "remoteSourceControl",
          "location" : "https://github.com/apple/swift-docc-plugin",
          "state" : {
            "revision" : "26ac5758409154cc448d7ab82389c520fa8a8247",
            "version" : "1.3.0"
          }
        },
        {
          "identity" : "swift-docc-symbolkit",
          "kind" : "remoteSourceControl",
          "location" : "https://github.com/apple/swift-docc-symbolkit",
          "state" : {
            "revision" : "b45d1f2ed151d057b54504d653e0da5552844e34",
            "version" : "1.0.0"
          }
        }
      ],
      "version" : 2
    }
    """
  }
}
