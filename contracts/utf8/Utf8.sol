// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/utf8/IUtf8Char.sol';
import './Utf8Char.sol';

library Utf8 {
  /**
   * Get next UTF8 character in bytes
   * @param str string byte array
   * @param startPos start position of byte array
   * @return UTF8 character
   */
  function getNextCharacter(bytes calldata str, uint startPos) internal pure returns (IUtf8Char.Utf8Char memory) {
    uint pos = startPos;
    uint code = 0;
    while (pos < str.length) {
      uint8 bits = uint8(str[pos]);
      if (code == 0) {
        // search start byte
        if (_isStartByte(bits)) {
          code = bits;
          pos++;
        }
      } else {
        if (_isStartByte(bits)) {
          // next char reached
          break;
        } else {
          code = (code << 8) | bits;
          pos++;
        }
      }
    }
    return Utf8Char.getByCode(code);
  }

  /**
   * Determine wether the character is number
   * @param code character code
   * @return true if the character is number
   */
  function isDigit(uint code) internal pure returns (bool) {
    return 0x30 /* 0 */ <= code && code <= 0x39 /* 9 */;
  }
  
  /**
   * Determine wether the character is new line 
   * @param code character code
   * @return true if the character is new line
   */
  function isNewLine(uint code) internal pure returns (bool) {
    if (
        code == 0x0a /* lineFeed */ ||
        code == 0x0d /* carriageReturn */ ||
        code == 0xE280A8 /* lineSeparator */ ||
        code == 0xE280A9 /* paragraphSeparator */
    ) {
        return true;
    } else {
        return false;
    }
  }

  /**
   * Determine wether the bits array is UTF8 starting bytes
   * @param bits bits array
   * @return true if the bits array is starting bytes
   */
  function _isStartByte(uint8 bits) private pure returns (bool) {
    uint8 testBits = (bits & 0xF0) >> 4;
    return (0 <= testBits && testBits <= 7) || (12 <= testBits && testBits <= 15);
  }
}