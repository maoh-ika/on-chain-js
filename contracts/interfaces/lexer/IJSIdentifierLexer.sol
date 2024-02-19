// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IJSLexer.sol';

/**
 * The interface to extract identifier tokens.
 */
interface IJSIdentifierLexer {
  /**
   * extract a identifier token.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The identifier token.
   */
  function readIdentifierToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external view returns (IJSLexer.Token memory);

  /**
   * determine whether the code can be used in identifier
   * @param code character code.
   * @return Return true if it can.
   */
  function isIdentifier(uint code) external pure returns (bool); 
  
  /**
   * Determine whether the character code can appear as the first character in an identifier.
   * @param code character code.
   * @return Return true if it can.
   */
  function isIdentifierStart(uint code) external pure returns (bool);
}