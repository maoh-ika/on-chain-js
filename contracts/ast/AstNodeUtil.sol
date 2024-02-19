// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../utils/Log.sol';
import '../interfaces/lexer/IJSLexer.sol';
import '../interfaces/lexer/IJSKeywordLexer.sol';
import '../interfaces/lexer/IJSPunctuationLexer.sol';
import '../interfaces/lexer/IJSOperatorLexer.sol';

library AstNodeUtil {
  /**
   * Assign node id to passed node and add it to context.
   * @param node ast node to be added
   * @param context the runtime context
   */
  function addNodeToContext(IAstBuilder.AstNode memory node, IAstBuilder.Context memory context) internal pure {
    node.nodeId = context.nodeCount;
    if (node.nodeId >= context.nodes.length) {
      resize(context, context.nodes.length + 10);
    }
    require(context.nodes[node.nodeId].nodeType == IAstBuilder.NodeType.invalid, 'alread exists');
    context.nodes[node.nodeId] = node;
    ++context.nodeCount;
    if (context.maxNodeId < node.nodeId) {
      context.maxNodeId = node.nodeId;
    }
  }

  /**
   * Register child node id to parent node. 
   * @param parentNode parent node
   * @param node child node
   */
  function addNodeIdToArray(IAstBuilder.AstNode memory parentNode, IAstBuilder.AstNode memory node) internal pure {
    require(node.nodeType != IAstBuilder.NodeType.invalid, 'root cannot be child');
    resize(parentNode, parentNode.nodeArray.length + 1);
    parentNode.nodeArray[parentNode.nodeArray.length - 1] = node.nodeId;
  }
  
  /**
   * Resize nodes array of context. 
   * @param context the runtime context
   * @param size new array size
   */
  function resize(IAstBuilder.Context memory context, uint size) internal pure {
    IAstBuilder.AstNode[] memory newArray = new IAstBuilder.AstNode[](size);
    for (uint i = 0; i < context.nodes.length && i < size; i++) {
      newArray[i] = context.nodes[i];
    }
    context.nodes = newArray;
  }
  
  /**
   * Resize child node id array of node. 
   * @param node ast node to be resized
   * @param size new array size
   */
  function resize(IAstBuilder.AstNode memory node, uint size) internal pure {
    uint[] memory newArray = new uint[](size);
    for (uint i = 0; i < node.nodeArray.length && i < size; i++) {
      newArray[i] = node.nodeArray[i];
    }
    node.nodeArray = newArray;
  }

  /**
   * Join two contexts. 
   * @param srcContext the context joined to dstContext
   * @param dstNode update attributes with srcContext
   * @param dstContext the context to join the srcContext to
   */
  function joinContext(
    IAstBuilder.Context memory srcContext,
    IAstBuilder.AstNode memory dstNode,
    IAstBuilder.Context memory dstContext
  ) internal pure {
    dstContext.currentTokenIndex = srcContext.currentTokenIndex;
    dstContext.maxNodeId += srcContext.maxNodeId;
    if (dstContext.nodes.length < srcContext.nodeCount + dstContext.nodeCount) {
      resize(dstContext, srcContext.nodeCount + dstContext.nodeCount + 10);
    }

    // Copy nodes to srcContext. In order to correctly refer to the elements of nodes array, 
    // shift the child nodes indexes in dstContext by the number of nodes in srcContext.
    for (uint i = 0; i < srcContext.nodeCount; ++i) {
      for (uint j = 0; j < srcContext.nodes[i].nodeArray.length; ++j) {
        srcContext.nodes[i].nodeArray[j] += dstContext.nodeCount;
      }
      IAstBuilder.AstNode memory node = srcContext.nodes[i];
      node.nodeId = uint(dstContext.nodeCount + i);
      dstContext.nodes[dstContext.nodeCount + i] = node;
    }
    dstContext.nodeCount += srcContext.nodeCount;
    dstContext.expCount += srcContext.expCount;
    uint oldId = dstNode.nodeId;
    dstNode.nodeId = srcContext.nodes[oldId].nodeId;
    dstNode.nodeArray = srcContext.nodes[oldId].nodeArray;
  }
}