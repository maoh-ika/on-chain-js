// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import '../interfaces/interpreter/IJSInterpreter.sol';
import './StringUtil.sol';
import './NumberUtil.sol';
import './JSValueUtil.sol';
import './JSObjectImpl.sol';

library JSArrayElementUtil {
  /**
   * decode arrayElmentIndexes value
   * @param elem JSArrayElement whose type is array
   * @return indexes array elements indexes which refer to elements in JSArray.elements
   */
  function arrayElmentIndexes(IJSInterpreter.JSArrayElement memory elem) internal pure returns (uint[] memory indexes) {
    if (elem.valueType == IJSInterpreter.JSValueType.value_array) {
      return abi.decode(elem.value, (uint[]));
    }
  }

  /**
   * decode object value 
   * @param elem JSArrayElement whose type is object
   * @return obj JSObject
   */
  function objectValue(IJSInterpreter.JSArrayElement memory elem) internal pure returns (IJSInterpreter.JSObject memory obj) {
    if (elem.valueType == IJSInterpreter.JSValueType.value_object) { 
      obj = abi.decode(elem.value, (IJSInterpreter.JSObject));
    }
  }
}

library JSArrayImpl {
  using JSArrayElementUtil for IJSInterpreter.JSArrayElement;
  using JSValueUtil for IJSInterpreter.JSValue;

  /**
   * add element to array
   * @param array JSArray
   * @param values elements to add
   * @notice In the case of multi-dimension array, the rootElementIndex specifies
   *         which dimension of the array to add the elements to.
   *         When adding the elements to nested array in a multi-dimension array, it is necessary to set
   *         the rootElementIndex to the index that points to the nested array.
   */
  function push(IJSInterpreter.JSArray memory array, IJSInterpreter.JSValue[] memory values) internal pure {
    if (array.elements.length == 0) {
      // add first root
      IJSInterpreter.JSArrayElement memory root;
      root.valueType = IJSInterpreter.JSValueType.value_array;
      root.value = abi.encode(new uint[](0));
      array.elements = new IJSInterpreter.JSArrayElement[](1);
      array.elements[0] = root;
      array.rootElementIndex = 0;
    }
    
    if (values.length == 0) {
      return;
    }

    // convet to JSArrayElement and insert nested array elements
    IJSInterpreter.JSArrayElement memory rootElem = array.elements[array.rootElementIndex];
    IJSInterpreter.JSArrayElement[] memory elems = new IJSInterpreter.JSArrayElement[](values.length);
    for (uint i = 0; i < values.length; ++i) {
      elems[i] = _toArrayElement(array, values[i]);
    }
   
    uint oldElemSize = array.elements.length;
    resize(array, oldElemSize + elems.length);
    uint[] memory arrayElmentIndexes = rootElem.arrayElmentIndexes();
    uint oldIndexSize = arrayElmentIndexes.length;
    uint newSize = oldIndexSize + elems.length;
    arrayElmentIndexes = NumberUtil.resize(arrayElmentIndexes, newSize);

    for (uint i = 0; i < elems.length; ++i) {
      uint index = oldElemSize + i;
      array.elements[index] = elems[i];
      arrayElmentIndexes[oldIndexSize + i] = index;
    }
    rootElem.value = abi.encode(arrayElmentIndexes);
  }

  /**
   * Get element by index.
   * @param array JSArray
   * @param index the element index
   * @return res element at index
   * @notice When getting value from nested array in multi-dimension array,
   *         it is necessary to set the rootElementIndex to the index that points to the nested array.
   */
  function at(IJSInterpreter.JSArray memory array, uint index) internal pure returns (IJSInterpreter.JSValue memory res) {
    uint[] memory arrayElmentIndexes = array.elements[array.rootElementIndex].arrayElmentIndexes();
    require(index < arrayElmentIndexes.length, 'out of range');
    uint elemIndex = arrayElmentIndexes[index];
    IJSInterpreter.JSArrayElement memory elem = array.elements[elemIndex];
    if (elem.valueType == IJSInterpreter.JSValueType.value_array) {
      res.value = abi.encode(IJSInterpreter.JSArray(array.elements, elemIndex));
    } else {
      res.value = elem.value;
    }
    res.numberSign = elem.numberSign;
    res.valueType = elem.valueType;
  }
  
  function update(IJSInterpreter.JSArray memory array, uint index, IJSInterpreter.JSValue memory value) internal pure {
    uint[] memory arrayElmentIndexes = array.elements[array.rootElementIndex].arrayElmentIndexes();
    require(index < arrayElmentIndexes.length, 'out of range');
    array.elements[arrayElmentIndexes[index]] = _toArrayElement(array, value);
  }
  
  /**
   * Implementing built-in properties for array
   * @param array JSArray
   * @param propName property name
   * @return res property value
   */
  function property(IJSInterpreter.JSArray memory array, string memory propName) internal pure returns (IJSInterpreter.JSValue memory res) {
    res.valueType = IJSInterpreter.JSValueType.value_undefined;
    if (StringUtil.equal(propName, 'length')) {
      res.valueType = IJSInterpreter.JSValueType.value_number;
      res.numberSign = true;
      uint num = JSValueUtil.toWei(array.elements[array.rootElementIndex].arrayElmentIndexes().length);
      res.value = abi.encode(num);
    } else if (StringUtil.equal(propName, 'push')) {
      res.valueType = IJSInterpreter.JSValueType.value_function;
      res.value = abi.encode(IJSInterpreter.JSValueType.value_array, array, propName);
    }
    return res;
  }
  
  /**
   * Implementing built-in methods for array
   * @param array JSArray
   * @param methodName method name
   * @return res method execution result
   */
  function method(IJSInterpreter.JSArray memory array, string memory methodName, IJSInterpreter.JSValue[] memory args) internal pure returns (IJSInterpreter.JSValue memory res) {
    if (StringUtil.equal(methodName, 'push') && args.length == 1) {
      push(array, args);
      res = property(array, 'length');
    } else {
      revert('invalid method');
    }
  }
  
  /**
   * Resize array
   * @param array JSArray
   * @param size new array size
   */
  function resize(IJSInterpreter.JSArray memory array, uint size) internal pure {
    IJSInterpreter.JSArrayElement[] memory newArray = new IJSInterpreter.JSArrayElement[](size);
    for (uint i = 0; i < array.elements.length && i < size; ++i) {
      newArray[i] = array.elements[i];
    }
    array.elements = newArray;
  }

  /**
   * convet JSValuet to JSArrayElement
   * @param value JSValue
   * @return elem JSArrayElement
   */
  function _toArrayElement(IJSInterpreter.JSArray memory array, IJSInterpreter.JSValue memory value) internal pure returns (IJSInterpreter.JSArrayElement memory elem) {
    elem.valueType = value.valueType;
    if (value.valueType == IJSInterpreter.JSValueType.value_array) {
      uint oldSize = array.elements.length;
      IJSInterpreter.JSArray memory valueArray = value.arrayValue();
      uint valueSize = valueArray.elements.length;
      uint additionalSize = valueSize - 1; // ignore root elem
      resize(array, oldSize + additionalSize);
      uint nextElemPos = oldSize;
      for (uint i = 0; i < valueSize; ++i) {
        IJSInterpreter.JSArrayElement memory valueElem = valueArray.elements[i];
        // elems of value will be inserted after elements of array, so shift references in value
        if (valueElem.valueType == IJSInterpreter.JSValueType.value_array) {
          uint[] memory arrayIndexes = valueElem.arrayElmentIndexes();
          for (uint j = 0; j < arrayIndexes.length; ++j) {
            arrayIndexes[j] += (oldSize - 1); // -1 shift for root elem. root must be placed at head
          }
          valueElem.value = abi.encode(arrayIndexes);
        }
        if (i != valueArray.rootElementIndex) { // skip root elem
          array.elements[nextElemPos] = valueElem;
          ++nextElemPos;
        }
      }
      elem.value = valueArray.elements[valueArray.rootElementIndex].value;
    } else {
      elem.value = value.value;
      elem.numberSign = value.numberSign;
    }
  }
}