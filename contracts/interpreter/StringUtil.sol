// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library StringUtil {
  /**
   * Extract substring
   * @param str original string
   * @param startIndex start poistion of substring
   * @param endIndex end poistion of substring
   */
  function substring(string calldata  str, uint startIndex, uint endIndex) external pure returns (string memory) {
    bytes calldata src = bytes(str);
    bytes memory sub = new bytes(endIndex - startIndex);
    for(uint i = startIndex; i < endIndex; ++i) {
        sub[i - startIndex] = src[i];
    }
    return string(sub);
  }

  /**
   * Compare two strings for equality
   * @param str1 the string
   * @param str2 the other
   * @return res  true if the strings are the same
   */
  function equal(string memory str1, string memory str2) internal pure returns (bool res) {
    assembly {
      let len1 := mload(str1)
      let len2 := mload(str2)
      if eq(len1, len2) {
        res := true
        let words := div(add(len1, 31), 32)
        let offset1 := add(str1, 32)
        let offset2 := add(str2, 32)
        for { let i := 0 } and(lt(i, words), res) { i := add(i, 1) } {
          let offset := mul(i, 32)
          res := eq(mload(add(offset1, offset)), mload(add(offset2, offset)))
        }
      }
    }
  }
}