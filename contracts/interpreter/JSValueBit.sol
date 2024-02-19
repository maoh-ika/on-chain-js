// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/interpreter/IJSInterpreter.sol';
import './StringUtil.sol';
import './JSValueUtil.sol';
import './JSValueOp.sol';

library JSValueBit {
  using StringUtil for string;
  using JSValueUtil for IJSInterpreter.JSValue;

  /**
   * Implement left shift operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function leftShift(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    uint num;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      num = JSValueUtil.toWei(JSValueUtil.toRaw(leftNum) << JSValueUtil.toRaw(rightNum));
    } else if (_isNumeric(leftValue.valueType) && !_isNumeric(rightValue.valueType)) {
      num = leftNum;
    }
    res.value = abi.encode(num);
    res.numberSign = leftValue.numberSign;
    return res;
  }
  
  /**
   * Implement right shift operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function rightShift(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    uint num;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      num = JSValueUtil.toWei(JSValueUtil.toRaw(leftNum) >> JSValueUtil.toRaw(rightNum));
    } else if (_isNumeric(leftValue.valueType) && !_isNumeric(rightValue.valueType)) {
      num = leftNum;
    }
    res.value = abi.encode(num);
    res.numberSign = leftValue.numberSign;
    return res;
  }

  /**
   * Implement signed right shift operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function unsignedRightShift(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    uint num;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      if (rightValue.numberSign) {
        if (leftValue.numberSign) {
          num = leftNum / 2 ** (JSValueUtil.toRaw(rightNum));
          res.numberSign = leftValue.numberSign;
        } else {
          uint n = JSValueUtil.toWei(_twoComplement64(JSValueUtil.toRaw(leftNum)));
          num = n / 2 ** (JSValueUtil.toRaw(rightNum));
          res.numberSign = true;
        }
      }
    } else if (_isNumeric(leftValue.valueType) && !_isNumeric(rightValue.valueType)) {
      num = leftNum;
      res.numberSign = leftValue.numberSign;
    }
    res.value = abi.encode(num);
    return res;
  }

  /**
   * Implement bitwise or operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function bitwiseOr(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    uint num;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    uint left = _isNumeric(leftValue.valueType) ? (leftValue.numberSign ? JSValueUtil.toRaw(leftNum) : _twoComplement64(JSValueUtil.toRaw(leftNum))) : 0;
    uint right = _isNumeric(rightValue.valueType) ? (rightValue.numberSign ? JSValueUtil.toRaw(rightNum) : _twoComplement64(JSValueUtil.toRaw(rightNum))) : 0;
    num = JSValueUtil.toWei(left | right);
    if (!leftValue.numberSign || !rightValue.numberSign) {
      num = JSValueUtil.toWei(_twoComplement64(JSValueUtil.toRaw(num)));
      res.numberSign = false;
    } else {
      res.numberSign = true;
    }
    res.value = abi.encode(num);
    return res;
  }
  
  /**
   * Implement bitwise and operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function bitwiseAnd(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    uint num;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      uint left = leftValue.numberSign ? JSValueUtil.toRaw(leftNum) : _twoComplement64(JSValueUtil.toRaw(leftNum));
      uint right = rightValue.numberSign ? JSValueUtil.toRaw(rightNum) : _twoComplement64(JSValueUtil.toRaw(rightNum));
      num = JSValueUtil.toWei(left & right);
      if (!leftValue.numberSign && !rightValue.numberSign) {
        num = JSValueUtil.toWei(_twoComplement64(JSValueUtil.toRaw(num)));
        res.numberSign = false;
      } else {
        res.numberSign = true;
      }
    }
    res.value = abi.encode(num);
    return res;
  }
  
  /**
   * Implement bitwise xor operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function bitwiseXor(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    uint num;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    uint left = _isNumeric(leftValue.valueType) ? (leftValue.numberSign ? JSValueUtil.toRaw(leftNum) : _twoComplement64(JSValueUtil.toRaw(leftNum))) : 0;
    uint right = _isNumeric(rightValue.valueType) ? (rightValue.numberSign ? JSValueUtil.toRaw(rightNum) : _twoComplement64(JSValueUtil.toRaw(rightNum))) : 0;
    num = JSValueUtil.toWei(left ^ right);
    if (leftValue.numberSign != rightValue.numberSign) {
      num = JSValueUtil.toWei(_twoComplement64(JSValueUtil.toRaw(num)));
      res.numberSign = false;
    } else {
      res.numberSign = true;
    }
    res.value = abi.encode(num);
    return res;
  }
  
  /**
   * Implement bitwise not operation
   * @param value operand
   * @return result value
   */
  function bitwiseNot(IJSInterpreter.JSValue calldata value) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    uint num;
    uint valueNum = value.numberValue();
    uint bits = _isNumeric(value.valueType) ? (value.numberSign ? JSValueUtil.toRaw(valueNum) : _twoComplement64(JSValueUtil.toRaw(valueNum))) : 0;
    bits = ~bits & 18446744073709551615;
    if (value.numberSign) {
      num = JSValueUtil.toWei(_twoComplement64(bits));
      res.numberSign = false;
    } else {
      num = JSValueUtil.toWei(bits);
      res.numberSign = true;
    }
    res.value = abi.encode(num);
    return res;
  }

  /**
   * calculate two compolement 64 digits
   * @param minusValue value with negative bit representation
   */
  function _twoComplement64(uint minusValue) private pure returns (uint) {
    return 2 ** 64 - minusValue;
  }
   
  /**
   * Determine a value is number like
   * @param valueType value type
   * @return res true if value is number like
   */
   function _isNumeric(IJSInterpreter.JSValueType valueType) private pure returns (bool res) {
    return valueType == IJSInterpreter.JSValueType.value_number ||
      valueType == IJSInterpreter.JSValueType.value_numberString ||
      valueType == IJSInterpreter.JSValueType.value_boolean ||
      valueType == IJSInterpreter.JSValueType.value_null;
  }
}