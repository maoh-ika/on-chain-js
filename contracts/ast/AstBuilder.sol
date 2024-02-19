// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '../utils/Log.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/ast/IStatementBuilder.sol';
import '../interfaces/lexer/IJSLexer.sol';
import '../interfaces/lexer/IJSKeywordLexer.sol';
import './AstNodeUtil.sol';
import './StatementBuilder.sol';

/**
 * access control for implementation update
 */
contract AstBuilderAdmin is Ownable {
  // address with permission to update state
  address public admin;
  // statement builder interface
  IStatementBuilder public statementBuilder;
  
  constructor(IStatementBuilder _statementBuilder) {
    admin = owner();
    statementBuilder = _statementBuilder;
  }

  /**
   * Ristrict access to admin
   */
  modifier onlyAdmin() {
    require(owner() == msg.sender || admin == msg.sender, 'only admin');
    _;
  }

  /**
   * Set admin address
   */
  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
  }

  /**
   * Update statement builder implementation
   */
  function setStatementBuilder(IStatementBuilder _statementBuilder) external onlyAdmin {
    statementBuilder = _statementBuilder;
  }
}

/**
 * The entry point for building ast.
 */
contract AstBuilder is AstBuilderAdmin, IAstBuilder {
  
  constructor(IStatementBuilder _statementBuilder) AstBuilderAdmin(_statementBuilder) {}

  /**
   * Build abstract syntax tree
   * @param tokens tokenized source code
   * @return ast
   */
  function build(IJSLexer.Token[] calldata tokens) external view returns (Ast memory) {
    // console.log('build');
    Context memory context = Context({
      currentTokenIndex: 0,
      nodeCount: 0,
      maxNodeId: 0,
      expCount: 0,
      nodes: new AstNode[](10)
    });
    AstNode memory programNode;
    (programNode, context) = _buildProgram(tokens, context);
    return Ast({
      programNode: programNode,
      nodes: context.nodes,
      expCount: context.expCount
    });
  }

  /**
   * Build program type ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   * @return updated context
   * @notice SnippetJS supports only function declaration node
   */
  function _buildProgram(IJSLexer.Token[] calldata tokens, IAstBuilder.Context memory context) private view returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory) {
    // console.log('IN buildProgram');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.program;
    AstNodeUtil.addNodeToContext(node, context);

    while (context.currentTokenIndex < tokens.length) {
      IJSLexer.Token memory token = tokens[context.currentTokenIndex];
      // console.log('token %s', token.attrs.expression);
      if (token.attrs.tokenType == IJSLexer.TokenType.keyword) {
        if (token.attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._function)) {
          IAstBuilder.AstNode memory funcDecl;
          (funcDecl, context) = statementBuilder.buildFunctionDeclaration(tokens, context);
          // console.log('RESUME buildProgram');
          AstNodeUtil.addNodeIdToArray(context.nodes[node.nodeId], funcDecl);
        }
      } else {
        ++context.currentTokenIndex;
        //revert('syntax error');
      }
    }
    AstNodeUtil.resize(context, context.nodeCount);
//    for (uint i = 0; i < context.nodes.length; ++i) {
//      Log.logAstNode(context.nodes[i]);
//    }
    // console.log('OUT buildProgram');
    return (context.nodes[node.nodeId], context);
  }
}