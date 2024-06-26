import Foundation

/// Type-erased wrapper over `Encodable`.
///
/// Taken from https://forums.swift.org/t/serializing-a-dictionary-with-any-codable-values/16676/8.
struct AnyEncodable: Encodable {

  private let _encode: (Encoder) throws -> Void

  public init<T: Encodable>(_ wrapped: T) {
    _encode = wrapped.encode
  }

  func encode(to encoder: Encoder) throws {
    try _encode(encoder)
  }
}
