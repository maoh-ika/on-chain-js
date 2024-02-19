// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/ast/IAstBuilder.sol';

library AstNodeValueUtil {
  /**
   * decode string literal value
   * @param node string literal node
   * @return value string value
   */
  function decodeLiteralString(IAstBuilder.AstNode memory node) internal pure returns (string memory value) {
    value = abi.decode(node.value, (string));
  }
  
  /**
   * decode number literal value
   * @param node number literal node
   * @return integer integer part of the number
   * @return decimal decimal part of the number
   * @return decimalDigits digits of decimal part
   * @return exponent exponent value of the number
   * @return sign sign of the number. true if plus
   * @return expSign sign of the exponent value. true if plus
   */
  function decodeLiteralNumber(
    IAstBuilder.AstNode memory node
  ) internal pure returns (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign) {
    (integer, decimal, decimalDigits, exponent, sign, expSign) = abi.decode(node.value, (uint, uint, uint, uint, bool, bool));
  }

  /**
   * decode number string literal value
   * @param node number literal node
   * @return integer integer part of the number
   * @return decimal decimal part of the number
   * @return decimalDigits digits of decimal part
   * @return exponent exponent value of the number
   * @return sign sign of the number. true if plus
   * @return expSign sign of the exponent value. true if plus
   * @return value string value
   */
  function decodeLiteralNumberString(
    IAstBuilder.AstNode memory node
  ) internal pure returns (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign, string memory value) {
    (integer, decimal, decimalDigits, exponent, sign, expSign, value) = abi.decode(node.value, (uint, uint, uint, uint, bool, bool, string));
  }
  
  /**
   * decode bool literal value
   * @param node bool literal node
   * @return value bool value
   */
  function decodeLiteralBoolean(IAstBuilder.AstNode memory node) internal pure returns (bool value) {
    value = abi.decode(node.value, (bool));
  }
  
  /**
   * decode regex literal value
   * @param node bool literal node
   * @return pattern regex pattern expression
   * @return flags regex flags
   */
  function decodeLiteralRegex(IAstBuilder.AstNode memory node) internal pure returns (string memory pattern, string memory flags) {
    (pattern, flags) = abi.decode(node.value, (string, string));
  }
}