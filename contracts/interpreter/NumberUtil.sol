// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library NumberUtil {
  /**
   * Resize uint array
   * @param array uint array
   * @param size new size
   * @return resized array
   */
  function resize(uint[] memory array, uint size) internal pure returns (uint[] memory) {
    uint[] memory newArray = new uint[](size);
    for (uint i = 0; i < array.length && i < size; ++i) {
      newArray[i] = array[i];
    }
    return newArray;
  }
  
  function addValue(uint[] memory arr, uint value) internal pure returns (uint[] memory newArr) {
    newArr = new uint[](arr.length + 1);
    for (uint i = 0; i < arr.length; ++i) {
      newArr[i] = arr[i];
    }
    newArr[arr.length] = value;
  }

  function exist(uint[] memory arr, uint value) internal pure returns (bool) {
    for (uint i = 0; i < arr.length; ++i) {
      if (arr[i] == value) {
        return true;
      }
    }
    return false;
  }

  function concat(uint[] memory arr1, uint[] memory arr2) internal pure returns (uint[] memory newArr) {
    newArr = resize(arr1, arr1.length + arr2.length);
    for (uint i = 0; i < arr2.length; ++i) {
      newArr[arr1.length + i] = arr2[i];
    }
  }
}