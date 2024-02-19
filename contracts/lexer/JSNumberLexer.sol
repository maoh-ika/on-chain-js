// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../utils/Log.sol";
import '../interfaces/lexer/IJSNumberLexer.sol';
import '../utf8/Utf8.sol';

/**
 * The lexer for number tokens.
 */
contract JSNumberLexer is IJSNumberLexer {
  /**
   * extract a number token assuming positive value
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The number token.
   */
  function readNumberToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) external pure returns (IJSLexer.Token memory) {
    return _readNumberToken(source, context, context.currentPos);
  }

  /**
   * implementation of readNumberToken
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param startPos starting position in source bytes.
   * @return The number token.
   */
  function _readNumberToken(
    bytes calldata source,
    IJSLexer.Context memory context,
    uint startPos
  ) private pure returns (IJSLexer.Token memory) {
    //console.log('_readNumber');
    IJSLexer.TokenAttrs memory intAttrs;
    IJSLexer.TokenAttrs memory decimalAttrs;
    IJSLexer.TokenAttrs memory expnentAttrs;
    uint currentPos = startPos;

    // read integer part
    intAttrs = _readInteger(source, context, currentPos, true);
    currentPos += intAttrs.size;

    // read decimal part
    IUtf8Char.Utf8Char memory dotChar = Utf8.getNextCharacter(source, currentPos);
    if (dotChar.code == 0x2E) { // dot, test float
      currentPos += dotChar.size;
      decimalAttrs = _readInteger(source, context, currentPos, false);
      currentPos += decimalAttrs.size;
    }

    // read exponent part
    bool expSign = true;
    IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, currentPos);
    if (char.code == 0x65 || char.code == 0x45) { // e, E
      // read exponent sign
      currentPos += char.size;
      char = Utf8.getNextCharacter(source, currentPos);
      if (char.code == 0x2D) { // minusSign
        expSign = false;
        currentPos += char.size;
      } else if (char.code == 0x2B) { // plusSign
        expSign = true;
        currentPos += char.size;
      }
      // read exponent value
      expnentAttrs = _readInteger(source, context, currentPos, true);
      currentPos += expnentAttrs.size;
      char = Utf8.getNextCharacter(source, currentPos);
      require(char.code != 0x2E && char.code != 0x6E, 'exponent must be integer');
    }
    
    // read bigint part
    (uint integer,,,,,,) = TokenAttrsUtil.decodeNumberValue(intAttrs);
    char = Utf8.getNextCharacter(source, currentPos);
    if (char.code == 0x6E) { // n
      require(expnentAttrs.size == 0 && decimalAttrs.size == 0, 'invalid bigint');
      currentPos += char.size;
      IJSLexer.TokenAttrs memory bigIntAttrs = _createBigIntAttrs(string(source[context.currentPos:currentPos]), integer, true);
      return _createToken(bigIntAttrs, context);
    } else {
      uint decimal;
      uint decimalDigits;
      if (decimalAttrs.size > 0) {
        (decimal,,,,,,) = TokenAttrsUtil.decodeNumberValue(decimalAttrs);
        decimalDigits = decimalAttrs.size;
      }
      uint exponent;
      if (expnentAttrs.size > 0) {
        (exponent,,,,,,) = TokenAttrsUtil.decodeNumberValue(expnentAttrs);
      }
      IJSLexer.TokenAttrs memory attrs = _createNumberAttrs(string(source[context.currentPos:currentPos]), integer, decimal, decimalDigits, exponent, true, expSign);
      return _createToken(attrs, context);
    }
  }
  
  /**
   * extract a number token assuming negative value
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The number token.
   */
  function readMinusNumberToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) external view returns (IJSLexer.Token memory) {
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, context.currentPos + 1);
    IJSLexer.Token memory token;
    if (nextChar.code == 0x30) { // 0
      ++context.currentPos;
      token = this.readZeroToken(source, context);
    } else if (Utf8.isDigit(nextChar.code)) {
      ++context.currentPos;
      token = _readNumberToken(source, context, context.currentPos);
    } else {
      revert('syntax error');
    }
    (uint integer, uint decimal, uint decimalDigits, uint exponent,,bool expSign, string memory expression) = TokenAttrsUtil.decodeNumberValue(token.attrs);
    return _createToken(
      _createNumberAttrs(
        string.concat('-', expression),
        integer,
        decimal,
        decimalDigits,
        exponent,
        false,
        expSign),
        context);
  }
  
  /**
   * extract a number token assuming it starts with zero
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The number token.
   */
  function readZeroToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external pure returns (IJSLexer.Token memory) {
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, context.currentPos + 1);
    if (nextChar.code == 0x2E || nextChar.code == 0x65 || nextChar.code == 0x45) { // dot, e, E
      return _readNumberToken(source, context, context.currentPos);
    } else if (
      nextChar.code == 0x78 || nextChar.code == 0x58 || // x, X
      nextChar.code == 0x6F || nextChar.code == 0x4F || // o, O
      nextChar.code == 0x62 || nextChar.code == 0x42 // b, B
    ) {
      return _readRadixToken(source, context);
    } else {
      return _readOctalToken(source, context);
    }
  }

  /**
   * Read a integer value.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param startPos starting position in the byte array.
   * @return integer attributes.
   */
  function readInteger(
    bytes calldata source,
    IJSLexer.Context memory context,
    uint startPos
  ) external pure override returns (IJSLexer.TokenAttrs memory) {
    return _readInteger(source, context, startPos, true);
  }
  
  /**
   * Implementation of readInteger.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param startPos starting position in the byte array.
   * @param enableOctalLiteral if false, ignore octal literal and parse as decimal number.
   * @return integer attributes.
   */
  function _readInteger(
    bytes calldata source,
    IJSLexer.Context memory context,
    uint startPos,
    bool enableOctalLiteral
  ) private pure returns (IJSLexer.TokenAttrs memory) {
    //console.log('_readInteger');
    uint total = 0;
    uint endPos = startPos;
    IUtf8Char.Utf8Char memory char = Utf8.getNextCharacter(source, startPos);
    if (char.code == 0x30) { // 0
      char = Utf8.getNextCharacter(source, startPos + 1);
      if (char.code == 0x78 || char.code == 0x58) { // x, X. hex number
        (total, endPos) = _readTotalNumber(source, context, startPos + 2, 16, false);
      } else if (char.code == 0x6F || char.code == 0x4F) { // o, O. octal number
        (total, endPos) = _readTotalNumber(source, context, startPos + 2, 8, false);
      } else if (enableOctalLiteral && Utf8.isDigit(char.code)) {
        (total, endPos) = _readTotalNumber(source, context, startPos + 1, 8, false);
      } else if (char.code == 0x62 || char.code == 0x42) { // b, B. binary number
        (total, endPos) = _readTotalNumber(source, context, startPos + 2, 2, false);
      } else { // decimal number
        (total, endPos) = _readTotalNumber(source, context, startPos, 10, false);
      }
    } else if (char.code == 0x5C) { // backSlash, escape sequence
      require(Utf8.getNextCharacter(source, startPos + 1).code == 0x75, 'invalid escape'); // u
      uint pos = startPos + (Utf8.getNextCharacter(source, startPos + 2).code == 0x7B /* leftCurlyBrace */ ? 3 : 2);
      (total, endPos) = _readTotalNumber(source, context, pos, 16, true);
    } else {
      (total, endPos) = _readTotalNumber(source, context, startPos, 10, false);
    }
    return _createNumberAttrs(string(source[startPos:endPos]), total, 0, 0, 0, true, true);
  }
  
  /**
   * Extract radix number token.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readRadixToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) private pure returns (IJSLexer.Token memory) {
    //console.log('_readRadixToken');
    IJSLexer.TokenAttrs memory attrs = _readInteger(source, context, context.currentPos, true);
    uint nextPos = context.currentPos + attrs.size;
    IUtf8Char.Utf8Char memory nextChar = Utf8.getNextCharacter(source, nextPos);
    if (nextChar.code == 0x6E) { // n. big number
      (uint integer,,,,,,string memory expression) = TokenAttrsUtil.decodeNumberValue(attrs);
      IJSLexer.TokenAttrs memory bigIntAttrs = _createBigIntAttrs(expression, integer, true);
      return _createToken(bigIntAttrs, context);
    } else {
      return _createToken(attrs, context);
    }
  }

  /**
   * Extract octal number token.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The token.
   */
  function _readOctalToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) private pure returns (IJSLexer.Token memory) {
    uint currentPos = context.currentPos;
    IUtf8Char.Utf8Char memory zeroChar = Utf8.getNextCharacter(source, currentPos);
    require(zeroChar.code == 0x30, 'octal must start with 0');
    IJSLexer.TokenAttrs memory octalAttrs = _readInteger(source, context, currentPos, true);
    return _createToken(octalAttrs, context);
  }

  /**
   * Parse string and convert to number based on radix
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param startPos starting position in source bytes.
   * @param radix radix type
   * @param isEscape if true, in escaped string
   * @return The token.
   */
  function _readTotalNumber(
    bytes calldata source,
    IJSLexer.Context memory context,
    uint startPos,
    uint radix,
    bool isEscape
  ) private pure returns (uint, uint) {
    uint total = 0;
    uint pos = startPos;
    IUtf8Char.Utf8Char memory char;
    while (pos < context.eofPos) {
      char = Utf8.getNextCharacter(source, pos);
      uint value = 0;
      if (radix == 16 && 0x61 <= char.code && char.code <= 0x66) { // a - f
        value = char.code - 0x61 + 10;
      } else if (radix == 16 && 0x41 <= char.code&& char.code <= 0x46) { // A - F
        value = char.code - 0x41 + 10;
      } else if (Utf8.isDigit(char.code)) {
        if (radix == 2 && char.code > 0x31) {
          revert('invalid binary');
        } else if (radix == 8 && char.code > 0x37) {
          revert('invalid octal');
        }
        value = char.code - 0x30; // 0
      } else {
        if (isEscape && char.code == 0x7D) { // rightCurlyBrace
          pos++;
        }
        break;
      }
      total = total * radix + value;
      pos += char.size;
    }
    return (total, pos);
  }

  /**
   * Create token attributes
   * @param expression bytes sequence of source code.
   * @param integer integer part of the number
   * @param decimal decimal part of the number
   * @param decimalDigits digits of decimal part
   * @param exponent exponent value of the number
   * @param sign sign of the number. true if plus
   * @param expSign sign of the exponent value. true if plus
   * @param tokenType token type
   * @param size bytes size of the token in the source code
   * @return The token.
   */
  function _createTokenAttrs(
    string memory expression,
    uint integer,
    uint decimal,
    uint decimalDigits,
    uint exponent,
    bool sign,
    bool expSign,
    IJSLexer.TokenType tokenType,
    uint size
  ) private pure returns (IJSLexer.TokenAttrs memory) {
    return IJSLexer.TokenAttrs({
      value: abi.encode(integer, decimal, decimalDigits, exponent, sign, expSign, expression), // encode into bytes. use TokenAttrsUtil.decodeNumberValue for decode
      size: size,
      tokenCode: 0,
      allowFollowingRegex: false,
      tokenType: tokenType
    });
  }

  /**
   * Create number token attributes
   * @param expression bytes sequence of source code.
   * @param integer integer part of the number
   * @param decimal decimal part of the number
   * @param decimalDigits digits of decimal part
   * @param exponent exponent value of the number
   * @param sign sign of the number. true if plus
   * @param expSign sign of the exponent value. true if plus
   * @return The token attributes.
   */
  function _createNumberAttrs(
    string memory expression,
    uint integer,
    uint decimal,
    uint decimalDigits,
    uint exponent,
    bool sign,
    bool expSign
  ) private pure returns (IJSLexer.TokenAttrs memory) {
    uint size = uint(bytes(expression).length);
    return _createTokenAttrs(expression, integer, decimal, decimalDigits, exponent, sign, expSign, IJSLexer.TokenType.number, size);
  }
  
  /**
   * Create bigint token attributes
   * @param expression bytes sequence of source code.
   * @param integer integer part of the number
   * @param sign sign of the number. true if plus
   * @return The token attributes.
   */
  function _createBigIntAttrs(string memory expression, uint integer, bool sign) private pure returns (IJSLexer.TokenAttrs memory) {
    uint size = uint(bytes(expression).length);
    return _createTokenAttrs(expression, integer, 0, 0, 0, sign, true, IJSLexer.TokenType.bigInt, size);
  }
  
  /**
   * Create a token 
   * @param attrs token attributes
   * @param context Tokenization context.
   * @return The token.
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
