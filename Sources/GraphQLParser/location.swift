/// Contains a range of UTF-8 character offsets and token references that
/// identify the region of the source from which the AST derived.
public struct Location: Decodable {
  /**
   * The character offset at which this Node begins.
   */
  let start: UInt

  /**
   * The character offset at which this Node ends.
   */
  let end: UInt
}
