// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/interpreter/IJSInterpreter.sol';
import './StringUtil.sol';
import './JSValueUtil.sol';

library JSValueCompare {
  using StringUtil for string;
  using JSValueUtil for IJSInterpreter.JSValue;

  /**
   * Implement equal operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function equal(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl;
    if (
      // number == number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_number && (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean)) ||
      // numberString == number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_numberString && (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean)) ||
      // bool == number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_boolean && (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean))
      ) {
      bl = (leftValue.numberValue() == rightValue.numberValue()) && (leftValue.numberSign == rightValue.numberSign);
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_string && rightValue.valueType == IJSInterpreter.JSValueType.value_string) {
      bl = leftValue.stringValue().equal(rightValue.stringValue());
    } else if (
      (leftValue.valueType == IJSInterpreter.JSValueType.value_null && rightValue.valueType == IJSInterpreter.JSValueType.value_null) ||
      (leftValue.valueType == IJSInterpreter.JSValueType.value_undefined && rightValue.valueType == IJSInterpreter.JSValueType.value_undefined)) {
      bl = true;
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_infinity && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) {
      bl = leftValue.numberSign == rightValue.numberSign;
    } else {
      bl = false;
    }
    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * Implement inequal operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function inequal(IJSInterpreter.JSValue calldata leftValue, IJSInterpreter.JSValue calldata rightValue) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl;
    if (
      // number == number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_number && (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean)) ||
      // numberString == number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_numberString && (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean)) ||
      // bool == number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_boolean && (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean))
      ) {
      bl = (leftValue.numberValue() != rightValue.numberValue()) || (leftValue.numberSign != rightValue.numberSign);
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_string && rightValue.valueType == IJSInterpreter.JSValueType.value_string) {
      bl = !leftValue.stringValue().equal(rightValue.stringValue());
    } else if (
      (leftValue.valueType == IJSInterpreter.JSValueType.value_null && rightValue.valueType == IJSInterpreter.JSValueType.value_null) ||
      (leftValue.valueType == IJSInterpreter.JSValueType.value_undefined && rightValue.valueType == IJSInterpreter.JSValueType.value_undefined)) {
      bl = false;
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_infinity && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) {
      bl = leftValue.numberSign != rightValue.numberSign;
    } else {
      bl = true;
    }
    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * Implement strict equal operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function strictEqual(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl = 
      (leftValue.valueType == rightValue.valueType) &&
      (leftValue.numberValue() == rightValue.numberValue()) &&
      (leftValue.numberSign == rightValue.numberSign);

    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * Implement strict inequal operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function strictInequal(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl = 
      (leftValue.valueType != rightValue.valueType) ||
      (leftValue.numberValue() != rightValue.numberValue()) ||
      (leftValue.numberSign != rightValue.numberSign);

    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * Implement less than operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function lessThan(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      if (leftNum == 0 && rightNum == 0) {
        bl = false;
      } else {
        if (leftValue.numberSign && rightValue.numberSign) {
          bl = leftNum < rightNum;
        } else if (!leftValue.numberSign && !rightValue.numberSign) {
          bl = rightNum < leftNum;
        } else {
          bl = !leftValue.numberSign && rightValue.numberSign;
        }
      }
    }

    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * Implement less than or equal operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function lessThanOrEqual(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      if (leftNum == 0 && rightNum == 0) {
        bl = true;
      } else {
        if (leftValue.numberSign && rightValue.numberSign) {
          bl = leftNum <= rightNum;
        } else if (!leftValue.numberSign && !rightValue.numberSign) {
          bl = rightNum <= leftNum;
        } else {
          bl = !leftValue.numberSign && rightValue.numberSign;
        }
      }
    } else {
      bl = false;
    }

    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * Implement greater than operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function greaterThan(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      if (leftNum == 0 && rightNum == 0) {
        bl = false;
      } else {
        if (leftValue.numberSign && rightValue.numberSign) {
          bl = leftNum > rightNum;
        } else if (!leftValue.numberSign && !rightValue.numberSign) {
          bl = rightNum > leftNum;
        } else {
          bl = leftValue.numberSign && !rightValue.numberSign;
        }
      }
    }

    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * Implement greater than or equal operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function greaterThanOrEqual(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    bool bl;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      if (leftNum == 0 && rightNum == 0) {
        bl = true;
      } else {
        if (leftValue.numberSign && rightValue.numberSign) {
          bl = leftNum >= rightNum;
        } else if (!leftValue.numberSign && !rightValue.numberSign) {
          bl = rightNum >= leftNum;
        } else {
          bl = leftValue.numberSign && !rightValue.numberSign;
        }
      }
    }

    res.value = abi.encode(bl);
    return res;
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