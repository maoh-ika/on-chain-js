// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IJSLexer.sol';
import '../utf8/IUtf8Char.sol';

/**
 * The interface to regex tokens.
 */
interface IJSRegexLexer {
  /**
   * extract a regex token
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The regex token.
   */
  function readRegexToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) external view returns (IJSLexer.Token memory); 
}