// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../utils/Log.sol";
import '../interfaces/lexer/IJSRegexLexer.sol';
import '../interfaces/lexer/IJSIdentifierLexer.sol';
import '../utf8/Utf8.sol';

/**
 * The lexer for regex tokens.
 */
contract JSRegexLexer is IJSRegexLexer {
  IJSIdentifierLexer identifier;

  constructor(IJSIdentifierLexer _identifier) {
    identifier = _identifier;
  }

  /**
   * extract a regex token
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The regex token.
   */
  function readRegexToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) external view returns (IJSLexer.Token memory) {
    console.log('readRegexToken');
    uint currentPos = context.currentPos + 1;
    // read pattern
    bool inEscape = false;
    bool inClass = false;
    while (currentPos < context.eofPos) {
      IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, currentPos);
      require(!Utf8.isNewLine(char.code), 'regex not terminated');
      if (inEscape) {
        inEscape = false;
      } else {
        if (char.code == 0x5B) { // leftSquareBracket
          inClass = true;
        } else if (char.code == 0x5D && inClass) { // rightSquareBracket
          inClass = false;
        } else if (char.code == 0x2F && !inClass) { // slash
          currentPos += char.size;
          break;
        } else if (char.code == 0x5C) { // backSlash
          inEscape = true;
        }
      }
      currentPos += char.size;
    }
    // read flags
    uint flagStartPos = currentPos;
    uint flags = 0;
    while (currentPos < context.eofPos) {
      IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, currentPos);
      if (
        char.code == 0x64 || // d
        char.code == 0x67 || // g
        char.code == 0x69 || // i
        char.code == 0x6D || // m
        char.code == 0x73 || // s
        char.code == 0x75 || // u
        char.code == 0x79 // y
      ) {
        require((flags & char.code) != char.code, 'dup regex flag');
      } else {
        require(!identifier.isIdentifier(char.code) && char.code != 0x5C, 'invalid flags');
        break;
      }
      flags |= char.code;
      currentPos += char.size;
    }

    require(context.currentPos + 1 <= currentPos || context.currentPos + 1 <= flagStartPos - 1, 'invalid reg');

    IJSLexer.TokenAttrs memory attrs = IJSLexer.TokenAttrs({
      value: abi.encode(
        string(source[context.currentPos:currentPos]),
        string(source[context.currentPos + 1:flagStartPos - 1]),
        string(source[flagStartPos:currentPos])
      ),
      tokenType: IJSLexer.TokenType.regex,
      tokenCode: 0,
      size: currentPos - context.currentPos + 1,
      allowFollowingRegex: false
    });
    return IJSLexer.Token({
      attrs: attrs,
      startPos: context.currentPos,
      endPos: context.currentPos + attrs.size - 1,
      line: context.currentLine
    });
  }
}