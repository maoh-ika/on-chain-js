// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../utils/Log.sol";
import '../interfaces/lexer/IJSStringLexer.sol';
import { IJSNumberLexer } from '../interfaces/lexer/IJSNumberLexer.sol';
import { IJSIdentifierLexer } from '../interfaces/lexer/IJSIdentifierLexer.sol';
import '../utf8/Utf8.sol';
import './SkipUtil.sol';

/**
 * The lexer for string tokens.
 */
contract JSStringLexer is IJSStringLexer {
  IJSNumberLexer numberLexer;
  IJSIdentifierLexer identifierLexer;

  constructor(
    IJSNumberLexer _numberLexer,
    IJSIdentifierLexer _identifierLexer
  ) {
    numberLexer = _numberLexer;
    identifierLexer = _identifierLexer;
  }

  /**
   * extract a string token starting with ampersand 
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param quote quote character enclosing the string.
   * @return The string token.
   */
  function readStringToken(
    bytes calldata source,
    IJSLexer.Context memory context,
    IUtf8Char.Utf8Char calldata quote
  ) external view returns (IJSLexer.Token memory) {
    uint currentPos = context.currentPos + quote.size;
    bool inEscape = false;
    while (currentPos < context.eofPos) {
      IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, currentPos);
      if (char.code == quote.code && !inEscape) {
        break;
      } else if (char.code == 0x5C) { // backSlash
        inEscape = !inEscape;
        currentPos += char.size;
        char = Utf8.getNextCharacter(source, currentPos);
        if (char.code == 0x0d) { // carriageReturn
          currentPos += char.size;
          char = Utf8.getNextCharacter(source, currentPos);
          if (char.code == 0x0a) { // lineFeed
            context.currentLine++;
          } else {
            revert();
          }
          currentPos += char.size;
        } else if (char.code == 0x0a) {
          context.currentLine++;
          currentPos += char.size;
        }
      } else if (char.code == 0xE280A8 || char.code == 0xE280A9) { // lineSeparator, paragraphSeparator
        context.currentLine++;
        currentPos += char.size;
      } else if (quote.code == 0x60 && char.code == 0x0d) { // CR
        currentPos += char.size;
        char = Utf8.getNextCharacter(source, currentPos);
        if (char.code == 0x0a) { // lineFeed
          context.currentLine++;
        }
        currentPos += char.size;
      } else if (quote.code == 0x60 && char.code == 0x0a) { // LF
        context.currentLine++;
        currentPos += char.size;
      } else {
        inEscape = false;
        require(char.size > 0, 'unknown char');
        require(!Utf8.isNewLine(char.code), 'unterminated string');
        currentPos += char.size;
      }
    }
    require(currentPos < context.eofPos, 'unterminated string');
    
    bytes memory value = source[context.currentPos + 1:currentPos];
    bytes memory expr = source[context.currentPos:currentPos + 1];
    uint size = currentPos - context.currentPos + 1;
    IJSLexer.Token memory numberToken = _readAsNumber(source, context, context.currentPos + 1, currentPos);
    if (numberToken.attrs.tokenType == IJSLexer.TokenType.number) {
      return _createToken(_createStringAttrs(string(expr), string(value), size, numberToken), context);
    } else {
      return _createToken(_createStringAttrs(string(expr), string(value), size), context);
    }
  }
  
  /**
   * Read string as number
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param startPos starting position in source bytes array.
   * @param endPos last element position of source bytes array.
   * @return The string token.
   */
  function _readAsNumber(
    bytes calldata source,
    IJSLexer.Context memory context,
    uint startPos,
    uint endPos
  ) private view returns (IJSLexer.Token memory) {
    IJSLexer.Context memory strContext = IJSLexer.Context({
      currentPos: startPos,
      currentLine: context.currentLine,
      eofPos: context.eofPos,
      allowFollowingRegex: context.allowFollowingRegex
    });

    SkipUtil.skipSpaces(source, strContext);
    IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, strContext.currentPos);
    IJSLexer.Token memory token;
    if (char.code == 0x30) { // 0
      token = numberLexer.readZeroToken(source, strContext);
    } else if (Utf8.isDigit(char.code)) {
      token = numberLexer.readNumberToken(source, strContext);
    } else if (char.code == 0x2D) { // minusSign
      IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, strContext.currentPos + 1);
      if (nextChar.code == 0x30 || Utf8.isDigit(nextChar.code)) {
        token = numberLexer.readMinusNumberToken(source, strContext);
      }
    } else if (char.code == 0x2E) { // dot
      IUtf8Char.Utf8Char memory nextDotChar = Utf8.getNextCharacter(source, strContext.currentPos + 1);
      if (0x30 <= nextDotChar.code && nextDotChar.code <= 0x39) { // 0 - 9
        return numberLexer.readNumberToken(source, strContext);
      }
    } else if (strContext.currentPos == endPos) {
      return IJSLexer.Token({
         attrs: IJSLexer.TokenAttrs({
           value: abi.encode(0, 0, 0, 0, true, true, ''),
           tokenType: IJSLexer.TokenType.number,
           tokenCode: 0,
           size: 1,
           allowFollowingRegex: false
         }),
         startPos: startPos,
         endPos: endPos,
         line: context.currentLine
       });
    }

    return token;
  }

  /**
   * create string token attributes
   * @param expression raw expression in source code
   * @param value string value
   * @param size string size in bytes
   * @return The string token attributes.
   */
  function _createStringAttrs(string memory expression, string memory value, uint size) private pure returns (IJSLexer.TokenAttrs memory) {
    return IJSLexer.TokenAttrs({
      value: abi.encode(value, expression), // encode into bytes. use TokenAttrsUtil.decodeStringValue for decode
      tokenType: IJSLexer.TokenType.str,
      tokenCode: 0,
      size: size,
      allowFollowingRegex: false
    });
  }

  /**
   * create number string token attributes
   * @param expression raw expression in source code
   * @param value string value
   * @param size string size in bytes
   * @param numberToken number token
   * @return The string token attributes.
   */
  function _createStringAttrs(string memory expression, string memory value, uint size, IJSLexer.Token memory numberToken) private pure returns (IJSLexer.TokenAttrs memory) {
    (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign,)= TokenAttrsUtil.decodeNumberValue(numberToken.attrs);
    return IJSLexer.TokenAttrs({
      // encode into bytes. use TokenAttrsUtil.decodeNumberStringValue for decode
      value: abi.encode(
        integer,
        decimal,
        decimalDigits,
        exponent,
        sign,
        expSign,
        value,
        expression
      ),
      tokenType: IJSLexer.TokenType.numberStr,
      tokenCode: 0,
      size: size,
      allowFollowingRegex: false
    });
  }

  /**
   * create string token
   * @param attrs token attributes
   * @param context Tokenization context
   * @return The string token
   */
  function _createToken(IJSLexer.TokenAttrs memory attrs, IJSLexer.Context memory context) internal pure returns (IJSLexer.Token memory) {
    return IJSLexer.Token({
      attrs: attrs,
      startPos: context.currentPos,
      endPos: context.currentPos + attrs.size - 1,
      line: context.currentLine
    });
  }
}