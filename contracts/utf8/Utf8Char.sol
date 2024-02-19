// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/utf8/IUtf8Char.sol';

library Utf8Char {
  /**
   * Get UTF8 character by code
   * @param code character code
   * @return UTF8 character
   * @notice support only ascii, numbers, and partial set of symbols.
   */
  function getByCode(uint code) external pure returns (IUtf8Char.Utf8Char memory) {
    bytes memory expression;
    uint size = 1;
    assembly {
      expression := mload(0x40)

      switch code
      case 0x41 {
        mstore(add(expression, 0x20), 'A')
      }
      case 0x42 {
        mstore(add(expression, 0x20), 'B')
      }
      case 0x43 {
        mstore(add(expression, 0x20), 'C')
      }
      case 0x44 {
        mstore(add(expression, 0x20), 'D')
      }
      case 0x45 {
        mstore(add(expression, 0x20), 'E')
      }
      case 0x46 {
        mstore(add(expression, 0x20), 'F')
      }
      case 0x47 {
        mstore(add(expression, 0x20), 'G')
      }
      case 0x48 {
        mstore(add(expression, 0x20), 'H')
      }
      case 0x49 {
        mstore(add(expression, 0x20), 'I')
      }
      case 0x4A {
        mstore(add(expression, 0x20), 'J')
      }
      case 0x4B {
        mstore(add(expression, 0x20), 'K')
      }
      case 0x4C {
        mstore(add(expression, 0x20), 'L')
      }
      case 0x4D {
        mstore(add(expression, 0x20), 'M')
      }
      case 0x4E {
        mstore(add(expression, 0x20), 'N')
      }
      case 0x4F {
        mstore(add(expression, 0x20), 'O')
      }
      case 0x50 {
        mstore(add(expression, 0x20), 'P')
      }
      case 0x51 {
        mstore(add(expression, 0x20), 'Q')
      }
      case 0x52 {
        mstore(add(expression, 0x20), 'R')
      }
      case 0x53 {
        mstore(add(expression, 0x20), 'S')
      }
      case 0x54 {
        mstore(add(expression, 0x20), 'T')
      }
      case 0x55 {
        mstore(add(expression, 0x20), 'U')
      }
      case 0x56 {
        mstore(add(expression, 0x20), 'V')
      }
      case 0x57 {
        mstore(add(expression, 0x20), 'W')
      }
      case 0x58 {
        mstore(add(expression, 0x20), 'X')
      }
      case 0x59 {
        mstore(add(expression, 0x20), 'Y')
      }
      case 0x5A {
        mstore(add(expression, 0x20), 'Z')
      }
      case 0x61 {
        mstore(add(expression, 0x20), 'a')
      }
      case 0x62 {
        mstore(add(expression, 0x20), 'b')
      }
      case 0x63 {
        mstore(add(expression, 0x20), 'c')
      }
      case 0x64 {
        mstore(add(expression, 0x20), 'd')
      }
      case 0x65 {
        mstore(add(expression, 0x20), 'e')
      }
      case 0x66 {
        mstore(add(expression, 0x20), 'f')
      }
      case 0x67 {
        mstore(add(expression, 0x20), 'g')
      }
      case 0x68 {
        mstore(add(expression, 0x20), 'h')
      }
      case 0x69 {
        mstore(add(expression, 0x20), 'i')
      }
      case 0x6A {
        mstore(add(expression, 0x20), 'j')
      }
      case 0x6B {
        mstore(add(expression, 0x20), 'k')
      }
      case 0x6C {
        mstore(add(expression, 0x20), 'l')
      }
      case 0x6D {
        mstore(add(expression, 0x20), 'm')
      }
      case 0x6E {
        mstore(add(expression, 0x20), 'n')
      }
      case 0x6F {
        mstore(add(expression, 0x20), 'o')
      }
      case 0x70 {
        mstore(add(expression, 0x20), 'p')
      }
      case 0x71 {
        mstore(add(expression, 0x20), 'q')
      }
      case 0x72 {
        mstore(add(expression, 0x20), 'r')
      }
      case 0x73 {
        mstore(add(expression, 0x20), 's')
      }
      case 0x74 {
        mstore(add(expression, 0x20), 't')
      }
      case 0x75 {
        mstore(add(expression, 0x20), 'u')
      }
      case 0x76 {
        mstore(add(expression, 0x20), 'v')
      }
      case 0x77 {
        mstore(add(expression, 0x20), 'w')
      }
      case 0x78 {
        mstore(add(expression, 0x20), 'x')
      }
      case 0x79 {
        mstore(add(expression, 0x20), 'y')
      }
      case 0x7A {
        mstore(add(expression, 0x20), 'z')
      }
      case 0x30 {
        mstore(add(expression, 0x20), '0')
      }
      case 0x31 {
        mstore(add(expression, 0x20), '1')
      }
      case 0x32 {
        mstore(add(expression, 0x20), '2')
      }
      case 0x33 {
        mstore(add(expression, 0x20), '3')
      }
      case 0x34 {
        mstore(add(expression, 0x20), '4')
      }
      case 0x35 {
        mstore(add(expression, 0x20), '5')
      }
      case 0x36 {
        mstore(add(expression, 0x20), '6')
      }
      case 0x37 {
        mstore(add(expression, 0x20), '7')
      }
      case 0x38 {
        mstore(add(expression, 0x20), '8')
      }
      case 0x39 {
        mstore(add(expression, 0x20), '9')
      }
      case 0x09 {
        mstore(add(expression, 0x20), '\t')
      }
      case 0x0a {
        mstore(add(expression, 0x20), 'LF')
      }
      case 0x0d {
        mstore(add(expression, 0x20), 'CR')
      }
      case 0x20 {
        mstore(add(expression, 0x20), " ")
      }
      case 0xC2A0 {
        mstore(add(expression, 0x20), '  ')
        size := 2
      }
      case 0xE280A8 {
        mstore(add(expression, 0x20), '   ')
        size := 3
      }
      case 0xE280A9 {
        mstore(add(expression, 0x20), '   ')
        size := 3
      }
      case 0x21 {
        mstore(add(expression, 0x20), '!')
      }
      case 0x22 {
        mstore(add(expression, 0x20), '\"')
      }
      case 0x23 {
        mstore(add(expression, 0x20), '#')
      }
      case 0x24 {
        mstore(add(expression, 0x20), '$')
      }
      case 0x25 {
        mstore(add(expression, 0x20), '%')
      }
      case 0x26 {
        mstore(add(expression, 0x20), '&')
      }
      case 0x27 {
        mstore(add(expression, 0x20), '\'')
      }
      case 0x28 {
        mstore(add(expression, 0x20), '(')
      }
      case 0x29 {
        mstore(add(expression, 0x20), ')')
      }
      case 0x2A {
        mstore(add(expression, 0x20), '*')
      }
      case 0x2B {
        mstore(add(expression, 0x20), '+')
      }
      case 0x2C {
        mstore(add(expression, 0x20), ',')
      }
      case 0x2D {
        mstore(add(expression, 0x20), '-')
      }
      case 0x2E {
        mstore(add(expression, 0x20), '.')
      }
      case 0x2F {
        mstore(add(expression, 0x20), '/')
      }
      case 0x3A {
        mstore(add(expression, 0x20), ':')
      }
      case 0x3B {
        mstore(add(expression, 0x20), ';')
      }
      case 0x3C {
        mstore(add(expression, 0x20), '<')
      }
      case 0x3D {
        mstore(add(expression, 0x20), '=')
      }
      case 0x3E {
        mstore(add(expression, 0x20), '>')
      }
      case 0x3F {
        mstore(add(expression, 0x20), '?')
      }
      case 0x40 {
        mstore(add(expression, 0x20), '@')
      }
      case 0x5B {
        mstore(add(expression, 0x20), '[')
      }
      case 0x5C {
        mstore(add(expression, 0x20), '\\')
      }
      case 0x5D {
        mstore(add(expression, 0x20), ']')
      }
      case 0x5E {
        mstore(add(expression, 0x20), '^')
      }
      case 0x5F {
        mstore(add(expression, 0x20), '_')
      }
      case 0x60 {
        mstore(add(expression, 0x20), '`')
      }
      case 0x7B {
        mstore(add(expression, 0x20), '{')
      }
      case 0x7C {
        mstore(add(expression, 0x20), '|')
      }
      case 0x7D {
        mstore(add(expression, 0x20), '}')
      }
      case 0x7E {
        mstore(add(expression, 0x20), '~')
      }
      case 0xC2A5 { // ¥
        mstore(add(expression, 0x20), ' ')
        size := 2
      }
      default { size:= 0 }
      mstore(expression, size)
      mstore(0x40, add(expression, mul(0x20, 2)))
    }

    IUtf8Char.Utf8Char memory char = IUtf8Char.Utf8Char({ expression: string(expression), code: code, size: size});
    return char;
  }
  
}