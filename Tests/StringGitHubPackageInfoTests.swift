import XCTest

@testable import swiftpm_settings_acknowledgements

class StringGitHubPackageInfoTests: XCTestCase {

  func testPackageInfoValid() {

    let packageInfo = "https://github.com/apple/swift-argument-parser.git".gitHubPackageInfo
    let expectedValue: GitHubPackageInfo = .init(
      owner: "apple",
      name: "swift-argument-parser"
    )

    XCTAssertEqual(packageInfo, expectedValue)
  }

  func testPackageInfoNotGitHub() {

    let packageInfo = "https://gitlab.com/apple/swift-argument-parser.git".gitHubPackageInfo
    XCTAssertNil(packageInfo)
  }

  func testPackageInfoMissingInformation() {

    let packageInfo = "https://github.com/apple".gitHubPackageInfo
    XCTAssertNil(packageInfo)
  }
}
