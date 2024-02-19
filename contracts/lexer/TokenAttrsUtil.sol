// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/lexer/IJSLexer.sol';

library TokenAttrsUtil {
  /**
   * decode identifier token value
   * @param attrs token attributes
   * @return value identifier value
   * @return expression raw value in source code
   */
  function decodeIdentifierValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (string memory value, string memory expression) {
    (value, expression) = abi.decode(attrs.value, (string, string));
  }
  
  /**
   * decode keyword token value
   * @param attrs token attributes
   * @return keyword keyword value
   */
  function decodeKeywordValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (string memory keyword) {
    keyword = abi.decode(attrs.value, (string));
  }
  
  /**
   * decode number token value
   * @param attrs token attributes
   * @return integer integer part of the number
   * @return decimal decimal part of the number
   * @return decimalDigits digits of decimal part
   * @return exponent exponent value of the number
   * @return sign sign of the number. true if plus
   * @return expSign sign of the exponent value. true if plus
   * @return expression raw value in source code
   */
  function decodeNumberValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign, string memory expression) {
    (integer, decimal, decimalDigits, exponent, sign, expSign, expression) = abi.decode(attrs.value, (uint, uint, uint, uint, bool, bool, string));
  }
  
  /**
   * decode operator token value
   * @param attrs token attributes
   * @return operator operator value
   */
  function decodeOperatorValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (string memory operator) {
    operator = abi.decode(attrs.value, (string));
  }
  
  /**
   * decode punctuation token value
   * @param attrs token attributes
   * @return punctuation punctuation value
   */
  function decodePunctuationValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (string memory punctuation) {
    punctuation = abi.decode(attrs.value, (string));
  }
  
  /**
   * decode regex token value
   * @param attrs token attributes
   * @return pattern regex pattern expression
   * @return flags regex flags
   * @return expression raw value in source code
   */
  function decodeRegexValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (string memory pattern, string memory flags, string memory expression) {
    (pattern, flags, expression) = abi.decode(attrs.value, (string, string, string));
  }
  
  /**
   * decode string token value
   * @param attrs token attributes
   * @return value string value
   * @return expression raw value in source code
   */
  function decodeStringValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (string memory value, string memory expression) {
    (value, expression) = abi.decode(attrs.value, (string, string));
  }
  
  /**
   * decode number string token value
   * @param attrs token attributes
   * @return integer integer part of the number
   * @return decimal decimal part of the number
   * @return decimalDigits digits of decimal part
   * @return exponent exponent value of the number
   * @return sign sign of the number. true if plus
   * @return expSign sign of the exponent value. true if plus
   * @return value string value
   * @return expression raw value in source code
   */
  function decodeNumberStringValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (
    uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign, string memory value, string memory expression) {
    (integer, decimal, decimalDigits, exponent, sign, expSign, value, expression) = abi.decode(attrs.value, (uint, uint, uint, uint, bool, bool, string, string));
  }
  
  /**
   * decode comment token value
   * @param attrs token attributes
   * @return value comment value
   */
  function decodeCommentValue(
    IJSLexer.TokenAttrs memory attrs
  ) internal pure returns (string memory value) {
    value = abi.decode(attrs.value, (string));
  }
}