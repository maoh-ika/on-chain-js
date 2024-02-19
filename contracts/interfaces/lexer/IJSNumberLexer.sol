// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IJSLexer.sol';

/**
 * The interface to extract number tokens.
 */
interface IJSNumberLexer {
  /**
   * extract a number token assuming positive value
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The number token.
   */
  function readNumberToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) external view returns (IJSLexer.Token memory);
  
  /**
   * extract a number token assuming negative value
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The number token.
   */
  function readMinusNumberToken(
    bytes calldata source,
    IJSLexer.Context memory context
  ) external view returns (IJSLexer.Token memory);
  
  /**
   * extract a number token assuming it starts with zero
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @return The number token.
   */
  function readZeroToken(
    bytes calldata source,
    IJSLexer.Context memory context 
  ) external view returns (IJSLexer.Token memory);
  
  /**
   * Read a integer value.
   * @param source bytes sequence of source code.
   * @param context Tokenization context.
   * @param startPos starting position in the byte array.
   * @return integer attributes.
   */
  function readInteger(
    bytes calldata source,
    IJSLexer.Context memory context,
    uint startPos
  ) external view returns (IJSLexer.TokenAttrs memory);
}