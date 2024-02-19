// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IUtf8Char {
  struct Utf8Char {
    string expression;
    uint code;
    uint size;
  }
}