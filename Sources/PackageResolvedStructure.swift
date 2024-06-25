import Foundation

/// The parts from the structure of a SPM `Package.resolved` file that we are interested in.
struct PackageResolvedStructure: Decodable {

  let pins: [PinStructure]
  let version: Int

  struct PinStructure: Decodable {
    /// The name of the package.
    let identity: String
    /// The source of the package. For us, this will most often be a remote (e.g. GitHub) url.
    let location: String
  }
}
