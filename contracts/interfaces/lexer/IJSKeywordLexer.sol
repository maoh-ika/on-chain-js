// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IJSLexer.sol";

/**
 * The interface to extract reserved keyword tokens.
 */
interface IJSKeywordLexer {
  enum KeywordCode {
    _await, // 0
    _break, // 1
    _case, // 2
    _catch, // 3
    _class, // 4
    _const, // 5
    _continue, // 6
    _debugger, // 7
    _default, // 8
    _delete, // 9
    _do, // 10
    _else, // 11
    _enum, // 12
    _export, // 13
    _extends, // 14
    _false, // 15
    _finally, // 16
    _for, // 17
    _function, // 18
    _if, // 19
    _import, // 20
    _in, // 21
    _instanceof, // 22
    _new, // 23
    _null, // 24
    _return, // 25
    _super, // 26
    _switch, // 27
    _this, // 28
    _throw, // 29
    _true, // 30
    _try, // 31
    _typeof, // 32
    _var, // 33
    _void, // 34
    _while, // 35
    _with, // 36
    _yield, // 37
    _undefined, // 38
    _let, // 39
    _static, // 40
    _implements, // 41
    _interface, // 42
    _package, // 43
    _private, // 44
    _protected, // 45
    _public // 46
  }

  /**
   * Get TokenAttribute for specified keyword
   * @param word keyword string.
   * @return TokenAttribute for the word.
   */
  function getKeywordAttr(string calldata word) external view returns (IJSLexer.TokenAttrs memory);
}
