// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../lexer/IJSLexer.sol';
import './IAstBuilder.sol';

/**
 * The interface to build statement types ast nodes.
 */
interface IStatementBuilder {
  /**
   * Build statement types ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   * @return updated context
   */
  function buildStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) external view returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory);
  
  /**
   * Build function declaration ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   * @return updated context
   */
  function buildFunctionDeclaration(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) external view returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory);
}