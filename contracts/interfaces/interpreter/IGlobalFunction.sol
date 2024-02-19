// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import './IJSInterpreter.sol';

/**
 * The interface for global function.
 */
interface IGlobalFunction{
  /**
   * call global function.
   * @param funcName function name
   * @param argValues arguments passed to the function
   * @param traceDependencies the flag indicating tracing enabled
   * @return result value
   * @return contract dependees
   * @return exe token dependees
   */
  function call(
    string calldata funcName,
    IJSInterpreter.JSValue[] calldata argValues,
    bool traceDependencies
  ) external view returns (IJSInterpreter.JSValue memory, uint[] memory, uint[] memory);
}