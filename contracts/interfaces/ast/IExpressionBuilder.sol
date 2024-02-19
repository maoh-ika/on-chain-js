// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../lexer/IJSLexer.sol';
import './IAstBuilder.sol';

/**
 * The interface to build expression types ast nodes.
 */
interface IExpressionBuilder {
  /**
   * Build expression types ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @param findOne if true, build just one node. otherwise build node tree until reach non expression type. 
   * @return built ast node
   * @return updated context
   * @notice The context argument is received as 'memory' because it may be updated.
   *         This function is executed in different environment and memory addresses from caller, so we need passing
   *         the updated context to caller as return value which is passed as copy.
   */
  function buildExpression(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context,
    bool findOne
  ) external view returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory);
  
  /**
   * Build identifier type ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   * @return updated context
   */
  function buildIdentifier(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) external view returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory);
}