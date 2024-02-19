// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/interpreter/IJSInterpreter.sol';
import '../ast/AstNodeValueUtil.sol';
import './StringUtil.sol';
import './NumberUtil.sol';
import './JSValueUtil.sol';

library JSLiteralUtil {
  using AstNodeValueUtil for IAstBuilder.AstNode;

  /**
   * Make JSValue from literal value node
   * @param literalNode literal node
   * @return JSValue
   */
  function makeLiteralValue(
    IAstBuilder.AstNode calldata literalNode
  ) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory jsValue;
    if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_string)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_string;
      jsValue.value = abi.encode(literalNode.decodeLiteralString());
    } else if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_numberString)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_numberString;
      (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign, string memory value) = literalNode.decodeLiteralNumberString();
      uint num = _readAsInteger(integer, decimal, decimalDigits, exponent, expSign);
      jsValue.value = abi.encode(num, value);
      jsValue.numberSign = sign;
    } else if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_boolean)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_boolean;
      jsValue.value = abi.encode(literalNode.decodeLiteralBoolean());
      jsValue.numberSign = true;
    } else if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_number)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_number;
      (uint integer, uint decimal, uint decimalDigits, uint exponent, bool sign, bool expSign) = literalNode.decodeLiteralNumber();
      uint num = _readAsInteger(integer, decimal, decimalDigits, exponent, expSign);
      jsValue.value = abi.encode(num);
      jsValue.numberSign = sign;
    } else if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_regex)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_regex;
      (string memory pattern, string memory flags) = literalNode.decodeLiteralRegex();
      jsValue.value = abi.encode(pattern, flags);
    } else if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_null)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_null;
      jsValue.numberSign = true;
    } else if (literalNode.nodeDescriptor == uint(IAstBuilder.LiteralValueType.literal_undefined)) {
      jsValue.valueType = IJSInterpreter.JSValueType.value_undefined;
      jsValue.numberSign = true;
    }
    return jsValue;
  }
  
  /**
   * make fixed decimal with 18 digits of decimal part
   * @param integer integer part of the number
   * @param decimal decimal part of the number
   * @param decimalDigits digits of decimal part
   * @param exp exponent value of the number
   * @param expSign sign of the exponent value. true if plus
   * @return fixed decimal value
   */
  function _readAsInteger(uint integer, uint decimal, uint decimalDigits, uint exp, bool expSign) private pure returns (uint) {
    // calc exponent
    uint exponent = JSValueUtil.maxDecimalDigits;
    if (expSign) { // exponent sign
      exponent += exp;
    } else {
      if (exponent >= exp) {
        exponent -= exp;
        expSign = true;
      } else {
        exponent = exp - exponent;
      }
    }
    if (exponent > 0) {
      if (expSign) {
        assembly {
          integer := mul(integer, exp(10, exponent))
        }
        if (decimalDigits > exponent) {
          assembly {
            integer := add(integer, div(decimal, exp(10, sub(decimalDigits, exponent))))
          }
          decimal = 0; // less than 1 wei
        } else if (decimalDigits < exponent) {
          assembly {
            integer := add(integer, mul(decimal, exp(10, sub(exponent, decimalDigits))))
          }
          decimal = 0; // less than 1 wei
        } else {
          integer += decimal;
          decimal = 0;
        }
      } else {
        assembly {
          integer := div(integer, exp(10, exponent))
       }
        if (integer == 0) { // the number is less than 1 wei
          integer = 0;
          decimal = 0;
        } else { // decimal part is less than wei
          decimal = 0; 
        }
      }
    }
    return integer;
  }
}