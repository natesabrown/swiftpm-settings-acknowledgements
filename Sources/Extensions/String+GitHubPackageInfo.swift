import Foundation

extension String {

  /// For a string representing a URL, returns relevant information for receiving information from the GitHub API.
  ///
  /// * RegEx inspired by https://www.advancedswift.com/regex-capture-groups/.
  /// * `NSRegularExpression` is used over modern RegEx because this executable targets MacOS 12 rather than 13.
  var gitHubPackageInfo: GitHubPackageInfo? {

    guard
      let regex = try? NSRegularExpression(
        pattern: #".*github\.com\/(.*)\/(.*)"#,
        options: .caseInsensitive),
      let match = regex.matches(in: self, range: self.nsRange).first
    else {
      return nil
    }

    let extractedWords: [String] = (0..<(match.numberOfRanges)).compactMap { rangeIndex in

      let matchRange = match.range(at: rangeIndex)

      // Ignore matching the entire string
      if matchRange == self.nsRange { return nil }

      // Extract the substring matching the capture group
      guard let substringRange = Range(matchRange, in: self) else {
        return nil
      }
      return String(self[substringRange])
    }

    guard extractedWords.count == 2,
      let owner = extractedWords.first,
      let name = extractedWords.last
    else {
      return nil
    }

    return .init(
      owner: owner,
      name:
        name
        .replacingOccurrences(of: ".git", with: "")
    )
  }
}

extension String {

  fileprivate var nsRange: NSRange {
    NSRange(
      (self.startIndex)..<(self.endIndex),
      in: self
    )
  }
}
