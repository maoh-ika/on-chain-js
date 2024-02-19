// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../lexer/IJSLexer.sol';
import '../ast/IAstBuilder.sol';
import '../interpreter/IJSInterpreter.sol';

/**
 * The interface of SnippetJS
 */
interface ISnippetJS {
  // function signature
  struct Signature {
    string name;
    string[] args;
    IJSInterpreter.JSValueType[] types;
  }

  /**
   * Interpret and execute javascript function code.
   * @param code function code
   * @return result
   */
  function interpret(string calldata code) external view returns (IJSInterpreter.JSValue memory);
  
  /**
   * Interpret and execute javascript function code with initial state such as arguments.
   * @param code function code
   * @param initialState initial state
   * @return result
   */
  function interpretWithState(string calldata code, IJSInterpreter.InitialState calldata initialState) external view returns (IJSInterpreter.JSValue memory);
  
  /**
   * Interpret and execute javascript function code. Returns result as string.
   * @param code function code
   * @return result
   */
  function interpretToString(string calldata code) external view returns (string memory);
  
  /**
   * Interpret and execute javascript function code with initial state such as arguments.
   * Returns result as string.
   * @param code function code
   * @param initialState initial state
   * @return result
   */
  function interpretWithStateToString(string calldata code, IJSInterpreter.InitialState calldata initialState) external view returns (string memory);
  
  /**
   * Tokenize javascript function code.
   * @param code function code
   * @param config tokenization configuration
   * @return tokens
   */
  function tokenize(string calldata code, IJSLexer.Config calldata config) external view returns (IJSLexer.Token[] memory);
  
  /**
   * Build AST from code tokens.
   * @param tokens code tokens
   * @return AST
   */
  function buildAst(IJSLexer.Token[] calldata tokens) external view returns (IAstBuilder.Ast memory);
  
  /**
   * Interpret and execute abstract syntax tree with initial state.
   * @param ast abstract syntax tree
   * @param initialState initial state
   * @return result
   */
  function interpretAst(IAstBuilder.Ast calldata ast, IJSInterpreter.InitialState calldata initialState) external view returns (IJSInterpreter.JSValue memory);
  
  /**
   * Parse function signature
   * @param code function code
   * @return signature
   */
  function parseSignature(string calldata code) external view returns (Signature memory);
  
  /**
   * Track dependencies dynamically while executing the code.
   * @param code function code
   * @param initialState initial state
   * @return dependencies
   */  
  function traceDependencies(string calldata code, IJSInterpreter.InitialState calldata initialState) external view returns (IJSInterpreter.Dependencies memory);
}