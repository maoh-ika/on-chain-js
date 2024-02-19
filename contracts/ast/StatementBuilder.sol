// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '../utils/Log.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/ast/IStatementBuilder.sol';
import '../interfaces/ast/IExpressionBuilder.sol';
import '../interfaces/lexer/IJSLexer.sol';
import '../interfaces/lexer/IJSKeywordLexer.sol';
import '../interfaces/lexer/IJSPunctuationLexer.sol';
import '../interfaces/lexer/IJSOperatorLexer.sol';
import './AstNodeUtil.sol';
import './ExpressionBuilder.sol';

/**
 * access control for implementation update
 */
contract StatementExpressionAdmin is Ownable {
  // address with permission to update state
  address public admin;
  // expression builder interface
  IExpressionBuilder public expressionBuilder;

  constructor(IExpressionBuilder _expressionBuilder) {
    admin = owner();
    expressionBuilder = _expressionBuilder;
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
   * Update expression builder implementation
   */
  function setExpressionBuilder(IExpressionBuilder _expressionBuilder) external onlyAdmin {
    expressionBuilder = _expressionBuilder;
  }
}

/**
 * Builder for statement types ast nodes.
 */
contract StatementBuilder is StatementExpressionAdmin, IStatementBuilder {

  constructor(IExpressionBuilder _expressionBuilder) StatementExpressionAdmin(_expressionBuilder) {}

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
  ) external view override returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory) {
    // console.log('IN buildStatement');
    return (_buildStatement(tokens, context), context);
  }
  
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
  ) external view override returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory) {
    // console.log('IN buildFunctionDeclaration');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.functionDeclaration;
    AstNodeUtil.addNodeToContext(node, context);
    // func name
    context.currentTokenIndex++;
    IAstBuilder.AstNode memory idNode;
    (idNode, context) = expressionBuilder.buildIdentifier(tokens, context);
    ++context.currentTokenIndex;
    node = context.nodes[node.nodeId];
    AstNodeUtil.addNodeIdToArray(node, idNode);
    // args
    while (context.currentTokenIndex < tokens.length) {
      if (
        tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
        tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.rightParenthesis)
      ) {
        ++context.currentTokenIndex;
        break;
      } else if (tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.identifier) {
        IAstBuilder.AstNode memory argNode;
        (argNode, context) = expressionBuilder.buildIdentifier(tokens, context);
        node = context.nodes[node.nodeId];
        ++context.currentTokenIndex;
        if (
          tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.operator &&
          tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSOperatorLexer.OperatorCode.assignment)
        ) {
          // AssignmentPattern
          ++context.currentTokenIndex;
          IAstBuilder.AstNode memory initNode;
          (initNode, context) = expressionBuilder.buildExpression(tokens, context, false);
           require(initNode.nodeType != IAstBuilder.NodeType.invalid);
          node = context.nodes[node.nodeId];
          IAstBuilder.AstNode memory assignNode;
          assignNode.nodeType = IAstBuilder.NodeType.assignmentPattern;
          AstNodeUtil.addNodeToContext(assignNode, context);
          AstNodeUtil.addNodeIdToArray(assignNode, argNode);
          AstNodeUtil.addNodeIdToArray(assignNode, initNode);
          AstNodeUtil.addNodeIdToArray(node, assignNode);
        } else {
          AstNodeUtil.addNodeIdToArray(node, argNode);
        }
      } else {
        ++context.currentTokenIndex;
      }
    }
    // body
    IAstBuilder.AstNode memory bodyNode = _buildBlockStatement(tokens, context);
    AstNodeUtil.addNodeIdToArray(node, bodyNode);
    // console.log('OUT buildFunctionDeclaration');
    return (node, context);
  }
  
  /**
   * Implementation of buildStatement
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    if (tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.keyword) {
      if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._return)) {
        return _buildReturnStatement(tokens, context);
      } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._if)) {
        return _buildIfStatement(tokens, context);
      } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._var)) {
        return _buildVariableDeclaration(tokens, context);
      } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._while)) {
        return _buildWhileStatement(tokens, context);
      } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._for)) {
        uint curIndex = context.currentTokenIndex + 1;
        while (curIndex++ < tokens.length) {
          if (
            tokens[curIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
            tokens[curIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.semicolon)
          ) {
            return _buildForStatement(tokens, context);
          } else if (
            tokens[curIndex].attrs.tokenType == IJSLexer.TokenType.keyword &&
            tokens[curIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._in)
          ) {
            return _buildForInStatement(tokens, context);
          }
        }
      } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._break)) {
        return _buildBreakContinueStatement(context, true);
      } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._continue)) {
        return _buildBreakContinueStatement(context, false);
      }
    } else if (tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation) {
      if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftCurlyBrace)) {
        return _buildBlockStatement(tokens, context);
      }
    } else if (
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.identifier ||
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.operator) {
      return _buildExpressionStatement(tokens, context);
    }
    IAstBuilder.AstNode memory invalid;
    return invalid;
  }
  
  /**
   * Build block statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildBlockStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildBlockStatement');
    require(
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftCurlyBrace)
    );
    
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.blockStatement;
    AstNodeUtil.addNodeToContext(node, context);
    
    ++context.currentTokenIndex;
    while (context.currentTokenIndex < tokens.length) {
      IAstBuilder.AstNode memory statNode = _buildStatement(tokens, context);
      if (statNode.nodeType != IAstBuilder.NodeType.invalid) {
        // console.log('RESUME buildBlockStatement');
        AstNodeUtil.addNodeIdToArray(context.nodes[node.nodeId], statNode);
      } else if (
        tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
        tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.rightCurlyBrace)
      ) { // end of the block
        ++context.currentTokenIndex;
        break;
      } else {
        ++context.currentTokenIndex;
      }
    }

    // console.log('OUT buildBlockStatement');
    return context.nodes[node.nodeId];
  }
  
  /**
   * Build expression statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildExpressionStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildExpressionStatement');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.expressionStatement;
    AstNodeUtil.addNodeToContext(node, context);

    /*
      Delegate building expression task to ExpressionBuilder contract which is executed in
      external environment. In order to reduce payload passed inter contracts, make temporary
      context which contains minimum stuff and join it to the context of this environment.
     */ 
    IAstBuilder.AstNode memory exNode;
    IAstBuilder.Context memory exContext;
    exContext.currentTokenIndex = context.currentTokenIndex;
    (exNode, exContext) = expressionBuilder.buildExpression(tokens, exContext, false);
    require(exNode.nodeType != IAstBuilder.NodeType.invalid);
    AstNodeUtil.joinContext(exContext, exNode, context);
    node = context.nodes[node.nodeId];
    // console.log('RESUME buildExpressionStatement');
    AstNodeUtil.addNodeIdToArray(node, exNode);
    // console.log('OUT buildExpressionStatement');
    return node;
  }

  /**
   * Build return statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildReturnStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildReturnStatement');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.returnStatement;
    AstNodeUtil.addNodeToContext(node, context);
    ++context.currentTokenIndex;
    IAstBuilder.AstNode memory exNode;
    IAstBuilder.Context memory exContext; 
    exContext.currentTokenIndex = context.currentTokenIndex;
    (exNode, exContext) = expressionBuilder.buildExpression(tokens, exContext, false);
    require(exNode.nodeType != IAstBuilder.NodeType.invalid);
    AstNodeUtil.joinContext(exContext, exNode, context);
    node = context.nodes[node.nodeId];
    // console.log('RESUME buildReturnStatement');
    AstNodeUtil.addNodeIdToArray(node, exNode);
    // console.log('OUT buildReturnStatement');
    return node;
  }
  
  /**
   * Build break or continue statement ast node
   * @param context the runtime context
   * @param isBreak if true break statement is required
   * @return built ast node
   */
  function _buildBreakContinueStatement(
    IAstBuilder.Context memory context,
    bool isBreak
  ) private pure returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildReturnStatement');
    IAstBuilder.AstNode memory node;
    node.nodeType = isBreak ? IAstBuilder.NodeType.breakStatement : IAstBuilder.NodeType.continueStatement;
    AstNodeUtil.addNodeToContext(node, context);
    ++context.currentTokenIndex;
    return node;
  }
  
  /**
   * Build variable declaration statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildVariableDeclaration(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildVariableDeclaration');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.variableDeclaration;
    AstNodeUtil.addNodeToContext(node, context);

    // kind
    if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._var)) {
      node.value = abi.encode('var');
    } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._let)) {
      node.value = abi.encode('let');
    } else if (tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._const)) {
      node.value = abi.encode('const');
    }
    ++context.currentTokenIndex;
    
    // declarations
    while (context.currentTokenIndex < tokens.length) {
      require(tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.identifier, 'invalid var');
      IAstBuilder.AstNode memory declNode = _buildVariableDeclarator(tokens, context);
      // console.log('RESUME buildVariableDeclaration');
      AstNodeUtil.addNodeIdToArray(context.nodes[node.nodeId], declNode);
      if (
        tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
        tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.comma)
      ) {
        ++context.currentTokenIndex;
      } else {
        break;
      }
    } 
    // console.log('OUT buildVariableDeclaration');
    return node;
  }
   
  /**
   * Build variable declarator statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildVariableDeclarator(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildVariableDeclarator');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.variableDeclarator;
    AstNodeUtil.addNodeToContext(node, context);
    // identifier
    require(tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.identifier);
    IAstBuilder.AstNode memory idNode;
    IAstBuilder.Context memory idContext;
    idContext.currentTokenIndex = context.currentTokenIndex;
    (idNode, idContext) = expressionBuilder.buildIdentifier(tokens, idContext);
    AstNodeUtil.joinContext(idContext, idNode, context);
    node = context.nodes[node.nodeId];
    ++context.currentTokenIndex;
    // console.log('RESUME buildVariableDeclarator');
    AstNodeUtil.addNodeIdToArray(node, idNode);
    // init
    IAstBuilder.AstNode memory initNode;
    if (
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.operator &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSOperatorLexer.OperatorCode.assignment)
    ) {
      ++context.currentTokenIndex;
      IAstBuilder.Context memory initContext;
      initContext.currentTokenIndex = context.currentTokenIndex;
      (initNode, initContext) = expressionBuilder.buildExpression(tokens, initContext, false);
      require(initNode.nodeType != IAstBuilder.NodeType.invalid);
      AstNodeUtil.joinContext(initContext, initNode, context);
      node = context.nodes[node.nodeId];
      AstNodeUtil.addNodeIdToArray(node, initNode);
      // console.log('RESUME buildVariableDeclarator');
    } else {
      initNode.nodeType = IAstBuilder.NodeType.nullNode;
      AstNodeUtil.addNodeToContext(initNode, context);
      AstNodeUtil.addNodeIdToArray(node, initNode);
      // console.log('RESUME buildVariableDeclarator');
    }

    // console.log('OUT buildVariableDeclarator');
    return node;
  }
  
  /**
   * Build if statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildIfStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildIfStatement');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.ifStatement;
    AstNodeUtil.addNodeToContext(node, context);
    ++context.currentTokenIndex;
    require(
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftParenthesis),
      'invalid if statement'
    );
    ++context.currentTokenIndex;
    
    // test
    IAstBuilder.AstNode memory exNode;
    IAstBuilder.Context memory exContext;
    exContext.currentTokenIndex = context.currentTokenIndex;
    (exNode, exContext) = expressionBuilder.buildExpression(tokens, exContext, false);
    require(exNode.nodeType != IAstBuilder.NodeType.invalid);
    AstNodeUtil.joinContext(exContext, exNode, context);
    node = context.nodes[node.nodeId];
    ++context.currentTokenIndex;
    // console.log('RESUME buildIfStatement');
    AstNodeUtil.addNodeIdToArray(node, exNode);

    // consequent
    // console.log('if consequent');
    IAstBuilder.AstNode memory statNode = _buildStatement(tokens, context);
    AstNodeUtil.addNodeIdToArray(node, statNode);
    
    // console.log('token %s', tokens[context.currentTokenIndex].attrs.expression);

    // alternate
    if (
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.keyword &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._else)
    ) {
      // console.log('if alternate');
      ++context.currentTokenIndex;
      IAstBuilder.AstNode memory altNode = _buildStatement(tokens, context);
      AstNodeUtil.addNodeIdToArray(node, altNode);
    } 

    // console.log('OUT buildIfStatement');
    return node;
  }

  /**
   * Build while statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildWhileStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildWileStatement');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.whileStatement;
    AstNodeUtil.addNodeToContext(node, context);
    ++context.currentTokenIndex;

    require(
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftParenthesis),
      'invalid while statement'
    );
    ++context.currentTokenIndex;
    
    // test
    IAstBuilder.AstNode memory testNode;
    IAstBuilder.Context memory testContext;
    testContext.currentTokenIndex = context.currentTokenIndex;
    (testNode, testContext) = expressionBuilder.buildExpression(tokens, testContext, false);
    require(testNode.nodeType != IAstBuilder.NodeType.invalid);
    AstNodeUtil.joinContext(testContext, testNode, context);
    node = context.nodes[node.nodeId];
    if (testNode.nodeType != IAstBuilder.NodeType.invalid) {
      AstNodeUtil.addNodeIdToArray(node, testNode);
    } else {
      testNode.nodeType = IAstBuilder.NodeType.nullNode;
      AstNodeUtil.addNodeToContext(testNode, context);
      AstNodeUtil.addNodeIdToArray(node, testNode);
    }
    ++context.currentTokenIndex;

    // body
    IAstBuilder.AstNode memory bodyNode = _buildStatement(tokens, context);
    AstNodeUtil.addNodeIdToArray(node, bodyNode);
    
    // console.log('OUT buildWileStatement');
    return node;
  }

  /**
   * Build for statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildForStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildForStatement');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.forStatement;
    AstNodeUtil.addNodeToContext(node, context);
    ++context.currentTokenIndex;

    require(
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftParenthesis),
      'invalid "for"'
    );
    ++context.currentTokenIndex;
    
    // init
    IAstBuilder.AstNode memory initNode = _buildStatement(tokens, context);
    if (initNode.nodeType != IAstBuilder.NodeType.invalid) {
      AstNodeUtil.addNodeIdToArray(context.nodes[node.nodeId], initNode);
    } else {
      initNode.nodeType = IAstBuilder.NodeType.nullNode;
      AstNodeUtil.addNodeToContext(initNode, context);
      AstNodeUtil.addNodeIdToArray(context.nodes[node.nodeId], initNode);
    }
    ++context.currentTokenIndex;

    // test
    IAstBuilder.AstNode memory testNode;
    IAstBuilder.Context memory testContext;
    testContext.currentTokenIndex = context.currentTokenIndex;
    (testNode, testContext) = expressionBuilder.buildExpression(tokens, testContext, false);
    require(testNode.nodeType != IAstBuilder.NodeType.invalid);
    AstNodeUtil.joinContext(testContext, testNode, context);
    node = context.nodes[node.nodeId];
    if (testNode.nodeType != IAstBuilder.NodeType.invalid) {
      AstNodeUtil.addNodeIdToArray(node, testNode);
    } else {
      testNode.nodeType = IAstBuilder.NodeType.nullNode;
      AstNodeUtil.addNodeToContext(testNode, context);
      AstNodeUtil.addNodeIdToArray(node, testNode);
    }
    ++context.currentTokenIndex;

    // update
    IAstBuilder.AstNode memory updateNode;
    IAstBuilder.Context memory updateContext;
    updateContext.currentTokenIndex = context.currentTokenIndex;
    (updateNode, updateContext) = expressionBuilder.buildExpression(tokens, updateContext, false);
    require(updateNode.nodeType != IAstBuilder.NodeType.invalid);
    AstNodeUtil.joinContext(updateContext, updateNode, context);
    node = context.nodes[node.nodeId];
    if (updateNode.nodeType != IAstBuilder.NodeType.invalid) {
      AstNodeUtil.addNodeIdToArray(node, updateNode);
    } else {
      updateNode.nodeType = IAstBuilder.NodeType.nullNode;
      AstNodeUtil.addNodeToContext(updateNode, context);
      AstNodeUtil.addNodeIdToArray(node, updateNode);
    }
    require(
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.rightParenthesis),
      'invalid "for"'
    );
    ++context.currentTokenIndex;

    // body
    IAstBuilder.AstNode memory bodyNode = _buildStatement(tokens, context);
    AstNodeUtil.addNodeIdToArray(node, bodyNode);
    
    // console.log('OUT buildForStatement');
    return node;
  }
  
  /**
   * Build for-in statement ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildForInStatement(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildForStatement');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.forInStatement;
    AstNodeUtil.addNodeToContext(node, context);
    ++context.currentTokenIndex;

    require(
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftParenthesis),
      'invalid "for-in"'
    );
    ++context.currentTokenIndex;
    
    // left
    IAstBuilder.AstNode memory leftNode = _buildStatement(tokens, context);
    AstNodeUtil.addNodeIdToArray(context.nodes[node.nodeId], leftNode);
    ++context.currentTokenIndex; // skip 'in'

    // right
    IAstBuilder.AstNode memory rightNode;
    IAstBuilder.Context memory rightContext;
    rightContext.currentTokenIndex = context.currentTokenIndex;
    (rightNode, rightContext) = expressionBuilder.buildExpression(tokens, rightContext, false);
    require(rightNode.nodeType != IAstBuilder.NodeType.invalid);
    AstNodeUtil.joinContext(rightContext, rightNode, context);
    node = context.nodes[node.nodeId];
    AstNodeUtil.addNodeIdToArray(node, rightNode);
    require(
      tokens[context.currentTokenIndex].attrs.tokenType == IJSLexer.TokenType.punctuation &&
      tokens[context.currentTokenIndex].attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.rightParenthesis),
      'invalid "for-in"'
    );
    ++context.currentTokenIndex;

    // body
    IAstBuilder.AstNode memory bodyNode = _buildStatement(tokens, context);
    AstNodeUtil.addNodeIdToArray(node, bodyNode);
    
    return node;
  }
}