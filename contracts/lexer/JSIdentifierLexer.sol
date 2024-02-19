// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../utils/Log.sol";
import '../interfaces/lexer/IJSIdentifierLexer.sol';
import '../interfaces/lexer/IJSNumberLexer.sol';
import '../utf8/Utf8.sol';
import '../utf8/Utf8Char.sol';
import './TokenAttrsUtil.sol';

/**
 * The lexer for identifier tokens.
 */
contract JSIdentifierLexer is IJSIdentifierLexer {
  IJSNumberLexer numberLexer;

  constructor(IJSNumberLexer _numberLexer) {
    numberLexer = _numberLexer;
  }

  /**
   * extract a identifier token.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The identifier token.
   */
  function readIdentifierToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external view override returns (IJSLexer.Token memory) {
    uint currentPos = context.currentPos;
    uint chunkStart = context.currentPos;
    string memory value = '';

    while (currentPos < context.eofPos) {
      IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, currentPos);
      if (char.code == 0x5C) { // backSlash
        value = string.concat(value, string(source[chunkStart:currentPos]));
        IJSLexer.TokenAttrs memory numberAttrs = numberLexer.readInteger(source, context, currentPos);
        (uint integer,,,,,,) = TokenAttrsUtil.decodeNumberValue(numberAttrs);
        IUtf8Char.Utf8Char memory resolvedChar = Utf8Char.getByCode(integer);
        if (resolvedChar.size > 0) {
          if (currentPos == context.currentPos) {
            require(this.isIdentifierStart(resolvedChar.code), 'invalid escaped char');
          } else {
            require(this.isIdentifier(resolvedChar.code), 'invalid escaped char');
          }
          value = string.concat(value, resolvedChar.expression);
        }
        currentPos += numberAttrs.size;
        chunkStart = currentPos;
      } else if (this.isIdentifier(char.code) || char.code == 0x40) { // atMark
        currentPos += char.size;
      } else {
        break;
      }
    }

    value = string.concat(value, string(source[chunkStart:currentPos]));
    
    return _createToken(
      string(source[context.currentPos:currentPos]),
      value,
      currentPos - context.currentPos,
      context
    );
  }

  /**
   * determine whether the code can be used in identifier
   * @param code character code
   * @return Return true if it can.
   * @notice only ascii characters are supported
   */
  function isIdentifier(uint code) external pure returns (bool) {
    if (code < 0x30) { // zero
      return code == 0x24; // dollarSign
    }
    if (code < 0x3A) { // colon
      return true;
    }
    if (code < 0x41) { // A
      return false;
    }
    if (code <= 0x5A) { // Z
      return true;
    }
    if (code < 0x61) { // a
      return code == 0x5F; // underscore
    }
    if (code <= 0x7A) { // z
      return true;
    }
    return false;
  }

  /**
   * Determine whether the character code can be used as the first character in an identifier.
   * @param code character code.
   * @return Return true if it can.
   * @notice only ascii characters are supported
   */
  function isIdentifierStart(uint code) external pure returns (bool) {
    if (code < 0x41) { // A
      return code == 0x24; // dollarSign
    }
    if (code <= 0x5A) { // Z
      return true;
    }
    if (code < 0x61) { // a
      return code == 0x5F; // underscore
    }
    if (code <= 0x7A) { // z
      return true;
    }
    return false;
  }
  
  /**
   * create a identifier token
   * @param expression raw expression in source code
   * @param value identifier value
   * @param size bytes length of identifier
   * @param context Tokenization context.
   * @return the identifier token
   */
  function _createToken(
    string memory expression,
    string memory value,
    uint size,
    IJSLexer.Context memory context
  ) internal pure returns (IJSLexer.Token memory) {
    IJSLexer.TokenAttrs memory attrs = IJSLexer.TokenAttrs({
      value: abi.encode(value, expression), // store as bytes. use TokenAttrsUtil.decodeIdentifierValue for decode.
      tokenType: IJSLexer.TokenType.identifier,
      tokenCode: 0,
      size: size,
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