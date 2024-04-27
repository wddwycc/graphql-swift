/// An exported enum describing the different kinds of tokens that the
/// lexer emits.
public enum TokenKind: String, Decodable {
  case SOF = "<SOF>"
  case EOF = "<EOF>"
  case BANG = "!"
  case DOLLAR = "$"
  case AMP = "&"
  case PAREN_L = "("
  case PAREN_R = ")"
  case SPREAD = "..."
  case COLON = ":"
  case EQUALS = "="
  case AT = "@"
  case BRACKET_L = "["
  case BRACKET_R = "]"
  case BRACE_L = "{"
  case PIPE = "|"
  case BRACE_R = "}"
  case NAME = "Name"
  case INT = "Int"
  case FLOAT = "Float"
  case STRING = "String"
  case BLOCK_STRING = "BlockString"
  case COMMENT = "Comment"
}

public struct Token: Decodable {
  /**
    * The kind of Token.
    */
  let kind: TokenKind
  /**
     * For non-punctuation tokens, represents the interpreted value of the token.
     *
     * Note: is undefined for punctuation tokens, but typed as string for
     * convenience in the parser.
     */
  let value: String
  /**
     * The 1-indexed line number on which this Token appears.
     */
  let line: UInt
  /**
     * The 1-indexed column number at which this Token begins.
     */
  let column: UInt
}
