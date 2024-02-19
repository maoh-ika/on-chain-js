// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/interpreter/IJSInterpreter.sol';
import '../utils/Log.sol';
import '../interfaces/ast/IAstBuilder.sol';
import './JSValueUtil.sol';
import './StringUtil.sol';

library JSValueOp {
  using StringUtil for string;
  using JSValueUtil for IJSInterpreter.JSValue;
 
  function binaryOperation(
    IJSInterpreter.JSValue calldata leftValue,
    IJSInterpreter.JSValue calldata rightValue,
    IJSInterpreter.State calldata state,
    IAstBuilder.BinaryOperator op
  ) external view returns (IJSInterpreter.JSValue memory res) {
    if (op == IAstBuilder.BinaryOperator.biop_addition) {
      res = add(leftValue, rightValue, state);
    } else if (op == IAstBuilder.BinaryOperator.biop_subtraction) {
      res = sub(leftValue, rightValue, state);
    } else if (op == IAstBuilder.BinaryOperator.biop_multiplication) {
      res = mul(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_division) {
      res = div(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_remainder) {
      res = remainder(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_in) {
      // no impl
    } else if (op == IAstBuilder.BinaryOperator.biop_instanceof) {
      // no impl
    } else if (op == IAstBuilder.BinaryOperator.biop_equality) {
      res = equal(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_inequality) {
      res = inequal(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_strictEquality) {
      res = strictEqual(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_strictInequality) {
      res = strictInequal(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_lessThan) {
      res = lessThan(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_lessThanOrEqual) {
      res = lessThanOrEqual(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_greaterThan) {
      res = greaterThan(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_greaterThanOrEqual) {
      res = greaterThanOrEqual(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_leftShift) {
      res = leftShift(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_rightShift) {
      res = rightShift(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_unsignedRightShift) {
      res = unsignedRightShift(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_bitwiseOr) {
      res = bitwiseOr(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_bitwiseXor) {
      res = bitwiseXor(leftValue, rightValue);
    } else if (op == IAstBuilder.BinaryOperator.biop_bitwiseAnd) {
      res = bitwiseAnd(leftValue, rightValue);
    }
  }

  function unaryOperation(IJSInterpreter.JSValue calldata argValue, IAstBuilder.UnaryOperator op) external pure returns (IJSInterpreter.JSValue memory res) {
    if (op == IAstBuilder.UnaryOperator.unary_minus) {
      res = argValue.toNumber();
      res.numberSign = !argValue.numberSign;
    } else if (op == IAstBuilder.UnaryOperator.unary_plus) {
      res = argValue.toNumber();
    } else if (op == IAstBuilder.UnaryOperator.unary_logicalNot) {
      res = logicalNot(argValue);
    } else if (op == IAstBuilder.UnaryOperator.unary_bitwiseNot) {
      res = bitwiseNot(argValue);
    } else if (op == IAstBuilder.UnaryOperator.unary_typeof) {
      res = JSValueUtil.getType(argValue);
    } else if (
      op == IAstBuilder.UnaryOperator.unary_void ||
      op == IAstBuilder.UnaryOperator.unary_delete
    ) {
      res.valueType = IJSInterpreter.JSValueType.value_undefined;
    }
  }
  
  function assignmentOperation(
    IJSInterpreter.JSValue calldata leftValue,
    IJSInterpreter.JSValue calldata rightValue,
    IJSInterpreter.State calldata state,
    IAstBuilder.AssignmentOperator op
  ) external view returns (IJSInterpreter.JSValue memory res) {
    if (op == IAstBuilder.AssignmentOperator.assignment) {
      res = rightValue;
    } else if (op == IAstBuilder.AssignmentOperator.additionAssignment) {
      res = add(leftValue, rightValue, state);
    } else if (op == IAstBuilder.AssignmentOperator.subtractionAssignment) {
      res = sub(leftValue, rightValue, state);
    } else if (op == IAstBuilder.AssignmentOperator.exponentiationAssignment) {
      res = exp(leftValue, rightValue);
    } else if (op == IAstBuilder.AssignmentOperator.divisionAssignment) {
      res = div(leftValue, rightValue);
    } else if (op == IAstBuilder.AssignmentOperator.remainderAssignment) {
      res = remainder(leftValue, rightValue);
    } else if (op == IAstBuilder.AssignmentOperator.leftShiftAssignment) {
      res = leftShift(leftValue, rightValue);
    } else if (op == IAstBuilder.AssignmentOperator.rightShiftAssignment) {
      res = rightShift(leftValue, rightValue);
    } else if (op == IAstBuilder.AssignmentOperator.bitwiseOrAssignment) {
      res = bitwiseOr(leftValue, rightValue);
    } else if (op == IAstBuilder.AssignmentOperator.bitwiseXorAssignment) {
      res = bitwiseXor(leftValue, rightValue);
    } else if (op == IAstBuilder.AssignmentOperator.bitwiseAndAssignment) {
      res = bitwiseAnd(leftValue, rightValue);
    }
  }

  /**
   * Implement addition operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function add(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue, IJSInterpreter.State memory state) internal view returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    IJSInterpreter.JSValueType leftType = leftValue.valueType;
    IJSInterpreter.JSValueType rightType = rightValue.valueType;
    bool leftIsStringish = (leftType == IJSInterpreter.JSValueType.value_string || leftType == IJSInterpreter.JSValueType.value_numberString);
    bool rightIsStringish = (rightType == IJSInterpreter.JSValueType.value_string || rightType == IJSInterpreter.JSValueType.value_numberString);
    uint num;
    string memory str;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    string memory leftStr = leftValue.stringValue();
    string memory rightStr = rightValue.stringValue();
    if (
      // number + number/bool
      (leftType == IJSInterpreter.JSValueType.value_number && (
        rightType == IJSInterpreter.JSValueType.value_number ||
        rightType == IJSInterpreter.JSValueType.value_boolean)) ||
      // bool + number/bool/null
      (leftType == IJSInterpreter.JSValueType.value_boolean && (
        rightType == IJSInterpreter.JSValueType.value_number ||
        rightType == IJSInterpreter.JSValueType.value_boolean ||
        rightType == IJSInterpreter.JSValueType.value_null)) ||
      // null + number/null
      (leftType == IJSInterpreter.JSValueType.value_null && (
        rightType == IJSInterpreter.JSValueType.value_number ||
        rightType == IJSInterpreter.JSValueType.value_boolean ||
        rightType == IJSInterpreter.JSValueType.value_null))
    ) {
      res.valueType = IJSInterpreter.JSValueType.value_number;
      if (leftValue.numberSign == rightValue.numberSign) {
        num = leftNum + rightNum;
        res.numberSign = leftValue.numberSign;
      } else if (leftValue.numberSign && !rightValue.numberSign) {
        if (leftNum >= rightNum) {
          num = leftNum - rightNum;
          res.numberSign = true;
        } else {
          num = rightNum - leftNum;
          res.numberSign = false;
        }
      } else if (!leftValue.numberSign && rightValue.numberSign) {
        if (leftNum > rightNum) {
          num = leftNum - rightNum;
          res.numberSign = false;
        } else {
          num = rightNum - leftNum;
          res.numberSign = true;
        }
      }
    // number + string
    } else if (leftType == IJSInterpreter.JSValueType.value_number && rightIsStringish) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(JSValueUtil.toString(leftNum, leftValue.numberSign), rightStr);
    // number + null
    } else if (leftType == IJSInterpreter.JSValueType.value_number && rightType == IJSInterpreter.JSValueType.value_null) {
      res.valueType = IJSInterpreter.JSValueType.value_number;
      num = leftNum;
      res.numberSign = leftValue.numberSign;
    // number + Infinity
    } else if (leftType == IJSInterpreter.JSValueType.value_number && rightType == IJSInterpreter.JSValueType.value_infinity) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = rightValue.numberSign;
    // string + number
    } else if (leftIsStringish && rightType == IJSInterpreter.JSValueType.value_number) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftStr, JSValueUtil.toString(rightNum, rightValue.numberSign));
    // string + string
    } else if (leftIsStringish && rightIsStringish) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftStr, rightStr);
    // string + bool
    } else if (leftIsStringish && rightType == IJSInterpreter.JSValueType.value_boolean) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftStr, rightValue.boolValue() ? 'true' : 'false');
    // string + null
    } else if (leftIsStringish && rightType == IJSInterpreter.JSValueType.value_null) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftStr, 'null');
    // string + undefined
    } else if (leftIsStringish && rightType == IJSInterpreter.JSValueType.value_undefined) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftStr, 'undefined');
    // string + NaN
    } else if (leftIsStringish && rightType == IJSInterpreter.JSValueType.value_nan) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftStr, 'NaN');
    // string + Infinity
    } else if (leftIsStringish && rightType == IJSInterpreter.JSValueType.value_infinity) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftStr, rightValue.numberSign ? 'Infinity' : '-Infinity');
    // bool + string
    } else if (leftType == IJSInterpreter.JSValueType.value_boolean && rightIsStringish) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftValue.boolValue() ? 'true' : 'false', rightStr);
    // bool + Infinity
    } else if (leftType == IJSInterpreter.JSValueType.value_boolean && rightType == IJSInterpreter.JSValueType.value_infinity) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = rightValue.numberSign;
    // null + string
    } else if (leftType == IJSInterpreter.JSValueType.value_null && rightIsStringish) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat('null', rightStr);
    // null + Infinity
    } else if (leftType == IJSInterpreter.JSValueType.value_null && rightType == IJSInterpreter.JSValueType.value_infinity) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = rightValue.numberSign;
    // undefined + string
    } else if (leftType == IJSInterpreter.JSValueType.value_undefined && rightIsStringish) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat('undefined', rightStr);
    // NaN + string
    } else if (leftType == IJSInterpreter.JSValueType.value_nan && rightIsStringish) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat('NaN', rightStr);
    // infinity + number
    } else if (leftType == IJSInterpreter.JSValueType.value_infinity && rightType == IJSInterpreter.JSValueType.value_number) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = leftValue.numberSign;
    // infinity + string
    } else if (leftType == IJSInterpreter.JSValueType.value_infinity && rightIsStringish) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      str = string.concat(leftValue.numberSign ? 'Infinity' : '-Infinity', rightStr);
    // infinity + bool/null
    } else if (
      leftType == IJSInterpreter.JSValueType.value_infinity && (
        rightType == IJSInterpreter.JSValueType.value_boolean ||
        rightType == IJSInterpreter.JSValueType.value_null)
    ) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = leftValue.numberSign;
    // infinity + infinity
    } else if (leftType == IJSInterpreter.JSValueType.value_infinity && rightType == IJSInterpreter.JSValueType.value_string) {
      if (leftValue.numberSign == rightValue.numberSign) {
        res.valueType = IJSInterpreter.JSValueType.value_infinity;
        res.numberSign = leftValue.numberSign;
      } else {
        res.valueType = IJSInterpreter.JSValueType.value_nan;
      }
    // array + array
    } else if (leftType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      IJSInterpreter.JSArray memory leftArray = leftValue.arrayValue();
      string memory leftStrPart = JSValueUtil.toStringArray(leftArray.elements[leftArray.rootElementIndex], leftArray, state, true, true);
      if (rightType == IJSInterpreter.JSValueType.value_array) {
        IJSInterpreter.JSArray memory rightArray = rightValue.arrayValue();
        str = string.concat(leftStrPart, JSValueUtil.toStringArray(rightArray.elements[rightArray.rootElementIndex], rightArray, state, true, true));
      } else {
        str = string.concat(leftStrPart, JSValueUtil.toStringLiteral(rightValue, true));
      }
    // non-array + array
    } else if (leftType != IJSInterpreter.JSValueType.value_array && rightType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_string;
      IJSInterpreter.JSArray memory rightArray = rightValue.arrayValue();
      str = string.concat(JSValueUtil.toStringLiteral(leftValue, true), JSValueUtil.toStringArray(rightArray.elements[rightArray.rootElementIndex], rightArray, state, true, true));
    } else {
      // number + undefined/NaN
      // bool + undefined/NaN
      // null + undefined/NaN
      // undefined + number/bool/null/undefined/nan/infinity
      // infinity + undefined/NaN
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    }
    if (res.valueType ==  IJSInterpreter.JSValueType.value_number) {
      res.value = abi.encode(num);
    } else if (res.valueType ==  IJSInterpreter.JSValueType.value_string) {
      res.value = abi.encode(str);
    }
    
    return res;
  }

  /**
   * Implement subtraction operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function sub(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue, IJSInterpreter.State memory state) internal view returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    IJSInterpreter.JSValueType leftType = leftValue.valueType;
    IJSInterpreter.JSValueType rightType = rightValue.valueType;
    bool rightIsStrUndefNan = (
        rightType == IJSInterpreter.JSValueType.value_string ||
        rightType == IJSInterpreter.JSValueType.value_undefined ||
        rightType == IJSInterpreter.JSValueType.value_nan);
    if (
      // number - string
      (leftType == IJSInterpreter.JSValueType.value_number && rightValue.valueType == IJSInterpreter.JSValueType.value_string) ||
      // string - number/string/bool/null/undefined/NaN
      (leftType == IJSInterpreter.JSValueType.value_string) ||
      // numberString - string/undefined/NaN
      (leftType == IJSInterpreter.JSValueType.value_numberString && rightIsStrUndefNan) ||
      // bool - string/undefined/NaN
      (leftType == IJSInterpreter.JSValueType.value_boolean && rightIsStrUndefNan) ||
      // null - string/undefined/NaN
      (leftType == IJSInterpreter.JSValueType.value_null && rightIsStrUndefNan) ||
      // undefined/NaN
      leftType == IJSInterpreter.JSValueType.value_undefined ||
      leftType == IJSInterpreter.JSValueType.value_nan ||
      // infinity - string
      (leftType == IJSInterpreter.JSValueType.value_infinity && rightIsStrUndefNan)
    ) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else if (leftType == IJSInterpreter.JSValueType.value_array || rightType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else {
      if (leftType == IJSInterpreter.JSValueType.value_numberString) {
        leftValue = JSValueUtil.toNumber(leftValue);
      }
      if (rightType == IJSInterpreter.JSValueType.value_numberString) {
        rightValue = JSValueUtil.toNumber(rightValue);
      }
      IJSInterpreter.JSValue memory reverse;
      reverse.valueType = rightValue.valueType;
      reverse.value = rightValue.value;
      reverse.numberSign = !rightValue.numberSign;
      res = add(leftValue, reverse, state);
    }

    return res;
  }
  
  /**
   * Implement multiplication operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function mul(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    bool leftIsNumerish = _isNumeric(leftValue.valueType);
    bool rightIsNumerish = _isNumeric(rightValue.valueType);

    // number * number/numberString/bool/null
    // bool * number/numberString/bool/null
    if (leftIsNumerish && rightIsNumerish) {
      res = _mulNumbers(leftValue, rightValue);
    // number * infinity
    // bool * infinity
    // infinity * number/numberString/bool
    } else if (
      (leftValue.valueType == IJSInterpreter.JSValueType.value_number && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) ||
      (leftValue.valueType == IJSInterpreter.JSValueType.value_boolean && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) ||
      (leftValue.valueType == IJSInterpreter.JSValueType.value_infinity && (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean))
    ) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = (leftValue.numberSign == rightValue.numberSign);
    // null * number/stringNumber/bool/null
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_null && rightIsNumerish) {
      res.valueType = IJSInterpreter.JSValueType.value_number;
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_array || rightValue.valueType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else {
      // number * string/undefined/NaN
      // string * number/string/bool/null/undefined/undefined/infinity
      // bool * string/undefined/NaN
      // null * string/undefined/NaN/infinity
      // undefined/NaN
      // infinity * string/null/undefined/NaN
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    }
    return res;
  }
  
  /**
   * Implement division operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function div(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    bool rightIsNumerish = (
        rightValue.valueType == IJSInterpreter.JSValueType.value_number ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_numberString ||
        rightValue.valueType == IJSInterpreter.JSValueType.value_boolean);
    if (
      // number / number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_number && rightIsNumerish) ||
      // numberString / number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_numberString && rightIsNumerish) ||
      // bool / number/numberString/bool/null
      (leftValue.valueType == IJSInterpreter.JSValueType.value_boolean && (rightIsNumerish || rightValue.valueType == IJSInterpreter.JSValueType.value_null)) ||
      // null / number/numberString/bool
      (leftValue.valueType == IJSInterpreter.JSValueType.value_null && rightIsNumerish)
    ) {
      res = _divNumbers(leftValue, rightValue);
    // number / null
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_number && rightValue.valueType == IJSInterpreter.JSValueType.value_null) {
      res.valueType = leftValue.numberValue() == 0 ? IJSInterpreter.JSValueType.value_nan : IJSInterpreter.JSValueType.value_infinity;
    // number / infinity
    // numberString / infinity
    // bool / infinity
    // null / infinity
    } else if (
      (leftValue.valueType == IJSInterpreter.JSValueType.value_number && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) ||
      (leftValue.valueType == IJSInterpreter.JSValueType.value_numberString && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) ||
      (leftValue.valueType == IJSInterpreter.JSValueType.value_boolean && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) ||
      (leftValue.valueType == IJSInterpreter.JSValueType.value_null && rightValue.valueType == IJSInterpreter.JSValueType.value_infinity)
    ) {
      res.valueType = IJSInterpreter.JSValueType.value_number;
    // numberString / null
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_numberString && rightValue.valueType == IJSInterpreter.JSValueType.value_null) {
      res.valueType = leftValue.numberValue() == 0 ? IJSInterpreter.JSValueType.value_nan : IJSInterpreter.JSValueType.value_infinity;
    // infinity / number/numberString/bool/null
    } else if (
      leftValue.valueType == IJSInterpreter.JSValueType.value_infinity && (rightIsNumerish || rightValue.valueType == IJSInterpreter.JSValueType.value_null)
    ) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = (leftValue.numberSign == rightValue.numberSign);
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_array || rightValue.valueType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else {
    // number / string/undefined/NaN/
    // string / number/string/bool/null/undefined/NaN/infinity
    // number / NaN
    // numberString / string/undefined/NaN
    // bool / string/undefined/NaN
    // null / string/null/undefined/NaN
    // undefined/NaN
    // infinity / string/undefined/NaN/infinity
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    }
    return res;
  }
  
  /**
   * Implement reminder operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function remainder(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    uint num;
    if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      if (rightValue.numberValue() == 0) {
        res.valueType = IJSInterpreter.JSValueType.value_nan;
      } else {
        res.valueType = IJSInterpreter.JSValueType.value_number;
        //uint divValue = JSValueUtil.toRaw(_divNumbers(leftValue, rightValue).numberValue());
        //num = (leftValue.numberValue() - (rightValue.numberValue() * divValue));
        num = leftValue.numberValue() % rightValue.numberValue();
        res.numberSign = leftValue.numberSign;
      }
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_array || rightValue.valueType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    }
    res.value = abi.encode(num);
    return res;
  }

  /**
   * Implement exponent operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function exp(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    uint num;
    if (_isUndefinedOrNaN(leftValue.valueType) || _isUndefinedOrNaN(rightValue.valueType)) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else if (_isNumeric(leftValue.valueType) && _isNumeric(rightValue.valueType)) {
      require(
        JSValueUtil.getDecimal(rightValue.numberValue()) == 0 &&
        rightValue.numberSign,
      'decimal or minus pow not supported');
      res.valueType = IJSInterpreter.JSValueType.value_number;
      num = JSValueUtil.toWei(JSValueUtil.toRaw(leftValue.numberValue()) ** JSValueUtil.toRaw(rightValue.numberValue()));
      res.numberSign = leftValue.numberSign;
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_infinity || rightValue.valueType == IJSInterpreter.JSValueType.value_infinity) {
      if (rightValue.numberSign) {
        res.valueType == IJSInterpreter.JSValueType.value_infinity;
      } else {
        res.valueType == IJSInterpreter.JSValueType.value_number;
      }
    } else if (leftValue.valueType == IJSInterpreter.JSValueType.value_array || rightValue.valueType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    }

    res.value = abi.encode(num);
    return res;
  }
  
  /**
   * Implement increment operation
   * @param value operand
   * @return result value
   */
  function increment(IJSInterpreter.JSValue memory value, IJSInterpreter.State memory state) internal view returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    if (value.valueType == IJSInterpreter.JSValueType.value_nan || value.valueType == IJSInterpreter.JSValueType.value_undefined) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_infinity) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = value.numberSign;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else {
      IJSInterpreter.JSValue memory one;
      one.valueType = IJSInterpreter.JSValueType.value_number;
      one.numberSign = true;
      one.value = abi.encode(JSValueUtil.toWei(1));
      res = add(value, one, state);
    }
    return res;
  }
  
  /**
   * Implement decrement operation
   * @param value operand
   * @return result value
   */
  function decrement(IJSInterpreter.JSValue memory value, IJSInterpreter.State memory state) internal view returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    if (value.valueType == IJSInterpreter.JSValueType.value_nan || value.valueType == IJSInterpreter.JSValueType.value_undefined) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_infinity) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = value.numberSign;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_array) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else {
      IJSInterpreter.JSValue memory one;
      one.valueType = IJSInterpreter.JSValueType.value_number;
      one.numberSign = true;
      one.value = abi.encode(JSValueUtil.toWei(1));
      res = sub(value, one, state);
    }
    return res;
  }

  
  /**
   * Implement logical not operation
   * @param value operand
   * @return result value
   */
  function logicalNot(IJSInterpreter.JSValue calldata value) private pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    uint num;
    bool bl;
    res.valueType = IJSInterpreter.JSValueType.value_boolean;
    if (_isNumeric(value.valueType)) {
      bl = !(value.numberValue() == 0 ? false : true);
    } else if (value.valueType == IJSInterpreter.JSValueType.value_infinity) {
      bl = false;
    } else {
      bl = true;
      num = 1;
    }
    res.value = abi.encode(bl);
    return res;
  }
  
  /**
   * multiply two values
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function _mulNumbers(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) private pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    uint num;
    res.valueType = IJSInterpreter.JSValueType.value_number;
    num = JSValueUtil.toRaw(leftValue.numberValue() * rightValue.numberValue());
    res.numberSign = (leftValue.numberSign == rightValue.numberSign);
    res.value = abi.encode(num);
    return res;
  }

  /**
   * divide two values
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function _divNumbers(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) private pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory res;
    uint leftNum = leftValue.numberValue();
    uint rightNum = rightValue.numberValue();
    if (!leftValue.boolValue() && rightNum == 0) {
      res.valueType = IJSInterpreter.JSValueType.value_nan;
    } else if (rightNum == 0) {
      res.valueType = IJSInterpreter.JSValueType.value_infinity;
      res.numberSign = leftValue.numberSign == rightValue.numberSign;
    } else {
      res.valueType = IJSInterpreter.JSValueType.value_number;
      uint value = 0;
      uint numerator = leftNum;
      for (uint digit = 0; digit <= JSValueUtil.maxDecimalDigits; ++digit) {
        value += numerator / rightNum * 10 ** (JSValueUtil.maxDecimalDigits - digit);
        uint remain = numerator % rightNum;
        if (remain == 0) {
          break;
        }
        numerator = remain * 10;
      }
      res.value = abi.encode(value);
      res.numberSign = leftValue.numberSign == rightValue.numberSign;
    }
    return res;
  }

  /**
   * Determine a value is undefined or nan
   * @param valueType value type
   * @return result
   */
  function _isUndefinedOrNaN(IJSInterpreter.JSValueType valueType) private pure returns (bool) {
    return valueType == IJSInterpreter.JSValueType.value_undefined || valueType == IJSInterpreter.JSValueType.value_nan;
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
  
  /**
   * Implement left shift operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function leftShift(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
  function rightShift(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
  function unsignedRightShift(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
  function bitwiseOr(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
  function bitwiseAnd(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
  function bitwiseXor(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
  function bitwiseNot(IJSInterpreter.JSValue memory value) internal pure returns (IJSInterpreter.JSValue memory) {
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
   * Implement equal operation
   * @param leftValue left operand
   * @param rightValue right operant
   * @return result value
   */
  function equal(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
  function inequal(IJSInterpreter.JSValue memory leftValue, IJSInterpreter.JSValue memory rightValue) internal pure returns (IJSInterpreter.JSValue memory) {
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
   * calculate two compolement 64 digits
   * @param minusValue value with negative bit representation
   */
  function _twoComplement64(uint minusValue) private pure returns (uint) {
    return 2 ** 64 - minusValue;
  }
}