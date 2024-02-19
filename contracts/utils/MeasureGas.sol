// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../interfaces/lexer/IJSLexer.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/interpreter/IJSInterpreter.sol';
import '../interfaces/snippetjs/ISnippetJS.sol';

contract MeasureGas {
  function measureLexer(
    IJSLexer lexer,
    string calldata code
  ) external view returns (uint, IJSLexer.Token[] memory tokens) {
    uint gas = gasleft();
    IJSLexer.Config memory config = IJSLexer.Config(true);
    tokens = lexer.tokenize(code, config);
    return (gas - gasleft(), tokens);
  }
  
  function measureAst(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder astBuilder
  ) external view returns (uint, IAstBuilder.Ast memory ast) {
    uint gas = gasleft();
    ast = astBuilder.build(tokens);
    return (gas - gasleft(), ast);
  }
  
  function measureInterpreter(
    IAstBuilder.Ast calldata ast,
    IJSInterpreter interpreter,
    IJSInterpreter.InitialState calldata initialState
  ) external view returns (uint) {
    uint gas = gasleft();
    interpreter.interpret(ast, initialState);
    return gas - gasleft();
  }
  
  function measureSnippet(
    ISnippetJS snippetJs,
    string calldata code,
    IJSInterpreter.InitialState calldata initialState
  ) external view returns (string memory, uint) {
    uint gas = gasleft();
    string memory result = snippetJs.interpretWithStateToString(code, initialState);
    return (result, gas - gasleft());
  }
  
  function measureTokenize(
    ISnippetJS snippetJs,
    string calldata code
  ) external view returns (IJSLexer.Token[] memory, uint) {
    uint gas = gasleft();
    IJSLexer.Config memory config;
    config.ignoreComment = true;
    IJSLexer.Token[] memory tokens = snippetJs.tokenize(code, config);
    return (tokens, gas - gasleft());
  }
  
  function measureParseSignature(
    ISnippetJS snippetJs,
    string calldata code
  ) external view returns (ISnippetJS.Signature memory, uint) {
    uint gas = gasleft();
    ISnippetJS.Signature memory result = snippetJs.parseSignature(code);
    return (result, gas - gasleft());
  }

  function measureTraceDependencies(
    ISnippetJS snippetJs,
    string memory code,
    IJSInterpreter.InitialState calldata initialState
  ) external view returns (IJSInterpreter.Dependencies memory, uint) {
    uint gas = gasleft();
    IJSInterpreter.Dependencies memory result = snippetJs.traceDependencies(code, initialState);
    return (result, gas - gasleft());
  }
}