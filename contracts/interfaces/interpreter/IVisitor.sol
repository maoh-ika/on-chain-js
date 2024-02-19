// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import '../ast/IAstBuilder.sol';
import './IJSInterpreter.sol';

/**
 * The interface to traverse ast. 
 */
interface IVisitor {
  /**
   * Visit and evaluate a ast node
   * @param nodeIndex the index of nodes, which refer to the ast node to visit
   * @param nodes ast nodes
   * @param state interpretation state
   * @return result value
   * @return updated state
   * @notice The state argument is received as 'memory' because it may be updated.
   *         This function is executed in different environment and memory addresses from caller, so we need passing
   *         the updated state to caller as return value which is passed as copy.
   */
  function visit(
    uint nodeIndex,
    IAstBuilder.AstNode[] calldata nodes,
    IJSInterpreter.State memory state
  ) external view returns (IJSInterpreter.JSValue memory, IJSInterpreter.State memory);
}