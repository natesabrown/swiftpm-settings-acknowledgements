import XCTest

@testable import make_settings_from_spm

class SPMSettingsAcknowledgementsTests: XCTestCase {

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
