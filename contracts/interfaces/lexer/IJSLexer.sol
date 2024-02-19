// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * The interface to tokenize the source code.
 */
interface IJSLexer {
  enum TokenType {
    invalid, // 0
    keyword, // 1
    punctuation, // 2
    operator, // 3
    identifier, // 4
    number, // 5
    bigInt, // 6
    str, // 7
    numberStr, // 8
    regex, // 9
    comment, // 10
    start // 11
  }

  struct TokenAttrs {
    /*
      abi encoded value data. the included data is as follows according to the token type.
      To decode, use decoder methods of TokenAttrsUtil.

      identifier token =>
        value(string): identifier value
        expression(string): raw value in source code
      keyword token =>
        keyword(string): keyword value
      number token =>
        integer(uint): integer part of the number
        decimal(uint): decimal part of the number
        decimalDigits(uint): digits of decimal part
        expoenent(uint): exponent value of the number
        sign(bool): sign of the number. true if plus
        expSign(bool): sign of the exponent value. true if plus
        expression(string): raw value in source code
      operator token =>
        operator(string): operator type
      punctuation token =>
        punctuation(string): punctuation value
      regex token =>
        regexPattern(string): regex pattern expression
        regexFlags(string): regex flags
        expression(string): raw value in source code
      string token =>
        value(string): string value
        expression(string): raw value in source code
      number string token =>
        integer(uint): integer part of the number
        decimal(uint): decimal part of the number
        decimalDigits(uint): digits of decimal part
        expoenent(uint): exponent value of the number
        sign(bool): sign of the number. true if plus
        expSign(bool): sign of the exponent value. true if plus
        value(string): string value
        expression(string): raw value in source code
      comment token =>
        value(string): comment value
    */
    bytes value;
    // internal code for identifying subtypes of token type
    uint tokenCode;
    // byte size oppcupied by the token in source code. not the length of 'value'.
    uint size;
    // flag indicating wheter regular expression can be followed after this token.
    bool allowFollowingRegex;
    TokenType tokenType;
  }

  struct Token {
    TokenAttrs attrs;
    // starting position in source code byte array
    uint startPos;
    // end position in source code byte array
    uint endPos;
    // line number of this token
    uint line;
  }

  // tokenization context 
  struct Context {
    // current position in source code byte array
    uint currentPos;
    // current line number
    uint currentLine;
    // end position of source code byte array
    uint eofPos;
    // flag indicating wheter regular expression can be followed as next token.
    bool allowFollowingRegex;
  }

  // tokenization configuration
  struct Config {
    // if true, comment token will not be included in return value.
    bool ignoreComment;
  }
  
  /**
   * Tokenize the source code.
   * @param code source code
   * @param config tokenization configuration
   * @return token array
   */
  function tokenize(string calldata code, Config calldata config) external view returns (Token[] memory);
}