// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//import "hardhat/console.sol";
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/interpreter/IJSInterpreter.sol';
import '../interfaces/interpreter/IGlobalFunction.sol';
import '../interfaces/token/IExeToken.sol';
import './JSValueUtil.sol';
import './JSObjectImpl.sol';
import './JSArrayImpl.sol';
import './StringUtil.sol';
import './NumberUtil.sol';

/**
 * access control for implementation update
 */
contract GlobalFunctionAdmin is Ownable {
  // address with permission to update state
  address public admin;
  // ExeToken interface
  IExeToken public exeToken;

  constructor(IExeToken _exeToken) {
    admin = owner();
    exeToken = _exeToken;
  }
  
  /**
   * Ristrict access to admin
   */
  modifier onlyAdmin() {
    require(owner() == msg.sender || admin == msg.sender, 'only admin');
    _;
  }

  /**
   * Set admin address
   */
  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
  }

  /**
   * Update code token implementation
   */
  function setexeToken(IExeToken _exeToken) external onlyAdmin {
    exeToken = _exeToken;
  }
}
/**
 * Call external contract. Encode calldata passed to the contract and decode return value.
 */
contract GlobalFunction is GlobalFunctionAdmin, IGlobalFunction{
  using StringUtil for string;
  using JSValueUtil for IJSInterpreter.JSValue;
  using JSObjectImpl for IJSInterpreter.JSObject;
  using JSArrayImpl for IJSInterpreter.JSArray;
  using JSArrayElementUtil for IJSInterpreter.JSArrayElement;
  using JSObjectPropertyUtil for IJSInterpreter.JSObjectProperty;
  
  constructor(IExeToken _exeToken) GlobalFunctionAdmin(_exeToken ) {}

  /**
   * call global function.
   * @param funcName function name
   * @param argValues arguments passed to the function
   * @param traceDependencies the flag indicating tracing enabled
   * @return res result value
   * @return contractDependees external contract dependees
   * @return exeTokenDependees extennal exe token dependees
   */
  function call(
    string calldata funcName,
    IJSInterpreter.JSValue[] calldata argValues,
    bool traceDependencies
  ) external view returns (IJSInterpreter.JSValue memory res, uint[] memory contractDependees, uint[] memory exeTokenDependees) {
    if (StringUtil.equal(funcName, 'executeToken')) {
      uint argCount = argValues.length - 1;
      IJSInterpreter.JSValue[] memory args = new IJSInterpreter.JSValue[](argCount);
      for (uint i = 0; i < argCount; ++i) {
        args[i] = argValues[i + 1];
      }
      uint tokenId = JSValueUtil.toRaw(argValues[0].numberValue());
      res = exeToken.execute(tokenId, args);
      if (traceDependencies) {
        exeTokenDependees = NumberUtil.addValue(exeTokenDependees, tokenId);
      }
    } else if (StringUtil.equal(funcName, 'staticcallContract')) {
      uint argCount = argValues.length - 3;
      IJSInterpreter.JSValue[] memory args = new IJSInterpreter.JSValue[](argCount);
      for (uint i = 0; i < argCount; ++i) {
        args[i] = argValues[i + 3];
      }
      uint addrNum = JSValueUtil.toRaw(argValues[0].numberValue());
      address addr = address(uint160(addrNum));
      res = _staticcall(
        addr,
        argValues[1].stringValue(),
        argValues[2],
        args
      );
      if (traceDependencies && addrNum > 0) {
        contractDependees = NumberUtil.addValue(contractDependees, addrNum);
      }
    } else {
      res.valueType = IJSInterpreter.JSValueType.value_invalid;
    }
  }

  /**
   * call contract using staticall.. Encode calldata passed to the contract and decode return value.
   * @param addr address of contract
   * @param sig signature of the method to execute, which is according to Solidity abi specification.
   * @param retType structure definition of retun value in Solidity json abi format.
   * @return res result value of contract execution.
   */
  function _staticcall(
    address addr,
    string memory sig,
    IJSInterpreter.JSValue calldata retType,
    IJSInterpreter.JSValue[] memory args
  ) private view returns (IJSInterpreter.JSValue memory res) {
    // encode method selector and arguments
    bytes memory payload = bytes.concat(abi.encodeWithSignature(sig), _encode(args));

    // call contract
    (bool success, bytes memory result) = addr.staticcall(payload);
    if (!success) {
      //console.log('failed');
      return res;
    }

    // decode return value   
    if (retType.valueType == IJSInterpreter.JSValueType.value_array) {
      bytes memory data;
      assembly { data := add(result, 32) } // skip length
      res = _decodeArray(data, retType);
    } else if (retType.valueType == IJSInterpreter.JSValueType.value_object) {
      bytes memory data;
      assembly { data := add(result, 32) } // skip length
      // store resolved types and names to avoid decode JSObject twice in the case of tuple[]
      string[] memory typesCache;
      string[] memory namesCache;
      (res, typesCache, namesCache) = _decodeObject(data, 0, retType, typesCache, namesCache);
    } else {
      res.valueType = IJSInterpreter.JSValueType.value_undefined;
    }
  }
  
  /**
   * Decode abi encoded array data 
   * @param data abi encoded data
   * @param retTypeArray structure definition of retun value in Solidity json abi format
   * @return decodedValue decoded value
   */
  function _decodeArray(bytes memory data, IJSInterpreter.JSValue memory retTypeArray) private view returns (IJSInterpreter.JSValue memory decodedValue) {
    IJSInterpreter.JSArray memory components = retTypeArray.arrayValue();
    IJSInterpreter.JSValue[] memory decodedValues;
    string[] memory typesCache;
    string[] memory namesCache;
    (decodedValues, typesCache, namesCache) = _decodeComponents(data, components, typesCache, namesCache);
    IJSInterpreter.JSArray memory decodedArray;
    decodedArray.push(decodedValues);
    decodedValue.value = abi.encode(decodedArray);
    decodedValue.valueType = IJSInterpreter.JSValueType.value_array;
  }

  /**
   * Decode abi encoded struct data 
   * @param data abi encoded data
   * @param retTypeObj structure definition of retun value in Solidity json abi format
   * @param typesCache types of data to be decoded
   * @param namesCache names of data to be decoded
   * @return decodedValue decoded value
   * @return types cache extracted from retTypeObj
   * @return names cache extracted from retTypeObj
   */
  function _decodeObject(
    bytes memory data,
    uint offsetPos,
    IJSInterpreter.JSValue memory retTypeObj,
    string[] memory typesCache,
    string[] memory namesCache
  ) private view returns (IJSInterpreter.JSValue memory decodedValue, string[] memory , string[] memory) {
    IJSInterpreter.JSObject memory obj = retTypeObj.objectValue();
    string memory objType = obj.getValue('type').stringValue();
    if (objType.equal('tuple[]')) {
      bytes memory dataPos;
      assembly { dataPos := add(data, mload(add(data, offsetPos))) }
      IJSInterpreter.JSArray memory decodedArray;
      bytes memory tupleData;
      uint tupleLength;
      assembly {
        tupleLength := mload(dataPos)
        tupleData := add(dataPos, 32) // skip length
      }

      // if the components of the tuple include only static data types, there is no offset to tuple data area and
      // all values are placed direc
      IJSInterpreter.JSArray memory componentArray = obj.getValue('components').arrayValue();
      bool isStatic = _isStaticTuple(componentArray);
      uint componentLength = componentArray.elements[componentArray.rootElementIndex].arrayElmentIndexes().length;

      IJSInterpreter.JSValue memory newType;
      newType.valueType = IJSInterpreter.JSValueType.value_string;
      newType.value = isStatic ? abi.encode('static_tuple') : abi.encode('tuple');
      obj.set('type', newType);
      IJSInterpreter.JSValue memory newRetTypeObj;
      newRetTypeObj.valueType = IJSInterpreter.JSValueType.value_object;
      newRetTypeObj.value = abi.encode(obj);
      IJSInterpreter.JSValue[] memory elems = new IJSInterpreter.JSValue[](tupleLength);
      for (uint tupleIdx = 0; tupleIdx < tupleLength; ++tupleIdx) {
        uint offset = isStatic ? componentLength * tupleIdx * 32 : 32 * tupleIdx;
        IJSInterpreter.JSValue memory decodedTuple;
        (decodedTuple, typesCache, namesCache) = _decodeObject(tupleData, offset, newRetTypeObj, typesCache, namesCache);
        elems[tupleIdx].value = decodedTuple.value;
        elems[tupleIdx].valueType = decodedTuple.valueType;
      }
      decodedArray.push(elems);
      decodedValue.value = abi.encode(decodedArray);
      decodedValue.valueType = IJSInterpreter.JSValueType.value_array;
    } else if (objType.equal('tuple')) {
      bytes memory dataPos;
      assembly { dataPos := add(data, mload(add(data, offsetPos))) }
      IJSInterpreter.JSObject memory decodedObject = JSObjectImpl.newObject();
      IJSInterpreter.JSArray memory componentArray = obj.getValue('components').arrayValue();
      IJSInterpreter.JSValue[] memory decodedValues;
      (decodedValues, typesCache, namesCache) = _decodeComponents(dataPos, componentArray, typesCache, namesCache);
      for (uint i = 0; i < decodedValues.length; ++i) {
        decodedObject.set(namesCache[i], decodedValues[i]);
      }
      decodedValue.value = abi.encode(decodedObject);
      decodedValue.valueType = IJSInterpreter.JSValueType.value_object;
    } else if (objType.equal('static_tuple')) {
      bytes memory dataPos;
      assembly { dataPos := add(data, offsetPos) }
      IJSInterpreter.JSObject memory decodedObject = JSObjectImpl.newObject();
      IJSInterpreter.JSArray memory componentArray = obj.getValue('components').arrayValue();
      IJSInterpreter.JSValue[] memory decodedValues;
      (decodedValues, typesCache, namesCache) = _decodeComponents(dataPos, componentArray, typesCache, namesCache);
      for (uint i = 0; i < decodedValues.length; ++i) {
        decodedObject.set(namesCache[i], decodedValues[i]);
      }
      decodedValue.value = abi.encode(decodedObject);
      decodedValue.valueType = IJSInterpreter.JSValueType.value_object;
    } else {
      IJSInterpreter.JSValue[] memory objValue = new IJSInterpreter.JSValue[](1);
      objValue[0] = retTypeObj;
      IJSInterpreter.JSArray memory componentArray;
      componentArray.push(objValue);
      IJSInterpreter.JSValue[] memory decodedValues;
      (decodedValues, typesCache, namesCache) = _decodeComponents(data, componentArray, typesCache, namesCache);
      decodedValue = decodedValues[0];
    }
    return (decodedValue, typesCache, namesCache);
  }
  
  /**
   * Decode abi encoded tuple data 
   * @param data abi encoded data
   * @param componentArray type definitions correspoinding to 'components' attribute in abi json fomat 
   * @param typesCache types of data to be decoded
   * @param namesCache names of data to be decoded
   * @return decodedValues decoded values
   * @return types cache extracted from componentArray
   * @return names cache extracted from componentArray
   */
  function _decodeComponents(
    bytes memory data,
    IJSInterpreter.JSArray memory componentArray,
    string[] memory typesCache,
    string[] memory namesCache
  ) private view returns (IJSInterpreter.JSValue[] memory decodedValues, string[] memory, string[] memory) { 
    uint length = componentArray.elements[componentArray.rootElementIndex].arrayElmentIndexes().length;
    decodedValues = new IJSInterpreter.JSValue[](length);
    bool useCached = true;
    if (typesCache.length == 0) {
      typesCache = new string[](length);
      namesCache = new string[](length);
      useCached = false;
    }
    for (uint arrIdx = 0; arrIdx < length; ++arrIdx) {
      IJSInterpreter.JSValue memory propValue;
      IJSInterpreter.JSValue memory typeDef = componentArray.at(arrIdx);
      string memory typeValue = useCached ? typesCache[arrIdx] : typeDef.objectValue().getValue('type').stringValue();
      string memory nameValue;
      if (useCached) {
        nameValue = namesCache[arrIdx];
      } else {
        IJSInterpreter.JSValue memory name = typeDef.objectValue().getValue('name');
        nameValue = name.valueType != IJSInterpreter.JSValueType.value_undefined ? name.stringValue() : '';
      }
      //console.log('TYPE %s', typeValue);
      //console.log('NAME %s', nameValue);
      if (typeValue.equal('uint256')) {
        propValue.valueType = IJSInterpreter.JSValueType.value_number;
        propValue.numberSign = true;
        uint val;
        assembly { val:= mload(add(data, mul(32, arrIdx))) }
        propValue.value = abi.encode(JSValueUtil.toWei(val));
      } else if (typeValue.equal('uint256[]')) {
        IJSInterpreter.JSArray memory array;
        _readArray(data, arrIdx, array, IJSInterpreter.JSValueType.value_number);
        propValue.valueType = IJSInterpreter.JSValueType.value_array;
        propValue.value = abi.encode(array);
      } else if (typeValue.equal('string')) {
        propValue.valueType = IJSInterpreter.JSValueType.value_string;
        string memory val = string(_readBytes(data, arrIdx));
        propValue.value = abi.encode(val);
      } else if (typeValue.equal('bytes')) {
        propValue.valueType = IJSInterpreter.JSValueType.value_bytes;
        propValue.value = _readBytes(data, arrIdx);
      } else if (typeValue.equal('bool')) {
        propValue.valueType = IJSInterpreter.JSValueType.value_boolean;
        propValue.numberSign = true;
        bool val;
        assembly { val:= mload(add(data, mul(32, arrIdx))) }
        propValue.value = abi.encode(val);
      } else if (typeValue.equal('bool[]')) {
        IJSInterpreter.JSArray memory array;
        _readArray(data, arrIdx, array, IJSInterpreter.JSValueType.value_boolean);
        propValue.valueType = IJSInterpreter.JSValueType.value_array;
        propValue.value = abi.encode(array);
      } else if (typeValue.equal('address')) {
        propValue.valueType = IJSInterpreter.JSValueType.value_string;
        uint val;
        assembly { val:= mload(add(data, mul(32, arrIdx))) }
        propValue.value = abi.encode(_toHexString(val));
      } else if (typeValue.equal('tuple')) {
        propValue.valueType = IJSInterpreter.JSValueType.value_object;
        IJSInterpreter.JSValue memory tupleValue;
        string[] memory types; 
        string[] memory names;
        (tupleValue, types, names) = _decodeObject(data, arrIdx * 32, typeDef, types, names);
        propValue.value = tupleValue.value;
      } else if (typeValue.equal('tuple[]')) {
        propValue.valueType = IJSInterpreter.JSValueType.value_array;
        IJSInterpreter.JSValue memory arrayValue;
        string[] memory types; 
        string[] memory names;
        (arrayValue, types, names) = _decodeObject(data, arrIdx * 32, typeDef, types, names);
        propValue.value = arrayValue.value;
      } else {
        revert('unsupported return type');
      }
      typesCache[arrIdx] = typeValue;
      namesCache[arrIdx] = nameValue;
      decodedValues[arrIdx] = propValue;
    }
    return (decodedValues, typesCache, namesCache);
  }

  /**
   * Extract a "bytes" value from abi encoded bytes array
   * @param data abi encoded bytes array 
   * @param offset starting point in data array
   * @return val bytes value
   */
  function _readBytes(bytes memory data, uint offset) private pure returns (bytes memory val) {
    assembly {
      let strPos := add(data, mload(add(data, mul(32, offset))))
      let strLen := mload(strPos)
      val := mload(0x40)
      mstore(val, strLen)
      let words := div(add(strLen, 31), 32)
      let dstPos := add(val, 32)
      let srcPos := add(strPos, 32)
      for { let idx := 0 } lt(idx, words) { idx := add(idx, 1) } {
        let pos := mul(idx, 32)
        mstore(add(dstPos, pos), mload(add(srcPos, pos)))
      }
      mstore(0x40, add(val, add(mul(words, 32), 64)))
    }
  }
  
  /**
   * Extract array elements from abi encoded bytes array
   * @param data abi encoded bytes array 
   * @param offset starting point in data array
   * @param array array to be added elements into
   * @param elemType value type of element
   */
  function _readArray(bytes memory data, uint offset, IJSInterpreter.JSArray memory array, IJSInterpreter.JSValueType elemType) private pure {
    uint elemCount;
    uint elemHeadPos;
    assembly {
      let arrPos := add(data, mload(add(data, mul(32, offset))))
      elemCount := mload(arrPos)
      elemHeadPos := add(arrPos, 32)
    }
    IJSInterpreter.JSValue[] memory elems = new IJSInterpreter.JSValue[](elemCount);
    for (uint i = 0; i < elemCount; ++i) {
      uint value;
      assembly {
        value := mload(add(elemHeadPos, mul(i, 32)))
      }
      elems[i].valueType = elemType;
      elems[i].value = elemType == IJSInterpreter.JSValueType.value_number ?
        abi.encode(JSValueUtil.toWei(value)) :
        abi.encode(value);
      elems[i].numberSign = true;
    }
    array.push(elems);
  }
  
  /**
   * encode values into abi encoded byte array.
   * @param values values to encode
   * @return encodedValue encoded value
   */
  function _encode(IJSInterpreter.JSValue[] memory values) private view returns (bytes memory encodedValue) {
    // header part
    bytes[] memory dataBytes = new bytes[](values.length);
    uint dataCount;
    uint offset = 32 * values.length;
    for (uint i = 0; i < values.length; ++i) {
      IJSInterpreter.JSValue memory arg = values[i];
      if (arg.valueType == IJSInterpreter.JSValueType.value_number) {
        encodedValue= bytes.concat(encodedValue, abi.encode(JSValueUtil.toRaw(arg.numberValue())));
      } else if (arg.valueType == IJSInterpreter.JSValueType.value_boolean) {
        encodedValue= bytes.concat(encodedValue, abi.encode(arg.boolValue()));
      } else if (arg.valueType == IJSInterpreter.JSValueType.value_string || arg.valueType == IJSInterpreter.JSValueType.value_numberString) {
        //console.log('%s data offset is %d', arg.stringValue(), offset);
        encodedValue= bytes.concat(encodedValue, abi.encode(offset));
        bytes memory stringData = _skipHeader(abi.encode(arg.stringValue()));
        offset += stringData.length;
        dataBytes[dataCount++] = stringData;
      } else if (arg.valueType == IJSInterpreter.JSValueType.value_array) {
        //console.log('array data offset is %d', offset);
        encodedValue= bytes.concat(encodedValue, abi.encode(offset));
        bytes memory arrData;
        IJSInterpreter.JSArray memory arrayValue = arg.arrayValue();
        uint size = arrayValue.elements[arrayValue.rootElementIndex].arrayElmentIndexes().length;
        if (size == 0) {
          int[] memory empty;
          arrData = _skipHeader(abi.encode(empty));
        } else {
          IJSInterpreter.JSValue memory first = JSArrayImpl.at(arrayValue, 0);
          if (first.valueType == IJSInterpreter.JSValueType.value_number) { // array of number
            int[] memory array = new int[](size);
            int sign = (first.numberSign ? int(1) : -1);
            array[0] = int(JSValueUtil.toRaw(first.numberValue())) * sign;
            for (uint a = 1; a < size; ++a) {
              IJSInterpreter.JSValue memory val = JSArrayImpl.at(arrayValue, a);
              sign = (val.numberSign ? int(1) : -1);
              array[a] = int(JSValueUtil.toRaw(val.numberValue())) * sign;
            }
            arrData = _skipHeader(abi.encode(array));
          } else if (first.valueType == IJSInterpreter.JSValueType.value_boolean) { // array of bool
            bool[] memory array = new bool[](size);
            array[0] = first.boolValue();
            for (uint a = 1; a < size; ++a) {
              IJSInterpreter.JSValue memory val = JSArrayImpl.at(arrayValue, a);
              array[a] = val.boolValue();
            }
            arrData = _skipHeader(abi.encode(array));
          } else if (first.valueType == IJSInterpreter.JSValueType.value_string) { // array of string
            string[] memory array = new string[](size);
            array[0] = first.stringValue();
            for (uint a = 1; a < size; ++a) {
              IJSInterpreter.JSValue memory val = JSArrayImpl.at(arrayValue, a);
              array[a] = val.stringValue();
            }
            arrData = _skipHeader(abi.encode(array));
          } else if (first.valueType == IJSInterpreter.JSValueType.value_object) { // array of object
            IJSInterpreter.JSValue[] memory array = new IJSInterpreter.JSValue[](size);
            array[0] = first;
            for (uint a = 1; a < size; ++a) {
              array[a] = JSArrayImpl.at(arrayValue, a);
            }
            arrData = _encode(array);
            arrData = bytes.concat(abi.encode(size), arrData);
          } else if (first.valueType == IJSInterpreter.JSValueType.value_array) { // array of array
            IJSInterpreter.JSValue[] memory innerArgs = new IJSInterpreter.JSValue[](size);
            for (uint a = 0; a < size; ++a) {
              innerArgs[a] = JSArrayImpl.at(arrayValue, a);
            }
            arrData = _encode(innerArgs);
            arrData = bytes.concat(abi.encode(size), arrData);
          }
        }
        offset += arrData.length;
        dataBytes[dataCount++] = arrData;
      } else if (arg.valueType == IJSInterpreter.JSValueType.value_object) {
        //console.log('object data offset is %d', offset);
        IJSInterpreter.JSObject memory objectValue = arg.objectValue();
        uint[] memory propIndexes = objectValue.properties[objectValue.rootPropertyIndex].objectPropertyIndexes();
        IJSInterpreter.JSValue[] memory innerArgs = new IJSInterpreter.JSValue[](propIndexes.length);
        bool needDataOffset;
        for (uint p = 0; p < propIndexes.length; ++p) {
          IJSInterpreter.JSValue memory propValue = JSObjectImpl.getValue(objectValue, propIndexes[p]);
          innerArgs[p] = propValue;
          if (propValue.valueType != IJSInterpreter.JSValueType.value_number && propValue.valueType != IJSInterpreter.JSValueType.value_boolean) {
            needDataOffset = true;
          }
        }
        if (needDataOffset) {
          encodedValue= bytes.concat(encodedValue, abi.encode(offset));
          bytes memory objData = _encode(innerArgs);
          offset += objData.length;
          dataBytes[dataCount++] = objData;
        } else {
          bytes memory objData = _encode(innerArgs);
          encodedValue= bytes.concat(encodedValue, objData); // write values imediately
        }
      } else if (arg.valueType == IJSInterpreter.JSValueType.value_bytes) {
        dataBytes[dataCount++] = arg.value;
      }
    }
    // data part
    for (uint i = 0; i < dataCount; ++i) {
      encodedValue= bytes.concat(encodedValue, dataBytes[i]);
    }
  }
  
  /**
   * skip header part of abi encoded array and extraact data part 
   * @param encodedArray abi encoded array
   * @return data extracted data part
   */
  function _skipHeader(bytes memory encodedArray) private pure returns (bytes memory data) {
    assembly {
      let dataLen := sub(mload(encodedArray), 32) // skip header
      data := mload(0x40)
      mstore(data, dataLen)
      let words := div(add(dataLen, 31), 32)
      let dstPos := add(data, 32)
      let srcPos := add(encodedArray, 64) // skip length and header
      for { let idx := 0 } lt(idx, words) { idx := add(idx, 1) } {
        let pos := mul(idx, 32)
        mstore(add(dstPos, pos), mload(add(srcPos, pos)))
      }
      mstore(0x40, add(data, add(mul(words, 32), 64)))
    }
  }

  /**
   * Check if all the components of the tuple are static data type.
   * @param componentArray type definitions correspoinding to 'components' attribute in abi json fomat 
   * @return return true if the tuple is static data type
   */
  function _isStaticTuple(IJSInterpreter.JSArray memory componentArray) private pure returns (bool) {
    uint length = componentArray.elements[componentArray.rootElementIndex].arrayElmentIndexes().length;
    for (uint arrIdx = 0; arrIdx < length; ++arrIdx) {
      IJSInterpreter.JSValue memory typeDef = componentArray.at(arrIdx);
      string memory typeValue = typeDef.objectValue().getValue('type').stringValue();
      if (!typeValue.equal('uint256') && !typeValue.equal('bool')) {
        return false;
      }
    }
    return true;
  }

  /**
   * convert integer to hex string
   * @param value integer
   * @return string hex string
   */
  function _toHexString(uint value) internal pure returns (string memory) {
    bytes memory strBytes = new bytes(40);
    for (uint i = 0; i < 20; ++i) {
      uint8 charInt = uint8(value / (2 ** ( 8 * (19 - i))));
      uint8 charHi = charInt / 16;
      uint8 charLow = charInt - 16 * charHi;
      strBytes[2 * i] = _toByte(charHi);
      strBytes[2 * i + 1] = _toByte(charLow);            
    }
    return string.concat('0x', string(strBytes));
  }

  /**
   * convert integer to hex string
   * @param charInt char code
   * @return char byte
   */
  function _toByte(uint8 charInt) internal pure returns (bytes1) {
    return charInt < 10 ? bytes1(charInt + 0x30) :  bytes1(charInt + 0x57);
  }

//  function _print(bytes memory data, uint sigSize) private view {
//    console.log('########################');
//    uint paylen;
//    uint mem1;
//    uint mem2;
//    uint mem3;
//    uint mem4;
//    uint mem5;
//    uint mem6;
//    uint mem7;
//    uint mem8;
//    uint mem9;
//    uint mem10;
//    uint mem11;
//    uint mem12;
//    uint mem13;
//    uint mem14;
//    uint mem15;
//    assembly {
//      paylen := mload(data)
//      let head := add(data, add(32, sigSize))
//      mem1 := mload(head)
//      mem2 := mload(add(head, mul(32, 1)))
//      mem3 := mload(add(head, mul(32, 2)))
//      mem4 := mload(add(head, mul(32, 3)))
//      mem5 := mload(add(head, mul(32, 4)))
//      mem6 := mload(add(head, mul(32, 5)))
//      mem7 := mload(add(head, mul(32, 6)))
//      mem8 := mload(add(head, mul(32, 7)))
//      mem9 := mload(add(head, mul(32, 8)))
//      mem10 := mload(add(head, mul(32, 9)))
//      mem11 := mload(add(head, mul(32, 10)))
//      mem12 := mload(add(head, mul(32, 11)))
//      mem13 := mload(add(head, mul(32, 12)))
//      mem14 := mload(add(head, mul(32, 13)))
//      mem15 := mload(add(head, mul(32, 14)))
//    }
//    console.log('-32 %d', paylen);
//    console.log('-64 %d', mem1);
//    console.log('-96 %d', mem2);
//    console.log('-128 %d', mem3);
//    console.log('-160 %d', mem4);
//    console.log('-192 %d', mem5);
//    console.log('-224 %d', mem6);
//    console.log('-256 %d', mem7);
//    console.log('-288 %d', mem8);
//    console.log('-320 %d', mem9);
//    console.log('-352 %d', mem10);
//    console.log('-384 %d', mem11);
//    console.log('-416 %d', mem12);
//    console.log('-448 %d', mem13);
//    console.log('-480 %d', mem14);
//    console.log('-512 %d', mem15);
//  }
}