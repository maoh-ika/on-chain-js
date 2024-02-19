// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "../utils/Log.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from 'base64-sol/base64.sol';
import '../interfaces/interpreter/IJSInterpreter.sol';
import '../interfaces/ast/IAstBuilder.sol';
import './StringUtil.sol';
import './NumberUtil.sol';
import './JSObjectImpl.sol';
import './JSArrayImpl.sol';

library JSValueUtil {
  using StringUtil for string;
  using NumberUtil for uint;
  using JSArrayElementUtil for IJSInterpreter.JSArrayElement;
  using JSObjectPropertyUtil for IJSInterpreter.JSObjectProperty;
  
  uint8 public constant maxDecimalDigits = 18;
  string public constant decimalPaddings = '000000000000000000';
  
  /**
   * Determine the value is equivalent to true
   * @param value JSValue
   * @return res true if the value is true
   */
  function isTrue(IJSInterpreter.JSValue memory value) internal pure returns (bool res) {
    IJSInterpreter.JSValueType valueType = value.valueType;
    if (
      valueType == IJSInterpreter.JSValueType.value_null ||
      valueType == IJSInterpreter.JSValueType.value_undefined ||
      valueType == IJSInterpreter.JSValueType.value_nan
    ) {
      return false;
    } else if (valueType == IJSInterpreter.JSValueType.value_infinity) {
      return true;
    } else if (valueType == IJSInterpreter.JSValueType.value_string || valueType == IJSInterpreter.JSValueType.value_numberString) {
      return boolValue(value);
    } else {
      return numberValue(value) != 0;
    }
  }
  
  /**
   * Determine the value is 'reference type'
   * @param value JSValue
   * @return res true if the value is 'reference type', otherwise it is 'value type', return false.
   */
  function isReferenceType(IJSInterpreter.JSValue memory value) internal pure returns (bool res) {
    IJSInterpreter.JSValueType valueType = value.valueType;
    return
      valueType == IJSInterpreter.JSValueType.value_array ||
      valueType == IJSInterpreter.JSValueType.value_object ||
      valueType == IJSInterpreter.JSValueType.value_reference;
  }
  
  /**
   * convert to internal integer format
   * @param value raw integer 
   * @return res internal format
   */
  function toWei(uint value) internal pure returns (uint res) {
    assembly {
      res := mul(value, exp(10, maxDecimalDigits))
    }
  }

  /**
   * convert to raw integer format
   * @param value internal integer format
   * @return res raw integer
   */
  function toRaw(uint value) internal pure returns (uint res) {
    assembly {
      res := div(value, exp(10, maxDecimalDigits))
    }
  }

  /**
   * Evaluate JSValue as number
   * @param value JSValue
   * @return number value
   */
  function numberValue(IJSInterpreter.JSValue memory value) internal pure returns (uint) {
    if (value.valueType == IJSInterpreter.JSValueType.value_number) {
      return abi.decode(value.value, (uint));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      bool bl = abi.decode(value.value, (bool));
      return bl ? toWei(1) : 0;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (uint num,) = abi.decode(value.value, (uint, string));
      return num;
    } else {
      return 0;
    }
  }
  
  /**
   * Evaluate JSValue as bool
   * @param value JSValue
   * @return bool value
   */
  function boolValue(IJSInterpreter.JSValue memory value) internal pure returns (bool) {
    if (value.valueType == IJSInterpreter.JSValueType.value_number) {
      return abi.decode(value.value, (uint)) != 0;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      return abi.decode(value.value, (bool));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (uint num, string memory str) = abi.decode(value.value, (uint, string));
      return num != 0 && !StringUtil.equal(str, '');
    } else if (value.valueType == IJSInterpreter.JSValueType.value_string) {
      (string memory str) = abi.decode(value.value, (string));
      return !StringUtil.equal(str, '');
    } else {
      return false;
    }
  }
  
  /**
   * Evaluate JSValue as string
   * @param value JSValue
   * @return string value
   */
  function stringValue(IJSInterpreter.JSValue memory value) internal pure returns (string memory) {
    if (value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      (,string memory str) = abi.decode(value.value, (uint, string));
      return str;
    } else if (value.valueType == IJSInterpreter.JSValueType.value_string) {
      return  abi.decode(value.value, (string));
    } else {
      return '';
    }
  }
  
  /**
   * Evaluate JSValue as object
   * @param value JSValue
   * @return obj JSObject value
   */
  function objectValue(IJSInterpreter.JSValue memory value) internal pure returns (IJSInterpreter.JSObject memory obj) {
    if (value.valueType == IJSInterpreter.JSValueType.value_object) { 
      obj = abi.decode(value.value, (IJSInterpreter.JSObject));
    }
  }
  
  /**
   * Evaluate JSValue as array
   * @param value JSValue
   * @return array JSArray value
   */
  function arrayValue(IJSInterpreter.JSValue memory value) internal pure returns (IJSInterpreter.JSArray memory array) {
    if (value.valueType == IJSInterpreter.JSValueType.value_array) { 
      array = abi.decode(value.value, (IJSInterpreter.JSArray));
    }
  }
  
  /**
   * Get reference identifier index
   * @param value JSValue
   * @return index the reference identifier index
   */
  function referenceIdentifierIndex(IJSInterpreter.JSValue memory value) internal pure returns (uint index) {
    if (value.valueType == IJSInterpreter.JSValueType.value_reference) { 
      index = abi.decode(value.value, (uint));
    }
  }
  
  /**
   * Get value type as string
   * @param value JSValue
   * @return type string
   */
  function getType(IJSInterpreter.JSValue calldata value) public pure returns (IJSInterpreter.JSValue memory) {
    string memory valueType = 'object';
    if (value.valueType == IJSInterpreter.JSValueType.value_string || value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      valueType = 'string';
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      valueType = 'boolean';
    } else if (
      value.valueType == IJSInterpreter.JSValueType.value_number ||
      value.valueType == IJSInterpreter.JSValueType.value_nan ||
      value.valueType == IJSInterpreter.JSValueType.value_infinity
    ) {
      valueType = 'number';
    } else if (
      value.valueType == IJSInterpreter.JSValueType.value_regex ||
      value.valueType == IJSInterpreter.JSValueType.value_null
    ) {
      valueType = 'object';
    } else if (value.valueType == IJSInterpreter.JSValueType.value_undefined) {
      valueType = 'undefined';
    }
    IJSInterpreter.JSValue memory result;
    result.valueType = IJSInterpreter.JSValueType.value_string;
    result.value = abi.encode(valueType);

    return result;
  }

  /**
   * Get decimal part of the value in internal integer format
   * @param value18 the value in internla integer format
   * @return decimal part value
   */
  function getDecimal(uint value18) public pure returns (uint) {
    return value18 % 10 ** JSValueUtil.maxDecimalDigits;
  }
  
  /**
   * covert to number type
   * @param value JSValue
   * @return number type value
   */
  function toNumber(IJSInterpreter.JSValue calldata value) external pure returns (IJSInterpreter.JSValue memory) {
    IJSInterpreter.JSValue memory result;
    IJSInterpreter.JSValueType valueType = value.valueType;
    if (
      valueType == IJSInterpreter.JSValueType.value_number ||
      valueType == IJSInterpreter.JSValueType.value_numberString ||
      valueType == IJSInterpreter.JSValueType.value_boolean ||
      valueType == IJSInterpreter.JSValueType.value_null
    ) {
      result.valueType = IJSInterpreter.JSValueType.value_number;
      result.value = abi.encode(numberValue(value));
      result.numberSign = value.numberSign;
    } else if (valueType == IJSInterpreter.JSValueType.value_infinity) {
      result.valueType = IJSInterpreter.JSValueType.value_infinity;
      result.numberSign = value.numberSign;
    } else {
      result.valueType = IJSInterpreter.JSValueType.value_nan;
    }
    return result;
  }

  /**
   * stringify the number value
   * @param value18 value in internal integer format
   * @param numberSign sign of the value
   * @return stringified value
   */
  function toString(uint value18, bool numberSign) public pure returns (string memory) {
    string memory result;
    if (value18 == 0) {
      result = '0';
    } else {
      uint integer = toRaw(value18);
      uint decimal = value18 % 10 ** JSValueUtil.maxDecimalDigits;
      result = Strings.toString(integer);
      if (decimal > 0) {
        string memory padding = JSValueUtil.decimalPaddings.substring(0, JSValueUtil.maxDecimalDigits - digits(decimal));
        while (decimal > 0 && decimal % 10 == 0) {
          decimal /= 10;
        }
        result = string.concat(string.concat(result, '.'), string.concat(padding, Strings.toString(decimal)));
      }
      if (!numberSign) {
        result = string.concat('-', result);
      }
    }
    return result;
  }

  /**
   * convert JSValue to string
   * @param value JSValue
   * @return string
   */
  function toStringValue(IJSInterpreter.JSValue memory value, IJSInterpreter.State memory state, bool ignoreStringQuote) internal view returns (string memory) {
    if (value.valueType == IJSInterpreter.JSValueType.value_array) {
      IJSInterpreter.JSArray memory array= arrayValue(value);
      return toStringArray(array.elements[array.rootElementIndex], array, state, false, false);
    } else if (value.valueType == IJSInterpreter.JSValueType.value_object) {
      IJSInterpreter.JSObject memory object = objectValue(value);
      return toStringObject(object.properties[object.rootPropertyIndex], object, state, false, false);
    } else if (value.valueType == IJSInterpreter.JSValueType.value_reference) {
      IJSInterpreter.JSValue memory refValue = resolveReference(value, state);
      return toStringValue(refValue, state, ignoreStringQuote);
    } else {
      return toStringLiteral(value, ignoreStringQuote);
    }
  }

  /**
   * stringify the JSValue
   * @param value JSValue
   * @param ignoreQuote if true, do not print quotations enclosing the string
   * @return stringified value
   */
  function toStringLiteral(IJSInterpreter.JSValue memory value, bool ignoreQuote) public pure returns (string memory) {
    string memory result;
    if (value.valueType == IJSInterpreter.JSValueType.value_string || value.valueType == IJSInterpreter.JSValueType.value_numberString) {
      string memory str = stringValue(value);
      result = ignoreQuote ? str : string.concat('"', string.concat(str, '"'));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_boolean) {
      result = boolValue(value) ? 'true' : 'false';
    } else if (value.valueType == IJSInterpreter.JSValueType.value_number) {
      result = toString(numberValue(value), value.numberSign);
    } else if (value.valueType == IJSInterpreter.JSValueType.value_null) {
      result = 'null';
    } else if (value.valueType == IJSInterpreter.JSValueType.value_undefined) {
      result = ignoreQuote ? 'undefined' : string.concat('"', string.concat('undefined', '"'));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_nan) {
      result = ignoreQuote ? 'NaN' : string.concat('"', string.concat('NaN', '"'));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_infinity) {
      result = ignoreQuote ? 'Infinity' : string.concat('"', string.concat('Infinity', '"'));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_bytes) {
      string memory bytesStr = Base64.encode(value.value);
      result = ignoreQuote ? bytesStr : string.concat('"', string.concat(bytesStr, '"'));
    } else if (value.valueType == IJSInterpreter.JSValueType.value_function) {
      result = ignoreQuote ? 'function' : string.concat('"', string.concat('function', '"'));
    }
    return result;
  }

  /**
   * stringify the array
   * @param element array to stringify
   * @param array JSArray containing the element
   * @param ignoreQuote if true, do not print quotations enclosing the string
   * @return stringified value
   */
  function toStringArray(IJSInterpreter.JSArrayElement memory element, IJSInterpreter.JSArray memory array, IJSInterpreter.State memory state, bool ignoreBracket, bool ignoreQuote) public view returns (string memory) {
    if (element.valueType != IJSInterpreter.JSValueType.value_array) {
      return '';
    }
    // console.log('IN toStringArray');
    string memory result = ignoreBracket ? '' : '[';
    uint[] memory arrayElmentIndexes = element.arrayElmentIndexes();
    for (uint i = 0; i < arrayElmentIndexes.length; ++i) {
      if (i != 0) {
        result = string.concat(result, ',');
      }
      if (array.elements[arrayElmentIndexes[i]].valueType == IJSInterpreter.JSValueType.value_array) {
        result = string.concat(result, toStringArray(array.elements[arrayElmentIndexes[i]], array, state, ignoreBracket, ignoreQuote));
      } else if (array.elements[arrayElmentIndexes[i]].valueType == IJSInterpreter.JSValueType.value_object) {
        IJSInterpreter.JSObject memory object = JSArrayElementUtil.objectValue(array.elements[arrayElmentIndexes[i]]);
        result = string.concat(result, toStringObject(object.properties[object.rootPropertyIndex], object, state, ignoreBracket, ignoreQuote));
      } else if (array.elements[arrayElmentIndexes[i]].valueType == IJSInterpreter.JSValueType.value_reference) {
        uint idIndex = abi.decode(array.elements[arrayElmentIndexes[i]].value, (uint));
        IJSInterpreter.JSValue memory refValue = resolveReference(state.identifierStates[idIndex].value, state);
        result = string.concat(result, toStringValue(refValue, state, false));
      } else {
        result = string.concat(result, toStringLiteral(IJSInterpreter.JSValue(
          array.elements[arrayElmentIndexes[i]].value,
          0,
          array.elements[arrayElmentIndexes[i]].numberSign,
          array.elements[arrayElmentIndexes[i]].valueType
        ), ignoreBracket));
      }
    }
    return ignoreBracket ? result : string.concat(result, ']');
  }
  
  /**
   * stringify the object
   * @param objectProperty object to stringify
   * @param object JSObject containing the objectProperty
   * @param ignoreBracket if true, do not print brachets enclosing the object
   * @param ignoreQuote if true, do not print quotations enclosing the string
   * @return stringified value
   */
  function toStringObject(IJSInterpreter.JSObjectProperty memory objectProperty, IJSInterpreter.JSObject memory object, IJSInterpreter.State memory state, bool ignoreBracket, bool ignoreQuote) public view returns (string memory) {
    // console.log('IN toStringObject');
    if (objectProperty.valueType != IJSInterpreter.JSValueType.value_object) {
      return '';
    }
    string memory result = ignoreBracket ? '' : '{';
    uint[] memory objectPropertyIndexes = objectProperty.objectPropertyIndexes();
    for (uint i = 0; i < objectPropertyIndexes.length; ++i) {
      if (i != 0) {
        result = string.concat(result, ',');
      }
      IJSInterpreter.JSObjectProperty memory property = object.properties[objectPropertyIndexes[i]];
      require(property.valueType != IJSInterpreter.JSValueType.value_invalid, 'invalid prop index');
      result = string.concat(string.concat(result, string.concat(string.concat('"', property.key), '"'), ':'));
      if (property.valueType == IJSInterpreter.JSValueType.value_object) {
        result = string.concat(result, toStringObject(property, object, state, ignoreBracket, ignoreQuote));
      } else if (property.valueType == IJSInterpreter.JSValueType.value_array) {
        IJSInterpreter.JSArray memory propArray = abi.decode(property.value, (IJSInterpreter.JSArray));
        result = string.concat(result,
          toStringArray(
            propArray.elements[propArray.rootElementIndex],
            propArray,
            state,
            ignoreBracket, ignoreQuote));
      } else if (property.valueType == IJSInterpreter.JSValueType.value_reference) {
        uint idIndex = abi.decode(property.value, (uint));
        IJSInterpreter.JSValue memory refValue = resolveReference(state.identifierStates[idIndex].value, state);
        result = string.concat(result, toStringValue(refValue, state, false));
      } else {
        result = string.concat(result, toStringLiteral(IJSInterpreter.JSValue(
          property.value,
          0,
          property.numberSign,
          property.valueType
        ), ignoreQuote));
      }
    }
    return ignoreBracket ? result : string.concat(result, '}');
  }
  
  function resolveReference(IJSInterpreter.JSValue memory value, IJSInterpreter.State memory state) internal pure returns (IJSInterpreter.JSValue memory res) {
    res = value;
    while (res.valueType == IJSInterpreter.JSValueType.value_reference) {
      res = state.identifierStates[referenceIdentifierIndex(res)].value;
    }
  }
  
  /**
   * calculate digits of the number
   * @param num number
   * @return d digits
   */
  function digits(uint num) internal pure returns (uint d) {
    assembly {
      for { let rem := num} gt(rem, 0) { rem := div(rem, 10) } {
        d := add(d, 1)
      }
    }
    return d;
  }

}