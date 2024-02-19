// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/interpreter/IJSInterpreter.sol';
import './NumberUtil.sol';
import './JSValueUtil.sol';

library JSObjectPropertyUtil {
  /**
   * decode objectPropertyIndexes value
   * @param property JSObjectProperty whose type is object 
   * @return indexes properties indexes which refer to elements in JSObject.propertieselements
   */
  function objectPropertyIndexes(IJSInterpreter.JSObjectProperty memory property) internal pure returns (uint[] memory indexes) {
    if (property.valueType == IJSInterpreter.JSValueType.value_object) {
      return abi.decode(property.value, (uint[]));
    }
  }
  
  /**
   * decode array value 
   * @param property JSObjectProperty whose type is array
   * @return array JSArray
   */
  function arrayValue(IJSInterpreter.JSObjectProperty memory property) internal pure returns (IJSInterpreter.JSArray memory array) {
    if (property.valueType == IJSInterpreter.JSValueType.value_array) {
      return abi.decode(property.value, (IJSInterpreter.JSArray));
    }
  }
}

library JSObjectImpl {
  using JSObjectPropertyUtil for IJSInterpreter.JSObjectProperty;

  /**
   * create new object
   * @return object
   */
  function newObject() internal pure returns (IJSInterpreter.JSObject memory object) {
    object.properties = new IJSInterpreter.JSObjectProperty[](1);
    IJSInterpreter.JSObjectProperty memory rootProperty;
    rootProperty.valueType = IJSInterpreter.JSValueType.value_object;
    rootProperty.value = abi.encode(new uint[](0));
    object.properties[0] = rootProperty;
    object.rootPropertyIndex = 0;
  }

  /**
   * set property
   * @param object JSObject
   * @param key property key
   * @param value property value
   * @notice In the case of nested object, the rootPropertyIndex specifies
   *         which nest level of the object to add the property to.
   *         When setting the property to nested object, it is necessary to set
   *         the rootPropertyIndex to the index that points to target object.
   */
  function set(
    IJSInterpreter.JSObject memory object,
    string memory key,
    IJSInterpreter.JSValue memory value
  ) internal pure {
    // to object property
    IJSInterpreter.JSObjectProperty memory newProperty;
    newProperty.key = key;
    newProperty.valueType = value.valueType;
    if (newProperty.valueType == IJSInterpreter.JSValueType.value_object) {
      uint oldSize = object.properties.length;
      _concatObject(object, JSValueUtil.objectValue(value));
      // root of nest object
      newProperty.value = object.properties[oldSize].value;
    } else if (newProperty.valueType == IJSInterpreter.JSValueType.value_array) {
      _concatArray(JSValueUtil.arrayValue(value), object);
      newProperty.value = value.value;
    } else {
      newProperty.value = value.value;
      newProperty.numberSign = value.numberSign;
    }

    bytes32 keyHash;
    bytes memory keyBytes = bytes(key);
    assembly {
      keyHash := keccak256(add(keyBytes, 0x20), mload(keyBytes))
    }
    newProperty.keyHash = keyHash;

    // update exisiting property if exists
    uint[] memory objectPropertyIndexes = object.properties[object.rootPropertyIndex].objectPropertyIndexes();
    for (uint i = 0; i < objectPropertyIndexes.length; ++i) {
      uint indexWithOffset = objectPropertyIndexes[i];
      IJSInterpreter.JSObjectProperty memory existingProp = object.properties[indexWithOffset];
      bytes32 propKeyHash = existingProp.keyHash;
      bool found;
      assembly {
        found := eq(keyHash, propKeyHash)
      }
      if (found) {
        object.properties[indexWithOffset] = newProperty;
        return;
      }
    }
    
    // add new property
    uint nextPropIndex = object.properties.length;
    _resize(object, object.properties.length + 1);
    object.properties[nextPropIndex] = newProperty;
    objectPropertyIndexes = NumberUtil.addValue(objectPropertyIndexes, nextPropIndex);
    object.properties[object.rootPropertyIndex].value = abi.encode(objectPropertyIndexes);
  }
  
  /**
   * Get property value by key.
   * @param object JSObject
   * @param key property
   * @return jsValue property value
   * @notice When getting value from nested object, it is necessary to set
   *         the rootPropertyIndex to the index that points to the nested object.
   */
  function getValue(IJSInterpreter.JSObject memory object, string memory key) internal pure returns (IJSInterpreter.JSValue memory) {
    uint[] memory objectPropertyIndexes = object.properties[object.rootPropertyIndex].objectPropertyIndexes();
    bytes32 keyHash;
    bytes memory keyBytes = bytes(key);
    assembly {
      keyHash := keccak256(add(keyBytes, 0x20), mload(keyBytes))
    }
    IJSInterpreter.JSObjectProperty memory existingProp;
    for (uint i = 0; i < objectPropertyIndexes.length; ++i) {
      uint indexWithOffset = objectPropertyIndexes[i];
      existingProp = object.properties[indexWithOffset];
      bytes32 propKeyHash = existingProp.keyHash;
      bool found;
      assembly {
        found := eq(keyHash, propKeyHash)
      }
      if (found) {
        return getValue(object, indexWithOffset); 
      } 
    }

    IJSInterpreter.JSValue memory undefined;
    undefined.valueType = IJSInterpreter.JSValueType.value_undefined;
    return undefined;
  }
  
  /**
   * Get property value by index.
   * @param object JSObject
   * @param index index of properties array
   * @return jsValue property value
   */
  function getValue(IJSInterpreter.JSObject memory object, uint index) internal pure returns (IJSInterpreter.JSValue memory jsValue) {
    IJSInterpreter.JSObjectProperty memory property = object.properties[index];
    jsValue.valueType = property.valueType;
    if (property.valueType == IJSInterpreter.JSValueType.value_object) {
      IJSInterpreter.JSObject memory newObj;
      newObj.properties = object.properties;
      newObj.rootPropertyIndex = index;
      jsValue.value = abi.encode(newObj);
    } else if (property.valueType == IJSInterpreter.JSValueType.value_array) {
      jsValue.value = property.value;
    } else {
      jsValue.value = property.value;
      jsValue.numberSign = property.numberSign;
    }
  }
  
  /**
   * Resize properties array.
   * @param object JSObject
   * @param size new size
   */
  function _resize(IJSInterpreter.JSObject memory object, uint size) private pure {
    IJSInterpreter.JSObjectProperty[] memory newArray = new IJSInterpreter.JSObjectProperty[](size);
    for (uint i = 0; i < object.properties.length && i < size; ++i) {
      newArray[i] = object.properties[i];
    }
    object.properties = newArray;
  }
  
  /**
   * Concat two objects
   * @param dstObject the object to join the srcObject to 
   * @param srcObject the context joined to dstObject
   */
  function _concatObject(IJSInterpreter.JSObject memory dstObject, IJSInterpreter.JSObject memory srcObject) private pure {
    uint indexOffset = dstObject.properties.length;
    uint addtionalSize = srcObject.properties.length;
    _resize(dstObject, indexOffset + addtionalSize);
    for (uint i = 0; i < addtionalSize; ++i) {
      uint index = i + indexOffset;
      IJSInterpreter.JSObjectProperty memory prop = srcObject.properties[i];
      if (prop.valueType == IJSInterpreter.JSValueType.value_object) {
        // props in object2 will be placed after in dstObject, so shift indexes by length of dstObject
        uint[] memory indexes = prop.objectPropertyIndexes();
        for (uint j = 0; j < indexes.length; ++j) {
          indexes[j] += indexOffset;
        }
        prop.value = abi.encode(indexes);
      }
      dstObject.properties[index] = prop;
    }
  }
  
  /**
   * Concat object elements in array
   * @param array JSArray
   * @param object the object to join the array to 
   */
  function _concatArray(IJSInterpreter.JSArray memory array, IJSInterpreter.JSObject memory object) private pure {
    for (uint i = 0; i < array.elements.length; ++i) {
      IJSInterpreter.JSArrayElement memory elem = array.elements[i];
      if (elem.valueType == IJSInterpreter.JSValueType.value_object) {
        _concatObject(object, abi.decode(elem.value, (IJSInterpreter.JSObject)));
      }
    }
  }
}