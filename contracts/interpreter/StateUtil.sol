// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/interpreter/IJSInterpreter.sol';
import '../interpreter/JSValueUtil.sol';
import '../interpreter/StringUtil.sol';

library StateUtil {
  /**
   * Get identifier state by name
   * @param state interpretation state
   * @param name identifier name
   * @return identifier state
   */
  function getIdentifierState(IJSInterpreter.State memory state, string memory name) internal pure returns (IJSInterpreter.IdentifierState memory) {
    bytes memory nameBytes = bytes(name);
    bytes32 nameHash;
    assembly {
      nameHash := keccak256(add(nameBytes, 0x20), mload(nameBytes))
    }
    for (uint256 i = 0; i < state.identifierStates.length; ++i) {
      bytes32 stateHash = state.identifierStates[i].hash;
      bool found;
      assembly {
        found := eq(stateHash, nameHash)
      }
      if (found) {
        return state.identifierStates[i];
      }
    }
    // undefiend identifier. return state with identifier index 0.
    IJSInterpreter.IdentifierState memory undefined;
    undefined.name = name;
    undefined.value.value = abi.encode(name);
    undefined.value.valueType = IJSInterpreter.JSValueType.value_string;
    return undefined;
  }
  
  /**
   * Get new identifier state
   * @param state interpretation state
   * @param name identifier name
   * @param value the value tied to the identifier
   * @return identifier state
   */
  function setIdentifierState( IJSInterpreter.State memory state, string memory name, IJSInterpreter.JSValue memory value) internal pure returns (IJSInterpreter.IdentifierState memory) {
    value.identifierIndex = state.identifierStates.length;
    bytes memory nameBytes = bytes(name);
    bytes32 nameHash;
    assembly {
      nameHash := keccak256(add(nameBytes, 0x20), mload(nameBytes))
    }
    IJSInterpreter.IdentifierState memory idState = IJSInterpreter.IdentifierState({
      name: name,
      hash: nameHash,
      value: value
    });
    resize(state, state.identifierStates.length + 1);
    state.identifierStates[value.identifierIndex] = idState;
    return idState;
  }

  /**
   * Update existing identifier state
   * @param state interpretation state
   * @param index identifier index
   * @param value new value
   */
  function updateIdentifierState(IJSInterpreter.State memory state, uint index, IJSInterpreter.JSValue memory value) internal pure {
    require(index > 0, 'index 0 is reserved');
    IJSInterpreter.IdentifierState memory idState = state.identifierStates[index];
    idState.value = value;
    idState.value.identifierIndex = index;
    state.identifierStates[index] = idState;
  }
  
  /**
   * Resize identifier array
   * @param state interpretation state
   * @param size new size
   */
  function resize(IJSInterpreter.State memory state, uint size) internal pure {
    IJSInterpreter.IdentifierState[] memory newArray = new IJSInterpreter.IdentifierState[](size);
    for (uint32 i = 0; i < state.identifierStates.length && i < size; i++) {
      newArray[i] = state.identifierStates[i];
    }
    state.identifierStates = newArray;
  }
  
  /**
   * Set declared function
   */
  function setDeclaredFunction(IJSInterpreter.State memory state, string memory name, uint nodeId) internal pure {
    uint oldSize = state.declaredFunctions.length;
    IJSInterpreter.DeclaredFunction memory decl = IJSInterpreter.DeclaredFunction({
      name: name,
      rootNodeIndex: nodeId
    });
     
    IJSInterpreter.DeclaredFunction[] memory newArray = new IJSInterpreter.DeclaredFunction[](oldSize + 1);
    for (uint32 i = 0; i < state.declaredFunctions.length; ++i) {
      newArray[i] = state.declaredFunctions[i];
    }
    state.declaredFunctions = newArray;
    state.declaredFunctions[oldSize] = decl;
  }
  
  function getDeclaredFunction(IJSInterpreter.State memory state, string memory name) internal pure returns (uint rootNodeId) {
    for (uint32 i = 0; i < state.declaredFunctions.length; ++i) {
      if (StringUtil.equal(state.declaredFunctions[i].name, name)) {
        return state.declaredFunctions[i].rootNodeIndex;
      }
    }
    return 0;
  }
}