// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IJSLexer.sol';
import '../utf8/IUtf8Char.sol';

/**
 * The interface to string tokens.
 */
interface IJSStringLexer {
  /**
   * extract a string token starting with single or double quote
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param quote quote character enclosing the string.
   * @return The string token.
   */
  function readStringToken(
    bytes calldata source,
    IJSLexer.Context memory context,
    IUtf8Char.Utf8Char calldata quote
  ) external view returns (IJSLexer.Token memory); 
}