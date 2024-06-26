import Foundation

struct GitHubClient {

  let getLicenseContent: (_ packageInfo: GitHubPackageInfo) async throws -> String
}

// MARK: - Live GitHubClient Implementation
@available(macOS 10.15, *)
extension GitHubClient {

  enum LiveClientError: LocalizedError {

    case couldNotMakeURL(repoName: String)
    case responseNot200(repoName: String, statusCode: Int)
    case couldNotEncodeToBase64(repoName: String)
    case couldNotDecodeFromBase64(repoName: String)

    var errorDescription: String? {
      switch self {
      case .couldNotMakeURL(let repoName):
        "Could not make URL for \(repoName)"
      case .responseNot200(let repoName, let statusCode):
        "Got status code \(statusCode) for \(repoName). Please try adding an access token."
      case .couldNotEncodeToBase64(let repoName):
        "Could not encode to Base64 for \(repoName)"
      case .couldNotDecodeFromBase64(let repoName):
        "Could not decode license from Base64 for \(repoName)"
      }
    }
  }

  struct GitHubAPIResponse: Decodable {
    var content: String
  }

  /// - Parameter token: A [GitHub token](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api?apiVersion=2022-11-28#about-authentication) to get past rate limiting.
  /// - Returns: A live ``GitHubClient``.
  ///
  /// * [Documentation for the relevant endpoint.](https://docs.github.com/en/rest/licenses/licenses?apiVersion=2022-11-28#get-the-license-for-a-repository)
  static func live(token: String?) -> Self {
    .init(
      getLicenseContent: { packageInfo in
        let repoName = packageInfo.fullPackageName
        // Get the endpoint URL
        guard let url = URL(string: "https://api.github.com/repos/\(repoName)/license") else {
          throw LiveClientError.couldNotMakeURL(repoName: repoName)
        }
        // Create a URLRequest for the endpoint, and add recommended headers
        var request = URLRequest(url: url)
        request.addValue(
          "application/vnd.github+json",
          forHTTPHeaderField: "accept"
        )
        request.addValue(
          "2022-11-28",
          forHTTPHeaderField: "X-GitHub-Api-Version"
        )
        // Add token, if applicable
        if let token {
          request.addValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
          )
        }
        // Get data returned from the API
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
          guard httpResponse.statusCode == 200 else {
            throw LiveClientError.responseNot200(
              repoName: repoName, statusCode: httpResponse.statusCode)
          }
        }
        // Decode the JSON response
        let apiResponse = try JSONDecoder().decode(GitHubAPIResponse.self, from: data)
        // The license content will be Base64. We will encode a `Data` instance from the content.
        let base64Data = Data(
          base64Encoded: apiResponse.content,
          options: .ignoreUnknownCharacters
        )
        guard let base64Data else {
          throw LiveClientError.couldNotEncodeToBase64(repoName: repoName)
        }
        // Decode from Base64 to get the license string.
        guard let stringFromBase64 = String(data: base64Data, encoding: .utf8) else {
          throw LiveClientError.couldNotDecodeFromBase64(repoName: repoName)
        }

        return stringFromBase64
      }
    )
  }
}
