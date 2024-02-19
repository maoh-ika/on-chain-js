// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../utils/Log.sol';
import '../interfaces/ast/IAstBuilder.sol';
import '../interfaces/lexer/IJSKeywordLexer.sol';
import '../interfaces/lexer/IJSPunctuationLexer.sol';
import '../interfaces/ast/IExpressionBuilder.sol';
import '../lexer/TokenAttrsUtil.sol';
import './AstBuilderUtil.sol';
import './AstNodeUtil.sol';

/**
 * Builder for expression types ast nodes.
 */
contract ExpressionBuilder is IExpressionBuilder {
  using TokenAttrsUtil for IJSLexer.TokenAttrs;
  
  /**
   * Build expression types ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @param findOne if true, build just one node. otherwise build node tree until reach non expression type. 
   * @return built ast node
   * @return updated context
   * @notice The context argument is received as 'memory' because it may be updated.
   *          This function is executed in different environment and memory addresses from caller, so we need passing
   *          the updated context to caller as return value which is passed as copy.
   */
  function buildExpression(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context,
    bool findOne
  ) external view override returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory) {
    return (_buildExpression(tokens, context, findOne, 0), context);
  }
  
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
  ) external pure override returns (IAstBuilder.AstNode memory, IAstBuilder.Context memory) {
    return (_buildIdentifier(tokens, context), context);
  }
  
  /**
   * Implementation of buildExpression
   * @param tokens tokenized source code
   * @param context the runtime context
   * @param findOne if true, build just one node. otherwise build node tree until reach non expression type. 
   * @param prevBiopOrder the order of previous binary operator. if previous is not binary, the value is 0.
   * @return built ast node
   */
  function _buildExpression(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context,
    bool findOne,
    uint prevBiopOrder 
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildExpression');

    IAstBuilder.AstNode memory prevNode;
    while (context.currentTokenIndex < tokens.length) {
      IJSLexer.Token calldata token = tokens[context.currentTokenIndex];
      if (token.attrs.tokenType == IJSLexer.TokenType.identifier) {
        prevNode = _buildIdentifier(tokens, context);
        ++context.currentTokenIndex;
        token = tokens[context.currentTokenIndex];
        // test member expression
        if (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftSquareBracket)) {
          // console.log('Found memberExpression br');
          ++context.currentTokenIndex;
          IAstBuilder.AstNode memory propertyNode = _buildExpression(tokens, context, false, 0);
          prevNode = _buildMemberExpression(prevNode, propertyNode, true, context);
          ++context.currentTokenIndex; // skip rightSquareBracket
          // console.log('RESUME buildExpression1 br');
        } else if (token.attrs.tokenType == IJSLexer.TokenType.operator && token.attrs.tokenCode == uint(IJSOperatorLexer.OperatorCode.dot)) {
          // console.log('Found memberExpression dot');
          ++context.currentTokenIndex;
          IAstBuilder.AstNode memory propertyNode = _buildIdentifier(tokens, context);
          prevNode = _buildMemberExpression(prevNode, propertyNode, false, context);
          ++context.currentTokenIndex;
          // console.log('RESUME buildExpression1 dot');
        }
      } else if ( // nested member expression (computed)
        prevNode.nodeType != IAstBuilder.NodeType.invalid &&
        token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftSquareBracket)
      ) {
        // console.log('Found memberExpression br');
        ++context.currentTokenIndex;
        IAstBuilder.AstNode memory propertyNode = _buildExpression(tokens, context, false, 0);
        prevNode = _buildMemberExpression(prevNode, propertyNode, true, context);
        ++context.currentTokenIndex; // skip rightSquareBracket
      } else if ( // nested member expression
        prevNode.nodeType != IAstBuilder.NodeType.invalid &&
        token.attrs.tokenType == IJSLexer.TokenType.operator && token.attrs.tokenCode == uint(IJSOperatorLexer.OperatorCode.dot)
      ) {
        // console.log('Found memberExpression dot');
        ++context.currentTokenIndex;
        IAstBuilder.AstNode memory propertyNode = _buildIdentifier(tokens, context);
        prevNode = _buildMemberExpression(prevNode, propertyNode, false, context);
        ++context.currentTokenIndex;
        // console.log('RESUME buildExpression dot');
      } else if (AstBuilderUtil.getLiteralValueType(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.LiteralValueType.literal_invalid) {
        // console.log('Found Literal');
        prevNode = _buildLiteral(tokens, context);
        ++context.currentTokenIndex;
        // console.log('RESUME buildExpression2');
      } else if (AstBuilderUtil.getBinaryOperator(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.BinaryOperator.biop_invalid) {
        if (
          prevNode.nodeType == IAstBuilder.NodeType.invalid &&
          AstBuilderUtil.getUnaryOperator(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.UnaryOperator.unary_invalid) {
          // console.log('Found UnaryOperator');
          ++context.currentTokenIndex;
          IAstBuilder.AstNode memory argNode = _buildExpression(tokens, context, false, 0);
          // console.log('RESUME buildExpression3');
          prevNode = _buildUnaryExpression(token, argNode, false, context);
        } else {
          uint biopOrder = _biopOrder(token.attrs.tokenCode);
          if (prevBiopOrder != 0 && biopOrder <= prevBiopOrder) {
            // if prevOpOrder is not zero, it is in looking for a higher order op to process it prior to prevOpOrder op.
            // if opOrder is less or equal than prevOpOrder, exit here to process prevOpOrder op prior to opOrder op.
            break;
          }
          // console.log('Found BinaryOperator');
          ++context.currentTokenIndex;
          IAstBuilder.AstNode memory rightNode = _buildExpression(tokens, context, false, biopOrder);
          // console.log('RESUME buildExpression4');
          prevNode = _buildBinaryExpression(token, context.nodes[prevNode.nodeId], rightNode, context);
        }
      } else if (AstBuilderUtil.getUnaryOperator(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.UnaryOperator.unary_invalid) {
        // console.log('Found UnaryOperator');
        ++context.currentTokenIndex;
        IAstBuilder.AstNode memory argNode = _buildExpression(tokens, context, true, 0);
        // console.log('RESUME buildExpression5');
        prevNode = _buildUnaryExpression(token, argNode, false, context);
      } else if (AstBuilderUtil.getAssignmentOperator(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.AssignmentOperator.invalid) {
        // console.log('Found AssignmentOperator');
        ++context.currentTokenIndex;
        IAstBuilder.AstNode memory rightNode = _buildExpression(tokens, context, false, 0);
        // console.log('RESUME buildExpression6');
        prevNode = _buildAssignmentExpression(token, context.nodes[prevNode.nodeId], rightNode, context);
      } else if (AstBuilderUtil.getUpdateOperator(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.UpdateOperator.update_invalid) {
        // console.log('Found UpdateOperator');
        if (prevNode.nodeType != IAstBuilder.NodeType.invalid) {
          prevNode = _buildUpdateExpression(token, context.nodes[prevNode.nodeId], false, context);
          ++context.currentTokenIndex;
          // console.log('RESUME buildExpression7');
        } else {
          ++context.currentTokenIndex;
          IAstBuilder.AstNode memory argNode = _buildExpression(tokens, context, true, 0);
          // console.log('RESUME buildExpression8');
          prevNode = _buildUpdateExpression(token, argNode, true, context);
        }
      } else if (AstBuilderUtil.getLogicalOperator(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.LogicalOperator.logical_invalid) {
        // console.log('Found LogicalOperator');
        if (prevBiopOrder > 0) {
          // finding higher order biop but encouted non op token which takes two operands.
          break;
        }
        ++context.currentTokenIndex;
        IAstBuilder.AstNode memory rightNode = _buildExpression(tokens, context, false, 0);
        // console.log('RESUME buildExpression10');
        prevNode = _buildLogicalExpression(token, context.nodes[prevNode.nodeId], rightNode, context);
      } else if (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftParenthesis)) {
        if (
          prevNode.nodeType != IAstBuilder.NodeType.invalid && (
          prevNode.nodeType == IAstBuilder.NodeType.identifier ||
          prevNode.nodeType == IAstBuilder.NodeType.memberExpression ||
          prevNode.nodeType == IAstBuilder.NodeType.callExpression
        )) {
          // console.log('FOUND callExpression');
          ++context.currentTokenIndex;
          prevNode = _buildCallExpression(prevNode, tokens, context);
          ++context.currentTokenIndex; // skip rightParenthesis
        } else {
          // console.log('Found leftParenthesis for oder control');
          ++context.currentTokenIndex;
          prevNode = _buildExpression(tokens, context, false, 0);
          ++context.currentTokenIndex; // skip rightParenthesis
          // console.log('RESUME buildExpression9');
        }
      } else {
        revert('syntax error');
      }

      token = tokens[context.currentTokenIndex];
      // // only one expression required
      if (
        findOne &&
        prevNode.nodeType != IAstBuilder.NodeType.invalid &&
        !(token.attrs.tokenType == IJSLexer.TokenType.operator && token.attrs.tokenCode == uint(IJSOperatorLexer.OperatorCode.dot)) && // not in dot method chain
        !(token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.leftSquareBracket)) // not in bracket chain
      ) {
        break;
      }
      // exit expression
      if (
        (token.attrs.tokenType == IJSLexer.TokenType.punctuation && (
          token.attrs.tokenCode != uint(IJSPunctuationLexer.PunctuationCode.leftSquareBracket) &&
          token.attrs.tokenCode != uint(IJSPunctuationLexer.PunctuationCode.leftParenthesis)
        )) ||
        (token.attrs.tokenType == IJSLexer.TokenType.keyword && !_isAllowedKeyword(token.attrs.tokenCode)) ||
        (token.line != tokens[context.currentTokenIndex - 1].line && AstBuilderUtil.getBinaryOperator(token.attrs.tokenCode, token.attrs.tokenType) == IAstBuilder.BinaryOperator.biop_invalid)
      ) {
        // console.log('fixed exp');
        // Log.logToken(token);
        break;
      }
    }
    // console.log('OUT buildExpression');
    return prevNode;
  }
  
  /**
   * Build unary operator ast node
   * @param token source code
   * @param argument operand node
   * @param prefix if true, it is prefix operator, otherwise postfix operator
   * @param context the runtime context
   * @return built ast node
   */
  function _buildUnaryExpression(
    IJSLexer.Token calldata token,
    IAstBuilder.AstNode memory argument,
    bool prefix,
    IAstBuilder.Context memory context
  ) private pure returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.unaryExpression;
    node.nodeDescriptor = uint(AstBuilderUtil.getUnaryOperator(token.attrs.tokenCode, token.attrs.tokenType));
    node.nodeArray = new uint[](1);
    node.nodeArray[0] = argument.nodeId;
    node.value = abi.encode(prefix);
    AstNodeUtil.addNodeToContext(node, context);
    return node;
  }

  /**
   * Build binary operator ast node
   * @param token source code
   * @param left left operand node
   * @param right right operand node
   * @param context the runtime context
   * @return built ast node
   */
  function _buildBinaryExpression(
    IJSLexer.Token calldata token,
    IAstBuilder.AstNode memory left,
    IAstBuilder.AstNode memory right,
    IAstBuilder.Context memory context
  ) private pure returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.binaryExpression;
    node.nodeDescriptor = uint(AstBuilderUtil.getBinaryOperator(token.attrs.tokenCode, token.attrs.tokenType));
    node.nodeArray = new uint[](2);
    node.nodeArray[0] = left.nodeId;
    node.nodeArray[1] = right.nodeId;
    AstNodeUtil.addNodeToContext(node, context);
    return node;
  }
  
  /**
   * Build logical operator ast node
   * @param token source code
   * @param left left operand node
   * @param right right operand node
   * @param context the runtime context
   * @return built ast node
   */
  function _buildLogicalExpression(
    IJSLexer.Token calldata token,
    IAstBuilder.AstNode memory left,
    IAstBuilder.AstNode memory right,
    IAstBuilder.Context memory context
  ) private pure returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.logicalExpression;
    node.nodeDescriptor = uint(AstBuilderUtil.getLogicalOperator(token.attrs.tokenCode, token.attrs.tokenType));
    node.nodeArray = new uint[](2);
    node.nodeArray[0] = left.nodeId;
    node.nodeArray[1] = right.nodeId;
    AstNodeUtil.addNodeToContext(node, context);
    return node;
  }
  
  /**
   * Build assignment operator ast node
   * @param token source code
   * @param left left operand node
   * @param right right operand node
   * @param context the runtime context
   * @return built ast node
   */
  function _buildAssignmentExpression(
    IJSLexer.Token calldata token,
    IAstBuilder.AstNode memory left,
    IAstBuilder.AstNode memory right,
    IAstBuilder.Context memory context
  ) private pure returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.assignmentExpression;
    node.nodeDescriptor = uint(AstBuilderUtil.getAssignmentOperator(token.attrs.tokenCode, token.attrs.tokenType));
    node.nodeArray = new uint[](2);
    node.nodeArray[0] = left.nodeId;
    node.nodeArray[1] = right.nodeId;
    AstNodeUtil.addNodeToContext(node, context);
    return node;
  }
  
  /**
   * Build update operator ast node
   * @param token source code
   * @param argument operand node
   * @param prefix if true, it is prefix operator, otherwise postfix operator
   * @param context the runtime context
   * @return built ast node
   */
  function _buildUpdateExpression(
    IJSLexer.Token calldata token,
    IAstBuilder.AstNode memory argument,
    bool prefix,
    IAstBuilder.Context memory context
  ) private pure returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.updateExpression;
    node.nodeDescriptor = uint(AstBuilderUtil.getUpdateOperator(token.attrs.tokenCode, token.attrs.tokenType));
    node.nodeArray = new uint[](1);
    node.nodeArray[0] = argument.nodeId;
    node.value = abi.encode(prefix);
    AstNodeUtil.addNodeToContext(node, context);
    return node;
  }
  
  /**
   * Build member expression ast node
   * @param object property owner node
   * @param property property node
   * @param computed if true, it is computed property
   * @param context the runtime context
   * @return built ast node
   */
  function _buildMemberExpression(
    IAstBuilder.AstNode memory object,
    IAstBuilder.AstNode memory property,
    bool computed,
    IAstBuilder.Context memory context
  ) private pure returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.memberExpression;
    node.nodeArray = new uint[](2);
    node.nodeArray[0] = object.nodeId;
    node.nodeArray[1] = property.nodeId;
    node.value = abi.encode(computed);
    AstNodeUtil.addNodeToContext(node, context);
    return node;
  }

  /**
   * Build object expression ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildObjectExpression(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory objectNode;
    objectNode.nodeType = IAstBuilder.NodeType.objectExpression;
    AstNodeUtil.addNodeToContext(objectNode, context);
    while (context.currentTokenIndex < tokens.length) {
      IJSLexer.Token calldata token = tokens[context.currentTokenIndex];
      if (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.rightCurlyBrace)) {
        break; // end of object literal
      } else if (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.comma)) {
        // next property
        ++context.currentTokenIndex;
        token = tokens[context.currentTokenIndex];
      }
      IAstBuilder.AstNode memory propertyNode;
      propertyNode.nodeType = IAstBuilder.NodeType.property;

      // find key
      IAstBuilder.AstNode memory keyNode;
      if (AstBuilderUtil.getLiteralValueType(token.attrs.tokenCode, token.attrs.tokenType) != IAstBuilder.LiteralValueType.literal_invalid) {
        keyNode = _buildLiteral(tokens, context);
        ++context.currentTokenIndex;
      } else if (token.attrs.tokenType == IJSLexer.TokenType.identifier) {
        keyNode = _buildIdentifier(tokens, context);
        ++context.currentTokenIndex;
      } else {
        revert('invalid object');
      }
      token = tokens[context.currentTokenIndex];
      require(token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.colon), 'no colon');
      ++context.currentTokenIndex;

      // find value
      IAstBuilder.AstNode memory valueNode;
      valueNode = _buildExpression(tokens, context, false, 0);
      require(valueNode.nodeType != IAstBuilder.NodeType.invalid, 'invalid value');

      propertyNode.value = abi.encode(false); // computed not supported
      AstNodeUtil.addNodeToContext(propertyNode, context);
      AstNodeUtil.addNodeIdToArray(propertyNode, keyNode);
      AstNodeUtil.addNodeIdToArray(propertyNode, valueNode);
      AstNodeUtil.addNodeIdToArray(objectNode, propertyNode);
    }
    return objectNode;
  }
  
  /**
   * Build call expression ast node
   * @param funcNameNode the node representing function name
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildCallExpression(
    IAstBuilder.AstNode memory funcNameNode,
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    IAstBuilder.AstNode memory callNode;
    callNode.nodeType = IAstBuilder.NodeType.callExpression;
    AstNodeUtil.addNodeToContext(callNode, context);
    AstNodeUtil.addNodeIdToArray(callNode, funcNameNode);

    while (context.currentTokenIndex < tokens.length) {
      IJSLexer.Token calldata token = tokens[context.currentTokenIndex];
      if (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.rightParenthesis)) {
        break; // end of function call
      } else if (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.comma)) {
        // next argument
        ++context.currentTokenIndex;
        token = tokens[context.currentTokenIndex];
      }
      IAstBuilder.AstNode memory argNode = _buildExpression(tokens, context, false, 0);
      require(argNode.nodeType != IAstBuilder.NodeType.invalid, 'invalid call');
      AstNodeUtil.addNodeIdToArray(callNode, argNode);
    }
    return callNode;
  }

  /**
   * Build identifier ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildIdentifier(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private pure returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildIdentifier');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.identifier;
    (string memory name,) = tokens[context.currentTokenIndex].attrs.decodeIdentifierValue(); // name
    node.value = abi.encode(name);
    AstNodeUtil.addNodeToContext(node, context);
    // console.log('OUT buildIdentifier');
    return node;
  }
  
  /**
   * Build literal value ast node
   * @param tokens tokenized source code
   * @param context the runtime context
   * @return built ast node
   */
  function _buildLiteral(
    IJSLexer.Token[] calldata tokens,
    IAstBuilder.Context memory context
  ) private view returns (IAstBuilder.AstNode memory) {
    // console.log('IN buildLiteral');
    IAstBuilder.AstNode memory node;
    node.nodeType = IAstBuilder.NodeType.literal;
    AstNodeUtil.addNodeToContext(node, context);
    IJSLexer.Token calldata token = tokens[context.currentTokenIndex];
    node.nodeType = IAstBuilder.NodeType.literal;
    IAstBuilder.LiteralValueType valueType = AstBuilderUtil.getLiteralValueType(token.attrs.tokenCode, token.attrs.tokenType);
    if (valueType == IAstBuilder.LiteralValueType.literal_string) {
      (string memory value,) = token.attrs.decodeStringValue();
      node.value = abi.encode(value);
    } else if (valueType == IAstBuilder.LiteralValueType.literal_numberString) {
      (uint integer,
      uint decimal,
      uint decimalDigits,
      uint exponent,
      bool sign,
      bool expSign,
      string memory value,) = token.attrs.decodeNumberStringValue();
      node.value = abi.encode(integer, decimal, decimalDigits, exponent, sign, expSign, value);
    } else if (valueType == IAstBuilder.LiteralValueType.literal_boolean) {
      node.value = abi.encode(token.attrs.tokenCode == uint(IJSKeywordLexer.KeywordCode._true));
    } else if (valueType == IAstBuilder.LiteralValueType.literal_number || valueType == IAstBuilder.LiteralValueType.literal_numberString) {
      (uint integer,
      uint decimal,
      uint decimalDigits,
      uint exponent,
      bool sign,
      bool expSign,) = token.attrs.decodeNumberValue();
      node.value = abi.encode(integer, decimal, decimalDigits, exponent, sign, expSign);
    } else if (valueType == IAstBuilder.LiteralValueType.literal_regex) {
      (string memory pattern, string memory flags,) = token.attrs.decodeRegexValue();
      node.value = abi.encode(pattern, flags);
    } else if (valueType == IAstBuilder.LiteralValueType.literal_array) {
      ++context.currentTokenIndex;
      while (context.currentTokenIndex < tokens.length) {
        token = tokens[context.currentTokenIndex];
        if (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.rightSquareBracket)) {
          break; // end of array literal
        }
        IAstBuilder.AstNode memory elemNode;
        elemNode = _buildExpression(tokens, context, true, 0); // build element node
        AstNodeUtil.addNodeIdToArray(node, elemNode);
        token = tokens[context.currentTokenIndex];
        while (token.attrs.tokenType == IJSLexer.TokenType.punctuation && token.attrs.tokenCode == uint(IJSPunctuationLexer.PunctuationCode.comma)) {
          ++context.currentTokenIndex; // next element 
          token = tokens[context.currentTokenIndex];
        }
      }
    } else if (valueType == IAstBuilder.LiteralValueType.literal_object) {
        ++context.currentTokenIndex;
        node = _buildObjectExpression(tokens, context);
    }
    node.nodeDescriptor = uint(valueType);
    // console.log('OUT buildLiteral');
    return node;
  }

  /**
   * Determine wether the keyword is allowed in expression.
   * @param code KeywordCode
   * @return res true if the keyword is allowed
   * @notice Don't forget to update this function if IJSKeywordLexer.KeywordCode is changed. 
   */
  function _isAllowedKeyword(uint code) private pure returns (bool res) {
    assembly {
      switch code
      case 0 /* _await */ { res:= true }
      case 9 /* _delete */ { res:= true }
      case 15 /* _false */ { res:= true }
      case 21 /* _in */ { res:= true }
      case 22 /* _instanceof */ { res:= true }
      case 23 /* _new */ { res:= true }
      case 24 /* _null */ { res:= true }
      case 28 /* _this */ { res:= true }
      case 30 /* _true */ { res:= true }
      case 32 /* _typeof */ { res:= true }
      case 34 /* _void */ { res:= true }
      case 38 /* _undefined */ { res:= true }
      default { res:= false }
    }
  }
  
  /**
   * Get the calculation order of the operator
   * @param code OperatorCode
   * @return order the calculation order
   * @notice Don't forget to update this function if IJSOperatorLexer.OperatorCode is changed. 
   */
  function _biopOrder(uint code) private pure returns (uint order) {
    assembly {
      switch code
      case 6 /* multiplication */ { order := 6 }
      case 4 /* division */ { order := 6 }
      case 10 /* remainder */ { order := 6 }
      case 22 /* addition */ { order := 5 }
      case 25 /* subtraction */ { order := 5 }
      case 34 /* lessThan */ { order := 4 }
      case 35 /* lessThanOrEqual */ { order := 4 }
      case 28 /* greaterThan */ { order := 4 }
      case 29 /* greaterThanOrEqual */ { order := 4 }
      case 39 /* equality */ { order := 3 }
      case 40 /* strictEquality */ { order := 3 }
      case 42 /* inequality */ { order := 3 }
      case 43 /* strictInequality */ { order := 3 }
      default { order := 0}
    } 
  }
}